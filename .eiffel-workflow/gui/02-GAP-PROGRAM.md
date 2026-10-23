# 02 Gap Program: every simple_widgets and simple_shell gap

*Opened 2026-10-22 on Larry's order: "Handle ALL of the widget gaps in simple_widgets and simple_shell. Hebrew and Greek need to work in both Light and Dark. Period. Full stop."*
*Sources: `spec_windows_design_notes.md` §9 (GW-01 to GW-26) and `01-THEMING-PLAN.md` (GW-27, GW-28). GW-29 was found while drawing the concordance gap.*

## Rules for every item

1. **The fix goes in the owning library.** That is simple_widgets, simple_shell, simple_shaping or simple_cairo. No workaround in simple_bible, no WebView2, no ISE library beyond base and testing.
2. **One branch per item** (`feature/gw-NN-<slug>`), contracts first, then tests in simple_testing (TEST_SET_BASE assertions, not `check`), then code.
3. **Gate:**
   - `ec.sh check` then `ec.sh test` in the owning library.
   - **One Eiffel compile at a time, ever.**
   - 0 errors and 0 warnings.
   - The owning library's full suite stays green.
4. **The Hebrew and Greek gate applies to every text-bearing item.** Render offscreen in BOTH `make_light` and `make_dark`:
   - pointed WLC Genesis 1:1 with cantillation;
   - polytonic Greek John 1:1 (WH);
   - a mixed English/Hebrew line.
   
   Check right-to-left order, mark stacking and contrast. A failure in either theme fails the item.
5. **No windows on Larry's desktop.** All GUI tests run headless and offscreen.
6. **After a merge, clean-rebuild every dependent** (`-clean`). Incremental builds run stale library code.
7. **Merges are local; pushes to GitHub wait for Larry's word.**
8. **Leave other sessions' open branches alone.** simple_cairo is on `fix/text-on-two-threads` from the simple_prompter work. Any simple_cairo gap waits until that branch is merged or Larry says otherwise.

## Order

### Phase 1: text in both themes (the foundation every screen stands on)

| # | Gap | Owner | What "done" means |
|---|---|---|---|
| 1 | **GW-28** theme tokens | simple_widgets | SW_THEME gains `ink_on_accent`, `divider`, `selection`, a strong ink per semantic color, and a sequential ramp, in both palettes. Invariants hold the contrast of each (4.5:1 for text, 3:1 for large text and marks) |
| 2 | **GW-01** bundled fonts | simple_shaping | Private, per-process load of font files from the app folder (`AddFontResourceExW`, `FR_PRIVATE`, visible to GDI, DirectWrite interop and cairo). Ships the OFL faces: Noto Serif, Noto Serif Hebrew, IBM Plex Sans, IBM Plex Mono. `family_exists` answers True after loading on a machine without them |
| 3 | **GW-04** shaped text everywhere | simple_widgets | `SW_PAINTER.text` and `advance` go through the shaped path whenever shaping is attached, so every widget (data grid, tree, tabs, chips, select, dialog, status bar, dock title bars, timeline, charts, diagram, map, tooltip) shapes, measures and draws Hebrew and Greek correctly, with no per-widget patch |
| 4 | **GW-02** right-to-left paragraphs | simple_shaping + simple_widgets | Paragraph base direction and alignment in `layout_for`; per-item direction and right alignment in SW_LABEL, SW_TEXT_BOX and SW_PARAGRAPH_LIST; gutter on the reading-start side |
| 5 | **GW-03** cantillation and polytonic | simple_shaping | The D-006 spike made into a permanent test: WLC Genesis 1:1 (cantillation, meteg, MapM's no-break space before paseq) and polytonic Greek, in both themes at 14-40 px. Any defect is fixed. Dark mode gets a heavier reading weight if the marks fade |
| 6 | **GW-27** follow Windows light/dark | simple_shell | Read `AppsUseLightTheme`, raise an event on `WM_SETTINGCHANGE` ("ImmersiveColorSet"), and a dark title bar (`DWMWA_USE_IMMERSIVE_DARK_MODE`) |

### Phase 2: the v1 widgets

| # | Gap | Owner | Notes |
|---|---|---|---|
| 7 | **GW-24** function keys, Ctrl+digit | simple_shell + simple_widgets | F1-F12 without a modifier; Ctrl+digit and Ctrl+punctuation reach the accelerator table |
| 8 | **GW-26** cross-processor wake | simple_widgets + simple_shell | A worker posts and the pump wakes at once; settable heartbeat |
| 9 | **GW-11** status-bar sections | simple_widgets | Sections hold text or a small widget (progress, button) with click agents |
| 10 | **GW-08** paragraph hit test, raised runs, small caps | simple_widgets | Point to (item, offset); hover-dwell and scroll events; superscript Strong's; small caps LORD |
| 11 | **GW-09** hover card | simple_widgets | Dwell-opened popover holding a widget tree, shaped, stays open while hovered |
| 12 | **GW-05** dock | simple_widgets | Tabbed zones, draggable edges, hide/show/remove, snapshot and restore |
| 13 | **GW-13** rich document view and editor | simple_widgets | Headings, lists, quotes, inline styles, clickable verse links, tables (view); editing for notes; images in v1.5 |
| 14 | **GW-06** SW_PARALLEL_TEXT | simple_widgets | Verse rows × version columns, each with its own direction and font; row height = tallest cell; one scroll; cell marks; sticky headers |
| 15 | **GW-07** SW_INTERLINEAR | simple_widgets | Wrapping stacked word cells, right to left or left to right, toggleable lines, token hit test, keyboard |
| 16 | **GW-10** grouped bars | simple_widgets | Multi-series SW_BAR_CHART |
| 17 | **GW-12** SW_QUERY_BUILDER | simple_widgets | Nested groups, NOT, proximity, typed pickers, clause-tree output |
| 18 | **GW-29** virtual shaped grid | simple_widgets | SW_DATA_GRID virtualization for 100,000+ rows of shaped cells (the concordance's EVERY PLACE: 88,444 rows for ὁ) at 60 Hz |

### Phase 3: v1.5

| # | Gap | Owner | Notes |
|---|---|---|---|
| 19 | **GW-15** closable, reorderable tabs, overflow menu | simple_widgets | |
| 20 | **GW-16** follow Windows high contrast | simple_shell + simple_widgets | Builds on GW-27 |
| 21 | **GW-21** render a widget region to PNG | simple_widgets | Exports in the light theme by default |
| 22 | **GW-14** UI Automation bridge, reduce-motion flag | simple_shell + simple_widgets | Names, roles, values, focus events |

### Phase 4: v2

| # | Gap | Owner | Notes |
|---|---|---|---|
| 23 | **GW-18** painter dashes, hatches, gradients | simple_widgets (+ simple_cairo if needed) | |
| 24 | **GW-17** SW_LANE_TIMELINE | simple_widgets | BC/AD with no year zero, lanes, dispute envelopes, synchronism cursor |
| 25 | **GW-19** regional map, routes, labels, layers, dark style | simple_widgets | |
| 26 | **GW-23** deterministic layered diagram layout | simple_widgets | |
| 27 | **GW-22** floating panels in a second window | simple_widgets + simple_shell | |
| 28 | **GW-20** print preview, print, print to PDF | simple_widgets + simple_cairo + simple_shell | |
| 29 | **GW-25** audio playback (MP3) | simple_widgets + audio stack | Windows Media Foundation through inline C |

## Status

| Gap | Branch | State |
|---|---|---|
| GW-28 | simple_widgets `feature/gw-28-theme-tokens` | **Merged locally** (0.9.0). 343 pass, 0 fail, 0 warnings. Fifteen tokens, `is_readable`, `is_dark` |
| GW-01 | simple_shaping `feature/gw-01-private-fonts` | **Merged locally** (0.2.0). 74 pass, 0 fail. `load_font_file`, proven on IBM Plex Mono (OFL), which this machine does not have installed |
| GW-04a | simple_shaping `feature/gw-04a-styled-policy` | **Merged locally** (0.3.0). 76 pass, 0 fail. Bold and italic in `FONT_LIST` and the pipeline |
| GW-04b | simple_widgets `feature/gw-04b-shaped-painter` | **Merged locally** (0.10.0). 347 pass. Every widget shapes through `SW_PAINTER.text`; Hebrew/Greek gate in both themes (evidence PNGs) |
| GW-04c | simple_shaping `fix/gw-04c-leading-family` | **Merged locally** (0.3.1). A role's face also carries digits and punctuation (found: mono digits came from Segoe UI) |
| GW-02a | simple_shaping `feature/gw-02a-direction-alignment` | **Merged locally** (0.4.0). 79 pass. Forced paragraph direction; `Align_*`; `line_offset`; aligned bridge draw |
| GW-02b | simple_widgets `feature/gw-02b-aligned-widgets` | **Merged locally** (0.11.0). 352 pass. Text box, paragraph list and label alignment; gutter on the reading side; evidence `gw02_verses_light/dark.png` |
| GW-03 | simple_widgets `feature/gw-03-pointed-polytonic` | **Merged locally** (0.12.0). 356 pass. `set_script_face` and `set_small_script_face`; Noto Serif Hebrew/Noto Serif OFL fixtures; 14-40 px no tofu, marks attach; MapM no-break space never splits from paseq; at 14 px the regular face's points go grey, so below 18 px Hebrew uses the true Medium face (GDI weight 500 does not reach it); evidence `gw03_specimen_light/dark.png` |
| GW-27 | simple_shell `feature/gw-27-follow-system-theme` + simple_widgets `feature/gw-27-window-follows-system` | **Merged locally** (shell 1.16.0, 37 pass + SCOOP 4; widgets 0.13.0, 359 pass). `SHELL_APPEARANCE.system_prefers_dark`, event 53, `set_dark_title_bar` (DWM 20/19); `SW_WINDOW.follow_system_theme`, live swap before modality, `set_on_theme_changed`, `set_theme` stops following, caption matches theme. **Phase 1 complete.** |
| Other gaps | - | Not started |

**Clients to rebuild `-clean` before their next build** (simple_widgets 0.9-0.11, simple_shaping 0.2-0.4): simple_chat, simple_narrate, simple_ocr_capture, simple_prompter, simple_taskman and anything else on simple_widgets. Apps that attach a shaping kit now shape ALL their text through the painter.

Pre-existing build state noted: simple_widgets carried 4 warning lines (fixed in GW-28). simple_cairo is checked out on the simple_prompter session's `fix/text-on-two-threads` branch, and every simple_widgets build compiles against it.
