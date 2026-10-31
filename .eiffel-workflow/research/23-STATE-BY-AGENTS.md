# 23 - State by agents (audit, plan, phases)

Status: **audit done (2026-10-31); phase 0 shipped in 0.7.44; phase 1 built for 0.7.45; phases 2 onward next.** The library design (section 5) waits for a design session with Larry.

## 1. The rule

Larry, 2026-10-31: GUI state (enabled or disabled, visible or hidden, labels, colors, behavior) is driven by **agent collections fired when state changes**: persistent agents, or one-shot ("kamikaze") agents. From now on this is the default way to manage state in Simple Bible and everything built after it, **unless a spike or a timing test shows another way is needed**. Change comes in stages and phases, never the whole simple_* architecture at once.

## 2. How it is done now (the audit)

Read-only sweep of `gui_app/` (bib_gui_app.e 6,905 lines, plus the panels) and the simple_widgets mechanisms it uses.

| Mechanism | Count | Notes |
|---|---|---|
| `set_enabled_when` (pull conditions re-asked by a walk of the widget tree) | 0 | The original window specification declared six; none was built that way. The Atlas measuring buttons used them in 0.7.43 and broke (below). |
| `set_enabled` (direct) | 42 | 26 computed, 16 literal; mostly inside `fill_*` routines, so a button is right only after its pane refills. |
| Dock show, hide, move, fraction, maximize, mark | about 60 | Decided by `arrange`, the river workspace, `show_results`/`hide_results`, `bring_into_view`, menus. |
| Show or hide by adding or removing a child | about 12 | The origin button, Back to results, the tools strip, the reading column and tabs. |
| Agent collections | 2 | `BIB_TIME_PLACE_SELECTION` (three hand-rolled lists, four listeners) and `SW_ATLAS.measure_actions` (one). `SW_EVENT`, the library's agent collection (permanent and kamikaze subscribers, pause, block, abort), is used by the app nowhere. |
| Single-slot callbacks (`set_on_click`, `set_on_select`, `set_on_change`) | 76 | Fine for input; they are not state. |
| Menus | 78 items, 27 computed | Rebuilt on each opening, so their flags are always fresh; but they recompute conditions the panes compute separately. |
| State attributes that drive the GUI | about 45 | `is_study`, `is_river_workspace`, `reading_verse`, `choices`, `is_commentary_held`, `study_lemma`, `pending_*` jobs, and so on. |

**The 0.7.43 bug, and what it teaches.** The Atlas measuring buttons had pull conditions (`enabled_when` agents). The window re-asks them by walking `sub_widgets`; a dock zone did not pass the walk to its panels, so the conditions were asked once and never again. simple_widgets 0.48.2 fixed the walk, and the Atlas now **pushes** each change to an agent collection (`on_measure_change`). A pull walk can be cut off silently by any one container; a push cannot.

### State clusters and their risks

| Cluster | State today | Kept in sync by | Risks found |
|---|---|---|---|
| A. Layout | `is_study`, the mode switch, the saved setting, `is_river_workspace`, `choices` | `arrange` rebuild plus direct dock calls in four places | Three copies of "Study"; panes left unfilled when switching Simple to Study (1); the reader's panel widths lost on every workspace change (13) |
| B. Reading place | book, chapter, verse, version, history | `open_reading` rebuilds everything, including nine Study panes on every verse click (17) | Previous/Next read back from the buttons, Back/Forward recomputed (3); `reading_verse > 0` written in 15 places (20) |
| C. Search results | `choices`, `verse_hits`, scope | direct sets in `on_search`, `show_results`, `hide_results` | Three definitions of "has results" (4); Close does nothing in Study (5) |
| D. Notes and collections | rows, chosen ids, last deleted, store open | `set_enabled` inside each `fill_*` and click handler | Answered enabled with nothing chosen (8); strip marks stale after a note is added or deleted (6) |
| E. Commentary | held place, shown place, `has_commentary` | a redraw cache keyed on the place | Imports do not refresh the commentary or its tabs (7) |
| F. Ask | helper, pending request | a tick countdown | No busy state; a second request overwrites the first (10) |
| G. Timeline and Atlas | selection, measure state, filled flags | **agents** (the only agent-based cluster) | The Atlas replays only the year when filled late (15) |
| H. Import jobs | pending folders, swapped packs | tick countdowns | Menus stay live while a job waits (10) |
| I. Library shelf | shelf, listed book, opened writing | reparenting in `show_shelf` | Tab numbers shared by different tab sets (14) |
| J. Settings and theme | text scale (four copies), dark (two copies) | `change_text_size`, `set_dark` | Size buttons stale at start (2); following the system theme does not move the switch (11) |
| K. Lexicon | lemma, places, paging | `open_study` rebuild, tick paging | Search-word button live with no word (8) |

Other risks: buttons on missing data enabled while their handlers do nothing (9); the Focus button's label never changes (18); "due today" goes stale past midnight (19); 27 explicit repaint requests whose purpose is unclear (16); `refresh_strip_marks` reads four unrelated facts and nobody tells it when they change (21).

## 3. The target, inside Simple Bible (no library change needed)

- **One state object per cluster**, holding its facts and nothing of the GUI. Every command that changes a fact fires an `SW_EVENT` **only when the value really changed**. What the GUI needs to know is a **query** on the state (`has_verse`, `can_go_back`, `has_results`), written once.
- **Binding**: each control subscribes an agent to the events it depends on, and **binding applies the current state at once** (subscribe, then call), so a late joiner is never stale.
- **Kamikaze agents** for one-shot follow-ups (when a job finishes, open its report once).
- **Menus** stay rebuilt on opening, but read the same state queries.
- **State objects are testable without a window**: the tests check that each event fires once per real change and never otherwise, and that a bound control follows every change.

## 4. Phases (each a stable release: tests shown failing first for every risk fixed, all snapshots, the installer)

0. **Shipped, 0.7.44**: the dock walk fixed (simple_widgets 0.48.2); the Atlas measuring buttons pushed by agents.
1. **Foundation and test bench.** A GUI test target (`bible_gui_tests`) that builds state objects and bindings without showing a window. `BIB_TIME_PLACE_SELECTION` moved onto `SW_EVENT`, with binding that applies now (risk 15). A short how-to in this file.
2. **Layout and settings (A, J).** One layout state (layout, workspace, results wanted, text scale, dark) replacing the copies; panels, mode switch, size buttons, dark switch and pills bound to it. Fixes risks 1, 2, 11, 13, 18.
3. **Reading place (B).** One reading state with events for chapter, verse, version and history; navigation buttons and menu items from its queries; panes bound to what they show (a verse click no longer refills every pane). Fixes 3, 17, 20.
4. **Search results (C).** One results state, one `has_results`, closing remembered. Fixes 4, 5, 6.
5. **Notes, collections and strip marks (D).** Change events from the user store drive the panes and the marks; selection-dependent buttons bound to their panel's choice. Fixes 6, 8, 21.
6. **Commentary, packs, jobs and Ask (E, F, H).** A packs-changed event clears caches and refreshes what shows them; a jobs state shows busy and holds a second request. Fixes 7, 9, 10.
7. **Library shelf, tabs, lexicon, time (I, K).** Named tabs per tab set; the lexicon bound to its word; a day-changed event. Fixes 8 (lexicon), 14, 19.
8. **Leftovers.** The remaining direct `set_enabled` calls, the unexplained repaint requests (16), menus reading state queries everywhere.

### How to (phase 1, 2026-10-31)

The pattern every later phase follows, as `BIB_TIME_PLACE_SELECTION` and `SW_LANE_TIMELINE.view_changed` now do it:

```eiffel
	year_changed: SW_EVENT [TUPLE [year: INTEGER]]
			-- One SW_EVENT per fact (or per group of facts that always change together).

	set_year (a_year: INTEGER)
			-- The ONE door that changes the fact: it tells only on a real change.
		do
			if not has_year or else year /= a_year then
				year := a_year
				has_year := True
				year_changed.call ([a_year])
			end
		end

	on_year (a_action: PROCEDURE [INTEGER])
			-- Joining = subscribe AND be told the present, so a late view is never stale.
		do
			year_changed.subscribe (a_action)
			if has_year then
				a_action.call ([year])
			end
		end
```

- A view joins when it is able to show the state (the Atlas joins when it is filled), not when the state is made.
- A widget whose state changes in many ways (the timeline's view: drag, wheel, keys, bar, `set_view`) tells from ONE place (`tell_view` at the end of `arrange`), comparing with what it last told.
- A bound control that the reader may be editing (the From and To boxes) skips the update while it has the focus.
- Tests live in `testing_gui/` (target `bible_gui_tests` in `simple_bible_app.ecf`): each event told once per real change and never otherwise; a late joiner told the present.

Shipped with phase 1 (0.7.45): the Timeline's bar across time (simple_widgets 0.49.0) and the From/To/Set row, both following `view_changed`.

## 5. For the design session with Larry (before any library change)

1. **Where a state ancestor lives**: simple_widgets, or a small library of its own that non-GUI programs (services, command-line tools) can use too.
2. **Its shape**: a deferred ancestor (for example a state with `changed` events and `bind`, which subscribes and applies now), and possibly a mixin that makes a widget or pane declare how it binds, so descendants are forced to implement it between the abstraction and the concrete class.
3. **Explicit state machines**: states, transitions, guard agents, entry and exit agent collections (the measuring tool is Idle, Running, Ended), as a class or as a pattern.
4. **Pull conditions**: keep `enabled_when` for menus and simple cases, or retire it; a timing spike of push against pull at a thousand bound controls.
5. **Enforcement**: contracts that check bound controls agree with their state; the `/eiffel-*` state-audit skill Larry proposed, built after the framework exists, to audit any GUI or state-machine task against it.
6. **Order beyond Simple Bible**: which programs follow (simple_prompter, simple_taskman), one at a time.

Phases 1 to 8 are written so they move onto the chosen ancestor later without rework: each state object already has the shape a deferred ancestor would demand.
