# Z_VENDOR_PAYMENT_TRACKER — Setup & Activation Guide

**SAP ABAP Capstone Project | Vendor Payment Due Date Tracker**

---

## 📦 Files in This Package

* `Z_VENDOR_PAYMENT_TRACKER.abap` → Main ABAP program (all logic)
* `SCREEN_0100_AND_GUI_SETUP.txt` → Screen 100 + GUI Status instructions
* `README.txt` → This file

---

## 🧩 Step 1 — Create the Program in SE38

1. Open transaction **SE38**
2. Enter program name: `Z_VENDOR_PAYMENT_TRACKER`
3. Click **Create**
4. Fill in:

   * **Title**: Vendor Payment Due Date Tracker
   * **Type**: Executable Program
   * **Status**: (leave default)
   * **Application**: FI (Financial Accounting) or blank
5. Save to local package `$TMP` or a real development package
6. Paste the entire content of `Z_VENDOR_PAYMENT_TRACKER.abap`
7. Save (**Ctrl+S**) — do NOT activate yet

---

## 🖥️ Step 2 — Create Screen 100 in SE51

1. Open transaction **SE51**
2. Program: `Z_VENDOR_PAYMENT_TRACKER` | Screen: `0100`
3. Click **Create**
4. Attributes:

   * **Short description**: Vendor Payment Tracker ALV Container
   * **Screen type**: Normal
5. Click **Layout**
6. Insert → **Custom Control** (fill screen)
7. Name it exactly: `MAIN_CONTAINER`
8. Save & activate (**Ctrl+F3**)

### Flow Logic

Replace with:

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0100.

PROCESS AFTER INPUT.
  MODULE user_command_0100.
```

---

## 🎛️ Step 3 — Create GUI Status MAIN_STATUS

1. Go to: **SE80 → Goto → Other Objects → GUI Status**
2. Name: `MAIN_STATUS`
3. Add toolbar functions:

| Code   | Icon             | Text            |
| ------ | ---------------- | --------------- |
| BACK   | ICON_BACK        | Back            |
| EXIT   | ICON_SYSTEM_EXIT | Exit            |
| EXPORT | ICON_XLS         | Export to Excel |

4. Activate

---

## 🏷️ Step 4 — Create GUI Title MAIN_TITLE

1. Go to **GUI Title**
2. Name: `MAIN_TITLE`
3. Title: *Vendor Payment Due Date Tracker*
4. Activate

---

## ⚙️ Step 5 — Activate the Program

1. Open program in **SE38**
2. Press **Ctrl+F3**
3. Activate all sub-objects

---

## ▶️ Step 6 — Run the Report

1. Execute via **SE38 / SA38 / transaction Z_VENDOR_PAYMENT_TRACKER**
2. Input:

   * Company Code (e.g. `1000`)
   * Vendor Range (optional)
   * Posting Date (optional)
   * Show Overdue (checkbox)
3. Press **F8**

---

## 📊 Expected Output

* ALV Grid with open vendor invoices
* Color-coded rows:

  * 🟢 Green — Not Due (>7 days)
  * 🟡 Yellow — Due Soon (1–7 days)
  * 🟠 Orange — Due Today
  * 🔴 Red — Overdue
* Totals grouped by currency
* Excel export via toolbar

---

## 🗄️ Tables Accessed (Read-Only)

* `BSIK` — Open Vendor Line Items
* `LFA1` — Vendor Master

---

## 📝 Notes

* Uses `BSIK` (not `BSEG`) for performance
* Cleared items (`BSAK`) excluded
* Blank due dates (`ZFBDT`) skipped
* `CELLTAB` used for coloring (hidden field)
* For S/4HANA → consider `ACDOCA`

---

**Source:** 
