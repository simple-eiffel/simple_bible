# 25 - The meme tool

Status: **built 2026-11-01 (0.7.56): the seed, meme.db (bible_build --memes), BIB_MEME_STORE, the Memes tab, and the installer.**

## 1. What Larry asked for

- A meme tool in Simple Bible: the memes found in his vault, each a picture, a description, and links to the passages it references (Old and New Testament), and to Favorites.
- Reach a meme from the tool, or have the tool answer the passage being read.
- Copy the picture to the clipboard, and copy the description separately, to paste elsewhere.
- Build the contents once; Larry adds more as he goes.
- Shipped with the installer: public, not private.
- Also asked the same day: a right-click on a Favorites folder copies every reference in it.

## 2. The memes found (2026-11-01)

- 123 PNG files under the vault's meme folders (FB Memes and FB Analyses' `_memes`), all distinct by content.
- 79 have a companion note (`NN - slug.md`) with the post copy (the description), the trigger, hook and punch lines, and the passages.
- 20 typographic cards are an earlier design of memes that have notes; 3 wide (16x9) and 8 square pictures are other cuts. Each attaches to its meme as another picture.
- 11 memes without notes (the Facebook Analyses series and one card) were described from their pictures, keeping to the cards' own words and passages.
- 2 pictures were left out: a portrait and a cropped post gathered for an analysis, not memes of Larry's.
- Result: 90 memes, 121 pictures, 167 passage links, about 71 megabytes of pictures.
- Three memes use Creative Commons photographs (a dove, CC BY-SA 4.0; meerkats, CC BY 2.0; sheep, CC BY-SA 2.0). Their credit lines are printed on the pictures; each meme keeps a credit and a license, and the two share-alike ones go out under their photograph's license.

The seed (`memes.seed.json`) sits beside the memes in the vault, picture paths relative to it, so it names no private path.

## 3. Design

- **meme.db** is a data file in `%LOCALAPPDATA%\simple_bible` beside user.db, not a pack in the packs folder (packs attach read-only at start, and the tool writes). `BIB_MEME_SCHEMA` (meta and provenance as every pack, then `meme`, `meme_image`, `meme_passage`); `BIB_MEME_BUILDER` writes it from the seed (`bible_build --memes <seed> --out <meme.db>`), reading each passage with BIB_PASSAGE_TEXT (the reference linker's `reference_at`, as the books read theirs); `BIB_MEME_STORE` reads it and writes Larry's additions.
- **The installer** ships meme.db and installs it only where none exists, so an update never overwrites what Larry added; the next installer built here ships his additions.
- **The window**: a Memes tab: the memes listed (filter, the verse read or all), the chosen one's picture, description and passages (each opens its place), and buttons: Copy picture, Copy description, Add to Favorites, Add meme. With the scope on the verse or chapter read, the list follows the reading place and its heading says how many memes name it. A meme in Favorites is a document favorite ("meme:<slug>").
- **Favorites**: a folder's right-click menu copies its references (and those of its folders), one a line.

## 4. As built (Larry's changes the same day)

- The list shows words only (Meme, Words, Passages, Set); a header click sorts it; a search box filters it; the favorite memes stay at the top under any order (simple_widgets 0.53.0's pinned rows).
- A picture icon in each row: hovering it opens the picture in a card (simple_widgets 0.54.0). The picture is read from meme.db and decoded only then, and the one before it is destroyed: at most one picture in memory (Larry: lazy, never all at once).
- Copy picture (in the cut chosen: feed, typographic, square or wide) and Copy description; the star makes a meme a favorite (a Memes folder in Favorites); Add meme keeps a new one.
- Pictures decode from bytes with simple_cairo 1.7.0's make_from_png_data.
- Pills T6.6 (the list) and T6.7 (the chosen meme).
- 0.7.57 (Larry, the same night): Edit... opens a sheet with the meme's title, its words (type over them, or select all and paste new ones) and its passages as one line separated by semicolons; Save replaces them in meme.db in one transaction (BIB_MEME_STORE.edit_meme), and a passage that does not read is told, changing nothing.
