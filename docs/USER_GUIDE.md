# User guide

If macOS blocks the first launch, follow the [Gatekeeper guide](FIRST_LAUNCH.md#english). [Deutsche Anleitung](FIRST_LAUNCH.md#deutsch).

## Projects and colors

Create a project from File → New project… (⌘N). Select it in the left sidebar. File → Project color changes its accent. Project names are user data and remain exactly as entered.

A running timer remains attached to the project where it started, even when you browse another project. Clicking the current task returns to the running timer's project. Only one timer can run at a time.

## Entries

New entry opens a draft in the inspector. Enter a task, category, and optional description. Start the timer or enter nonnegative decimal hours and click Add entry. The timer controls remain available in the menu bar popover. Text can be edited while running or paused.

Existing entries save as you edit. Select a row to edit the position, full description, date range, and hours in the inspector. A date range is free text; new dates use ISO `YYYY-MM-DD`. ISO ranges and legacy German `13.–19.10.2026` ranges are sorted by their end date. Entries without a known date appear last.

## Search, sorting, and totals

Search matches the task, category, description, and date range in the selected project. Choose a sort order above the table. Your sort choice is remembered. The project total includes all the project's entries plus its active measurement, regardless of the search filter. Pauses do not add time.

## Deleting and restoring

Select rows with Command-click, or a range with Shift-click. Use the trash button or File → Delete selected entries… and confirm. File → Delete project… removes the current project and its entries after confirmation. Stop its timer first.

File → Restore last deletion restores the most recent deletion. Repeat to restore earlier deletions. The deletion history is stored locally and survives restarts. Restorable data remains on disk; this is not secure erasure.

## Import and export

Use **File → Import…** (⇧⌘I) or **File → Export**. The export button in the window offers the same formats. Export uses all saved entries in the selected project, in its chosen sort order; search and row selection do not limit it. A running measurement must be stopped and saved first to include it.

### TickTack project files

**Project file (.ticktack)…** saves the selected project, its color, and every saved entry without rounding. **Save all projects…** includes all projects in one file. Keep copies in your own backup location or transfer them to another Mac.

Importing a `.ticktack` file shows its projects, entry counts, and totals for review. Press Import to add them as **new project copies**. Existing projects and entries are never overwritten. Reimporting a file creates another copy; it does not synchronize or deduplicate. Documents contain saved projects and entries, not preferences, deletion history, active measurements, or unfinished drafts. They are versioned JSON files and are not encrypted.

You can also open a `.ticktack` file from Finder. This opens the import preview, not an editable document linked to that file. Subsequent edits are saved in TickTack's local storage; export again to update your backup file.

### CSV / TSV import

1. Choose a UTF-8 CSV/TSV file (UTF-16 files with a byte-order mark are also accepted).
2. Check the delimiter and whether the first row contains headers. Semicolon, comma, and tab are supported.
3. Assign source columns to TickTack's fields. Task and hours are required. Recognized German and English headers are suggested automatically.
4. Choose the decimal separator. Hours must be nonnegative decimal numbers without thousands separators, such as `1.5` or `1,5`. Clock durations such as `01:30` are not accepted as hours.
5. Review the rows, valid total, and any errors. The preview shows up to 500 rows; its counts and total cover the whole table. Invalid rows block import unless you explicitly choose to skip them. Blank rows are ignored.
6. Choose an existing destination project or create a new one with a name and color, then press Import.

Imports append entries; they never replace existing entries. Importing the same table twice adds its entries twice. Dates and date ranges remain editable text. No formulas, scripts, or macros are executed.

### CSV export

The six columns are position, category, task, description, date range, and hours. Files use UTF-8 with a BOM, semicolon separators, and quoted fields. Header names and decimal separators follow the app language. Decimal hours use ten fractional digits to retain measured seconds. Quotes, newlines, and semicolons in notes are escaped. CSV has no row formatting; use Excel or PDF for alternating row colors. CSV contains user-entered text as written; choose Excel export when you need spreadsheet text cells explicitly typed as text.

### Excel (.xlsx)

Excel export produces a workbook with a frozen header, column filters, wrapped text, alternating row colors, and numeric hours. The first worksheet contains the entries; the second contains the project name and saved total in hours. It can be opened in Excel, Numbers, or LibreOffice. Very long cells exceeding Excel's 32,767-character limit require a TickTack file instead.

Excel import lets you choose a worksheet and map its columns using the same preview. Shared and inline strings, numeric cells, standard date styles, and cached formula results are supported. Formulas are not recalculated. Recalculate and save a workbook in its spreadsheet application before importing if necessary. Password-protected files and older `.xls` files are not supported. For `.numbers` documents, export to Excel or CSV from Numbers first.

### PDF time reports

PDF export produces an A4 landscape report with the project name, saved total, six entry columns, alternating row colors, and page numbers. Headers repeat on each page; long notes continue onto subsequent pages. PDF is an output format for sharing and printing, not for importing or restoring projects.

Import files are limited to 30 MB; decompressed Excel content is also bounded. An unsupported or damaged file leaves existing data untouched. Use TickTack project files for lossless project transfers; CSV, Excel, and PDF are reports rather than full application backups.

## Reading and language

The app starts with 17-point base text, larger rows, alternating table backgrounds, and labelled timer controls. View → Increase text size / Decrease text size adjusts base text from 16 to 24 points. Small supporting labels use fixed 13–14-point sizes. Project selection has a checkmark as well as color.

German is selected only when the primary preferred language starts with `de`; all other language preferences select English. Restart after changing language settings. User-entered text is never translated. macOS system dialogs may follow macOS's own language settings.

## Saving and quitting

Saved entries, projects, preferences, and restorable deletions persist locally. Timer state and drafts do not. Stop & save before quitting, restarting, or updating. The menu bar Quit button stops and saves; standard Quit or a crash can lose the active measurement. Automatic backups and crash recovery are not implemented.
