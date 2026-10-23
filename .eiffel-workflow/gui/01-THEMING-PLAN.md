# 01 Theming Plan: Light and Dark

*2026-10-22. Extends `00-GUI-SPEC.md` §12 (Theming). Drawn up while building the light and dark mockup pages (claude.ai pages; Larry holds the links).*

*Two decisions are Larry's, marked **(Larry)**. Everything else is technical and is settled by evidence.*

## DECIDED (Larry, 2026-10-22)

> "Dark mode looks really good as well. 1. Follow the mockup as it looks good. Fill the gaps as needed. 2. Use mockups. They look very good. 3. Default theme = Light, but include Dark and give the user the capacity to switch. Handle ALL of the widget gaps in simple_widgets and simple_shell. Hebrew and Greek need to work in both Light and Dark. Period. Full stop. Exports as light is okay."

| Open item | Ruling |
|---|---|
| Filled vs outlined controls (§4.1) | **Filled, as in the mockups.** Add `ink_on_accent`, with a contrast invariant, as part of GW-28 |
| Type (§8) | **The mockup faces:** IBM Plex Sans (interface), Noto Serif and Noto Serif Hebrew (reading), IBM Plex Mono. All are OFL and bundled under GW-01 |
| Default theme (§2) | **Light.** Dark is included, and the reader can switch (C9 toolbar switch and Settings › Appearance). Match Windows comes with GW-27 |
| Hebrew and Greek | **Must work in both themes, without exception.** This is an acceptance criterion on every text-bearing gap item |
| Exports | **Light by default** (§7) |
| Scope | **Every widget gap, GW-01 to GW-28** (plus any found on the way), filled in simple_widgets and simple_shell, and in simple_shaping and simple_cairo where they own the capability |

## 1. One theme object, two palettes

- Every panel and dialog takes every color from simple_widgets' theme tokens. No literal colors anywhere in simple_bible.
- `SW_THEME.make_light` and `make_dark` already exist. The theme's invariant enforces contrast: ink on surface is at least 4.5:1, and muted ink on surface at least 3:1.
- The dark mockup page was generated from the light page's source by swapping the palette, not redrawn by hand. That is the rule in miniature.

## 2. What the reader chooses (Larry)

- **Settings › Appearance:** Light, Dark, or Match Windows. The toolbar's Dark switch (C9) flips directly between Light and Dark.
- **High contrast** remains a separate setting. Following Windows' high-contrast mode is GW-16 (v1.5).
- **First-run default:** Match Windows once GW-27 lands; Light until then. This is recommended.

## 3. Switching keeps everything

- The switch is instant, with no restart. The reference, tabs, selection, notes, results and jobs all survive, the same rule as Simple ⇄ Study.
- The theme is independent of the Simple/Study layout.
- The choice is persisted in `user.db` settings.

## 4. Toolkit gaps found while making the dark page

1. **Text on filled controls.** White on dark-theme accent `#4D8FD6` is about 3.3:1, which fails the 4.5:1 rule.
   - SW_BUTTON draws primary buttons outlined (surface fill, accent border and label). The mockups draw filled ones, and the dark page substitutes dark text (`#0B1220`) on filled controls.
   - **(Larry)** Keep the outlined style everywhere, OR add an `ink_on_accent` token with an invariant.
2. **Semantic ink on washes.** Status chips and banners put colored text on colored washes. Add a strong ink per semantic color (accent, success, warning, danger), each with invariants against its wash and against the surface, in both themes. Today's invariants check ink and ink_muted on surface only.
3. **Divider and selection tokens.** The mockups use a row divider lighter than `outline` and a selection tint lighter than `wash_accent`. Both should be tokens.
4. **Sequential ramp per theme** for heat maps and charts.

- **GW-28** (simple_widgets): SW_THEME token additions plus their contrast invariants, covering items 1-4.
- **GW-27** (simple_shell): read Windows' app light/dark setting and react to its change notification.

## 5. Hebrew and Greek on dark

- Light-on-dark text renders thinner, and vowel points and cantillation fade first.
- Add both themes to the D-006 spike: pointed WLC Genesis 1:1 with cantillation, at 14-40 px.
- If the marks drop below legibility in dark, raise the dark reading weight (a simple_shaping setting). Do not change the font.

## 6. Meaning never by color alone

- Buckets, statuses, agreement marks, certainty classes and diff marks keep their words, underlines and patterns in both themes.
- Highlights are stored by name (`hl:yellow`) and drawn from the active theme's palette. `SW_MARK_PALETTE` already holds all twelve readable in both themes.

## 7. Maps, timeline, charts, exports

- Charts, the timeline and the atlas draw from theme tokens. The atlas needs a dark map style, so add it to GW-19.
- Copy-as-image and exports (GW-21) default to light, because they get pasted into other people's documents. A setting keeps the screen theme instead.

## 8. Type

- SW_THEME's faces are Archivo (interface), Literata (reading) and IBM Plex Mono. The mockups use IBM Plex Sans and Noto Serif.
- **(Larry)** Which pair? It applies to both themes.

## 9. Testing

- Every panel is rendered offscreen in both themes; no windows open on Larry's desktop.
- Theme invariants are checked at construction.
- Each panel gets a light/dark image pair for review.
