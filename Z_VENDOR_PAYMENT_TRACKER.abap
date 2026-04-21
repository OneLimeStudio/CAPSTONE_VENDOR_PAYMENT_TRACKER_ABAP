*&---------------------------------------------------------------------*
*& Report  : Z_VENDOR_PAYMENT_TRACKER
*& Title   : Vendor Payment Due Date Tracker
*& Author  : [Your Full Name]
*& Created : April 2026
*& Desc    : Custom ALV report showing open vendor invoices with
*&           aging buckets, colour-coded rows, and Excel export.
*& Tables  : BSIK (Open Vendor Items), LFA1 (Vendor Master)
*&---------------------------------------------------------------------*

REPORT z_vendor_payment_tracker.


TABLES: bsik,
        lfa1.

TYPES: BEGIN OF ty_output,
  bukrs    TYPE bukrs,          " Company Code
  belnr    TYPE belnr_d,        " Document Number
  lifnr    TYPE lifnr,          " Vendor Account
  name1    TYPE lfa1-name1,     " Vendor Name
  bldat    TYPE bldat,          " Document Date
  zfbdt    TYPE dzfbdt,         " Net Due Date (Baseline Date)
  wrbtr    TYPE wrbtr,          " Amount in Document Currency
  waers    TYPE waers,          " Currency Key
  days_left TYPE i,             " Days Remaining to Due Date
  aging    TYPE char15,         " Aging Bucket Label
  celltab  TYPE lvc_t_scol,     " ALV Cell Colour Table
END OF ty_output.

DATA: gt_output   TYPE TABLE OF ty_output,   " Output internal table
      gs_output   TYPE ty_output,            " Work area for output

      gt_fcat     TYPE lvc_t_fcat,           " ALV field catalog
      gs_fcat     TYPE lvc_s_fcat,           " Field catalog work area

      gs_layout   TYPE lvc_s_layo,           " ALV layout structure

      go_container TYPE REF TO cl_gui_custom_container,  " GUI container
      go_alv       TYPE REF TO cl_gui_alv_grid.          " ALV grid object


SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  PARAMETERS:     p_bukrs TYPE bukrs OBLIGATORY DEFAULT '1000'.  " Company Code

  SELECT-OPTIONS: s_lifnr FOR bsik-lifnr,                        " Vendor Range
                  s_budat FOR bsik-budat.                         " Posting Date Range

  PARAMETERS:     p_odue  TYPE c AS CHECKBOX DEFAULT ' '.         " Show Overdue Only

SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  TEXT-001 = 'Vendor Payment Due Date Tracker'.


START-OF-SELECTION.

  PERFORM fetch_data.

  IF gt_output IS INITIAL.
    MESSAGE 'No open vendor items found for the given selection.' TYPE 'I'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  PERFORM calculate_aging.

  IF gt_output IS INITIAL.
    MESSAGE 'No records to display after applying filters.' TYPE 'I'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  PERFORM build_field_catalog.
  PERFORM set_layout.
  PERFORM display_alv.


FORM fetch_data.

  SELECT b~bukrs
         b~belnr
         b~lifnr
         l~name1
         b~bldat
         b~zfbdt
         b~wrbtr
         b~waers
    INTO CORRESPONDING FIELDS OF TABLE gt_output
    FROM bsik AS b
    INNER JOIN lfa1 AS l
      ON l~lifnr = b~lifnr
    WHERE b~bukrs  = p_bukrs
      AND b~lifnr IN s_lifnr
      AND b~budat IN s_budat.

  IF sy-subrc <> 0.
    CLEAR gt_output.
  ENDIF.

ENDFORM.


FORM calculate_aging.

  DATA: ls_color TYPE lvc_s_scol.  " Single colour entry
  DATA: lt_del   TYPE TABLE OF sy-tabix.  " Rows to delete
  DATA: lv_idx   TYPE sy-tabix.

  LOOP AT gt_output INTO gs_output.

    lv_idx = sy-tabix.

    " Skip rows where net due date is blank to avoid short dumps
    IF gs_output-zfbdt IS INITIAL.
      APPEND lv_idx TO lt_del.
      CONTINUE.
    ENDIF.

    " Calculate days remaining (positive = future, negative = overdue)
    gs_output-days_left = gs_output-zfbdt - sy-datum.

    " Assign aging bucket and colour
    CLEAR: gs_output-celltab, ls_color.

    IF gs_output-days_left > 7.
      gs_output-aging     = 'Not Due'.
      ls_color-color-col  = '5'.   " Green
      ls_color-color-int  = '1'.
      ls_color-color-inv  = '0'.

    ELSEIF gs_output-days_left BETWEEN 1 AND 7.
      gs_output-aging     = 'Due Soon'.
      ls_color-color-col  = '6'.   " Yellow
      ls_color-color-int  = '1'.
      ls_color-color-inv  = '0'.

    ELSEIF gs_output-days_left = 0.
      gs_output-aging     = 'Due Today'.
      ls_color-color-col  = '3'.   " Orange
      ls_color-color-int  = '1'.
      ls_color-color-inv  = '0'.

    ELSE.
      gs_output-aging     = 'Overdue'.
      ls_color-color-col  = '6'.   " Red
      ls_color-color-int  = '0'.
      ls_color-color-inv  = '1'.
    ENDIF.

    " Apply colour to the whole row (no FNAME = all columns)
    APPEND ls_color TO gs_output-celltab.

    " If 'Show Overdue Only' checkbox selected, mark non-overdue for deletion
    IF p_odue = 'X' AND gs_output-days_left >= 0.
      APPEND lv_idx TO lt_del.
    ELSE.
      MODIFY gt_output FROM gs_output.
    ENDIF.

  ENDLOOP.

  " Delete rows marked for removal (in reverse to preserve indices)
  SORT lt_del DESCENDING.
  LOOP AT lt_del INTO lv_idx.
    DELETE gt_output INDEX lv_idx.
  ENDLOOP.

ENDFORM.


FORM build_field_catalog.

  CLEAR: gt_fcat, gs_fcat.

  " Company Code
  gs_fcat-fieldname = 'BUKRS'.
  gs_fcat-coltext   = 'Co. Code'.
  gs_fcat-outputlen = 8.
  APPEND gs_fcat TO gt_fcat. CLEAR gs_fcat.

  " Document Number
  gs_fcat-fieldname = 'BELNR'.
  gs_fcat-coltext   = 'Document No'.
  gs_fcat-outputlen = 12.
  APPEND gs_fcat TO gt_fcat. CLEAR gs_fcat.

  " Vendor Account
  gs_fcat-fieldname = 'LIFNR'.
  gs_fcat-coltext   = 'Vendor'.
  gs_fcat-outputlen = 12.
  APPEND gs_fcat TO gt_fcat. CLEAR gs_fcat.

  " Vendor Name
  gs_fcat-fieldname = 'NAME1'.
  gs_fcat-coltext   = 'Vendor Name'.
  gs_fcat-outputlen = 30.
  APPEND gs_fcat TO gt_fcat. CLEAR gs_fcat.

  " Document Date
  gs_fcat-fieldname = 'BLDAT'.
  gs_fcat-coltext   = 'Doc Date'.
  gs_fcat-outputlen = 12.
  APPEND gs_fcat TO gt_fcat. CLEAR gs_fcat.

  " Net Due Date
  gs_fcat-fieldname = 'ZFBDT'.
  gs_fcat-coltext   = 'Due Date'.
  gs_fcat-outputlen = 12.
  APPEND gs_fcat TO gt_fcat. CLEAR gs_fcat.

  " Amount
  gs_fcat-fieldname  = 'WRBTR'.
  gs_fcat-coltext    = 'Amount'.
  gs_fcat-outputlen  = 15.
  gs_fcat-do_sum     = 'X'.         " Show column total
  gs_fcat-qfieldname = 'WAERS'.     " Link to currency field for correct grouping
  APPEND gs_fcat TO gt_fcat. CLEAR gs_fcat.

  " Currency
  gs_fcat-fieldname = 'WAERS'.
  gs_fcat-coltext   = 'Curr'.
  gs_fcat-outputlen = 6.
  APPEND gs_fcat TO gt_fcat. CLEAR gs_fcat.

  " Days Remaining
  gs_fcat-fieldname = 'DAYS_LEFT'.
  gs_fcat-coltext   = 'Days Left'.
  gs_fcat-outputlen = 10.
  APPEND gs_fcat TO gt_fcat. CLEAR gs_fcat.

  " Aging Bucket
  gs_fcat-fieldname = 'AGING'.
  gs_fcat-coltext   = 'Status'.
  gs_fcat-outputlen = 12.
  APPEND gs_fcat TO gt_fcat. CLEAR gs_fcat.

  " Cell Colour column — technical only, must not be displayed
  gs_fcat-fieldname = 'CELLTAB'.
  gs_fcat-tech      = 'X'.          " Hidden from output grid
  APPEND gs_fcat TO gt_fcat. CLEAR gs_fcat.

ENDFORM.

FORM set_layout.

  CLEAR gs_layout.

  gs_layout-zebra      = 'X'.         " Alternating row shading
  gs_layout-cwidth_opt = 'X'.         " Auto-fit column widths
  gs_layout-ctab_fname = 'CELLTAB'.   " Column holding cell colour table

ENDFORM.


FORM display_alv.

  CALL SCREEN 100.

ENDFORM.

MODULE status_0100 OUTPUT.

  SET PF-STATUS 'MAIN_STATUS'.
  SET TITLEBAR  'MAIN_TITLE'.

  " Create container and ALV only once
  IF go_alv IS NOT BOUND.

    CREATE OBJECT go_container
      EXPORTING
        container_name = 'MAIN_CONTAINER'.

    CREATE OBJECT go_alv
      EXPORTING
        i_parent = go_container.

    go_alv->set_table_for_first_display(
      EXPORTING
        is_layout       = gs_layout
      CHANGING
        it_outtab       = gt_output
        it_fieldcatalog = gt_fcat ).

  ENDIF.

ENDMODULE.

MODULE user_command_0100 INPUT.

  DATA: lv_ucomm TYPE sy-ucomm.
  lv_ucomm = sy-ucomm.

  CASE lv_ucomm.

    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE PROGRAM.

    WHEN 'EXPORT'.
      " Trigger ALV built-in Excel download
      go_alv->execute_function( EXPORTING e_ucomm = '&LOCAL&SPREADSHEET' ).

  ENDCASE.

ENDMODULE.
