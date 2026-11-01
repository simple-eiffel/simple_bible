# 24 - History and Favorites

Status: **asked for by Larry 2026-11-01. Built: A (0.7.50, the reading place), B (0.7.51, History), C (0.7.52, Favorites, stars), D1 (0.7.53, quotations and documents from the framework, book and commentary views, marked inside them), D2 (0.7.54, quotations of verses in the Bible text and Parallel). Next: D3, carrying a selection to Favorites (section 5).** Follows research/23 phase 3 (the reading place), which it builds on.

## 1. What Larry asked for

- Back and Forward stay as they are (a verse click is a history step).
- **History**: every verse touched this session, and history kept between sessions, capped (200 by default, adjustable).
- **Favorites**, modeled on a notes app's file explorer: folders from a root, arranged by the reader's own categories. Verses, passage ranges, chapters and other materials.
- A **gold star** on every favorite verse, range or chapter wherever Simple Bible shows it.
- **Bookmarks are Favorites**: one list, not two.
- Favorites live in user.db, and each records the **Bible version** it was made in.
- Other materials: books, essays, papers, frameworks, commentaries. For a framework or commentary (and a book), a part rather than the whole: a right-click **"Add to Favorites as a quotation"** on a selection in any document, and the same for part of a verse.

## 2. What exists (read 2026-11-01)

| Part | Today |
|------|-------|
| History pane | `record_place` writes a `visit` per new chapter to user.db; `fill_history` lists the last 50 chapters (`History_length`, a constant), one per chapter. Kept between sessions, but by chapter only. |
| Back and Forward | `history` and `history_index` in the window, in memory, a step per `go_to`. |
| Bookmarks | `user_item` rows (kind bookmark), single verses, a flat list; Ctrl+D. No version recorded. |
| Stars | None. |
| Selection | `SW_DOCUMENT_VIEW` (books, frameworks, commentary, notes) has `SW_TEXT_SELECTION` and a context menu. `SW_PARALLEL_TEXT` (the Bible text, Parallel) has no partial selection. |
| Tree | `SW_TREE [G]` in simple_widgets: lazy children, keyboard, drag and release handlers. |

## 3. Stages (each a stable release with its tests, snapshots and the installer)

**A. The reading place (research/23 phase 3).** `BIB_READING_STATE`: book, chapter, verse, version, history, with events for chapter, verse, version and history, each told only on a real change; queries `has_verse`, `can_go_back`, `can_go_forward`, `has_previous_chapter`, `has_next_chapter`. Buttons and menu items bind to the queries; panes bind to the events they depend on (a verse click no longer rebuilds the chapter and nine Study panes). Tests: a verse click leaves the chapter-level panes untouched; Back, Forward, Previous and Next follow the state. Fixes risks 3, 17, 20.

**B. History.** user.db schema 3: a session number and the verse on each visit. The History pane gets two lists: *This session* (every verse touched, in order) and *Earlier* (kept, newest first, pruned to the cap). The cap is a setting (200 by default) on the Settings page. History binds to the reading state's history event.

**C. Favorites.** user.db: `favorite_folder` (id, parent, name, position) and `favorite` (id, folder, kind, hub_id, end_hub_id for a range, version code, label, position, created_at), with deleted flags for undo like the other user tables. A Favorites pane on `SW_TREE`: new folder, rename, drag items and folders, delete with undo, a filter box. Existing bookmarks migrate into a root folder named *Bookmarks*; Ctrl+D adds a favorite and asks for a folder. A favorites index (hub ranges) answers "is this verse a favorite" quickly, and the gold star is drawn wherever a verse, range or chapter is listed: the Bible text, Parallel, Interlinear, search results, History, cross references. The index tells a `changed` event; every starred view binds to it.

**D. Other materials and quotations.** Favorites of a book, essay, paper, framework or commentary (the whole, by its id). A *quotation* favorite: the selected text, the source (document id and the place in it: section and character range, or the verse and version), and the time. The right-click menu of every `SW_DOCUMENT_VIEW` gets "Add to Favorites as a quotation"; the Bible text gets selection (`SW_TEXT_SELECTION` in `SW_PARALLEL_TEXT`, a simple_widgets change) and the same item. Opening a quotation opens its source at its place with the quoted part selected.

## 4. Decided (Larry, 2026-11-01)

- A favorite document, and a quoted part, are marked inside the document itself, as verses are starred.
- Quotations of restricted works stay in user.db and are never exported.
- Sorting follows that file explorer: one order for the whole tree, folders first, chosen from name (A to Z, Z to A), changed time and created time (newest or oldest first). Its core has no hand ordering, so dragging moves an item into a folder, never between two items.

## 5. Carrying a selection to Favorites (Larry's ask, 2026-11-01; proposal)

One pebble, three ways to lift it, one drop hole.

- **The pebble**: a quotation (the selected text, its source, its place, and the version for a verse). Other things become pebbles the same way: a verse number, a chapter title, a search result, a History row, a book on the shelf.
- **Lifting it**:
  1. *Drag*: press inside the selection and move past the system drag distance (pressing outside the selection starts a new selection, as in Word and browsers).
  2. *Pick up* from the right-click menu: one click, and the pebble follows the pointer with the trajectory line simple_widgets already draws; no button is held, so the reader can scroll, change tabs and open folders by clicking before dropping.
  3. *Middle-click* on the selection: simple_widgets' existing pick gesture, as a shortcut for Pick up.
- **Not adopted**: turning the menu into a pick when the pointer leaves it. Pointers overshoot menus all the time, so it would pick by accident, and the click meant to dismiss the menu would then drop or cancel.
- **The drop hole (the Favorites tree), the same for every way of lifting**:
  - If Favorites is closed, its tab or edge strip lights up as a target; hovering there about half a second springs it open, and it closes again after the drop if it was closed before.
  - Hovering a closed folder about 0.7 seconds springs it open, and so on down; folders opened this way close again after the drop, except the path to where the item landed.
  - One "New folder" row stands at the end of the folder under the pointer: dropping on it makes an "Untitled" folder holding the item and opens its name for editing at once (one drop, not two).
  - Dropping on a favorite puts the pebble in that favorite's folder. Near the top or bottom edge the tree scrolls. Escape cancels; a drop anywhere else does nothing.
  - The source is never changed (a copy); dragging inside the tree moves.
  - While picking, clicking a folder's arrow opens it without dropping; clicking the folder drops.
  - The pointer carries a small card: the quote's opening words and its source ("For God so loved..." John 3:16, KJV). After the drop a notice names the folder and offers Undo.
- **Where it is built**: the targeting (spring-open, the New folder row, edge scrolling, the card) in simple_widgets on `SW_TREE` and `SW_WINDOW`'s existing pick machinery, so drag and pick share one code path and any program gets it.

## 6. Pills (Study board; the full table is gui/03-PILLS.md)

- T1.1 Favorites tools: filter box, New folder, Rename, Remove, Restore.
- T1.2 Favorites tree.
- T1.3 History: This session or Kept, and the Kept list's length.
- T1.4 History list.
