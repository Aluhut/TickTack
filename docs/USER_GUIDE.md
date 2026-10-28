# User guide

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

## CSV export

Export CSV writes the selected project's saved entries, in its selected sort order. Search does not limit export. The six columns are position, category, task, description, date range, and hours. The file uses UTF-8 with a BOM, semicolon separators, and quoted fields. Header names and decimal separators follow the app language. Quotes, newlines, and semicolons in notes are escaped.

A CSV does not contain project colors, deletion history, or an active timer. CSV import is not implemented.

## Reading and language

The app starts with 17-point base text, larger rows, and labelled timer controls. View → Increase text size / Decrease text size adjusts base text from 16 to 24 points. Small supporting labels use fixed 13–14-point sizes. Project selection has a checkmark as well as color.

German is selected only when the primary preferred language starts with `de`; all other language preferences select English. Restart after changing language settings. User-entered text is never translated. macOS system dialogs may follow macOS's own language settings.

## Saving and quitting

Saved entries, projects, preferences, and restorable deletions persist locally. Timer state and drafts do not. Stop & save before quitting, restarting, or updating. The menu bar Quit button stops and saves; standard Quit or a crash can lose the active measurement. Automatic backups and crash recovery are not implemented.
