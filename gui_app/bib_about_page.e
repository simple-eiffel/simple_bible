note
	description: "[
		Help > About (2026-10-30, Larry: "include version, description, and
		attribution to simple Eiffel libraries and to Eiffel studio and Eiffel
		software as well as the Bibles, and other sources like Franklin's work and
		so on ... so everyone needing mention and credit is represented"): the page
		the About window shows, as Markdown.

		Two kinds of credit. The data's are generated from what is open
		(SIMPLE_BIBLE.credits: each Bible version, the concordance's corpora and
		lexicons, each pack's sources, with their licenses), so a new version or
		pack names itself. The program's are written here: the compiler and the
		libraries built in (the window target's library closure, 2026-10-30), the
		tools and art shipped beside it, and the works the scholar guides follow.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ABOUT_PAGE

create
	make

feature {NONE} -- Initialization

	make (a_bible: SIMPLE_BIBLE; a_open_now: READABLE_STRING_GENERAL)
			-- The page for `a_bible', with `a_open_now' saying what data and helpers are open.
		do
			bible := a_bible
			create open_now.make_from_string_general (a_open_now)
		end

feature -- Access

	bible: SIMPLE_BIBLE

	open_now: STRING_32
			-- What data and helpers are open, as the status bar says.

	text: STRING_32
			-- The whole page.
		do
			create Result.make (12000)
			Result.append ({STRING_32} "# Simple Bible%N%N**Version " + {BIB_RELEASE}.Program_version.to_string_32 + {STRING_32} "** (engine "
				+ {BIB_RELEASE}.Engine_version.to_string_32 + {STRING_32} "), personal edition: not for distribution.%N%N")
			Result.append (Description)
			Result.append ({STRING_32} "%N%NOpen now: " + open_now + {STRING_32} "%N%N")
			Result.append ({STRING_32} "## Made by%N%NLarry Rix, in Eiffel.%N%N")
			Result.append (Eiffel_credits)
			Result.append (simple_credits)
			Result.append (Inside_credits)
			Result.append (Art_credits)
			Result.append ({STRING_32} "# The data%N%NEach source as the data records it, with its license.%N%N")
			if bible.is_open then
				Result.append (bible.credits)
			else
				Result.append ({STRING_32} "No data is open, so no source is named.%N")
			end
			Result.append (guide_credits)
		ensure
			names_the_version: Result.has_substring ({BIB_RELEASE}.Program_version.to_string_32)
		end

feature {NONE} -- The program's credits

	Description: STRING_32 = "[
Simple Bible is a Bible study program for one reader: the Bible in many versions and in its original languages side by side, the Hebrew and Greek words under the English with a concordance and lexicons, cross-references, Larry Rix's commentary, books, essays and frameworks, the reader's own notes, journal, bookmarks and prayers, notes and study guides brought in through ingest kits, and Ask, which answers plain requests on this computer.
]"

	Eiffel_credits: STRING_32 = "[
## Eiffel

- **EiffelStudio 25.02, Eiffel Software** (Goleta, California; https://www.eiffel.com): the Eiffel compiler, EiffelBase and its extension, and the Time, JSON and TAR libraries built into the program. Eiffel, the method and the language, is the work of Bertrand Meyer.
- **The Gobo Eiffel Project** (Eric Bezault; MIT License): its decimal and regular-expression libraries.


]"

	simple_credits: STRING_32
			-- The Simple Eiffel libraries built into the window program.
		do
			create Result.make (800)
			Result.append ({STRING_32} "## Simple Eiffel libraries%N%NBy Larry Rix, MIT License (https://github.com/simple-eiffel): ")
			across Simple_libraries as ic loop
				Result.append (ic)
				Result.append (if ic.same_string (Simple_libraries [Simple_libraries.upper]) then {STRING_32} ".%N%N" else {STRING_32} ", " end)
			end
		end

	Simple_libraries: ARRAY [STRING_32]
			-- The window target's simple_* library closure (simple_bible_app.ecf, target bible_gui,
			-- each library's own library target, 2026-10-30).
		once
			Result := <<{STRING_32} "simple_archive", {STRING_32} "simple_base64", {STRING_32} "simple_bible", {STRING_32} "simple_cairo",
				{STRING_32} "simple_datetime", {STRING_32} "simple_decimal", {STRING_32} "simple_document", {STRING_32} "simple_encoding",
				{STRING_32} "simple_env", {STRING_32} "simple_factory", {STRING_32} "simple_file", {STRING_32} "simple_json",
				{STRING_32} "simple_markdown", {STRING_32} "simple_mml", {STRING_32} "simple_pdf", {STRING_32} "simple_process",
				{STRING_32} "simple_reflection", {STRING_32} "simple_shaping", {STRING_32} "simple_shell", {STRING_32} "simple_sorter",
				{STRING_32} "simple_sql", {STRING_32} "simple_uuid", {STRING_32} "simple_widgets", {STRING_32} "simple_zstring">>
		end

	Inside_credits: STRING_32 = "[
## Inside the program

- **SQLite** (public domain), through eiffel_sqlite_2025: every database the program reads.
- **cairo** 2D graphics (LGPL 2.1 or MPL 1.1), through simple_cairo: the window's drawing.
- **minizip-ng** 4.0.10 and **zlib** (zlib License), through simple_archive: opening Word, LibreOffice and EPUB files for ingest kits.
- **Poppler's pdftotext** 24.08.0 (GPL 2.0 or later) and the libraries it needs, through simple_pdf: reading PDF files for ingest kits. Its notice, the license and where its source is are in the pdf folder beside the program.
- **Cactus Needle** (Apache License 2.0): Ask's on-device helper and its model. Its license and notice are in the ask folder beside the program.


]"

	Art_credits: STRING_32 = "[
## Fonts and pictures

- **Archivo** (Omnibus-Type), **Literata** (TypeTogether), **IBM Plex Mono** (IBM) and **Noto Serif Hebrew** (Google): SIL Open Font License 1.1; the license texts are in the fonts-licenses folder.
- **Noto Emoji** pictures (Google LLC and the Noto Emoji contributors; Apache License 2.0): see LICENSE-ASSETS.md beside the program.


]"

	guide_credits: STRING_32
			-- The works the scholar guides follow, when a guides pack is open, and the Enoch margin
			-- references their suggestions draw on.
		local
			l_works: ARRAYED_LIST [STRING_32]
			l_work: STRING_32
		do
			create Result.make (600)
			create l_works.make (4)
			if bible.is_open then
				across bible.text_packs_of_kind ({BIB_GUIDE_SCHEMA}.Pack_kind) as ic_pack loop
					if ic_pack.is_available and then attached ic_pack.books as al_books and then al_books.is_success then
						across 1 |..| al_books.count as al_i loop
							l_work := work_of (al_books.item (al_i))
							if not l_work.is_empty and then not across l_works as al_w some al_w.same_string (l_work) end then
								l_works.extend (l_work)
							end
						end
					end
				end
			end
			if not l_works.is_empty then
				Result.append ({STRING_32} "%N## The works the Scholar Guides follow%N%NStudy guides for private study, chapter by chapter, to:%N%N")
				across l_works as ic loop
					Result.append ({STRING_32} "- " + ic + {STRING_32} "%N")
				end
				Result.append ({STRING_32} "%NTheir suggested passages draw on the margin references of Jerry D. Franklin, *The Book of 1st Enoch* (Study Edition), First Century Version (Cassilis Publishing, 2024).%N")
			end
		end

	work_of (a_guide: BIB_AUTHOR_BOOK): STRING_32
			-- "Heiser: The Unseen Realm: ... (Lexham Press, 2015)": the guide's work, from its record (the
			-- author's surname in the edition, the work in the description's first sentence).
		local
			l_author: STRING_32
			l_end, l_paren: INTEGER
		do
			create Result.make_empty
			l_end := a_guide.description.substring_index ({STRING_32} ". A study guide", 1)
			if l_end > 1 then
				Result := a_guide.description.substring (1, l_end - 1)
				l_paren := Result.substring_index ({STRING_32} " (", 1)
				if l_paren > 1 then
						-- the title in italics, its publisher and year not
					Result := {STRING_32} "*" + Result.substring (1, l_paren - 1) + {STRING_32} "*" + Result.substring (l_paren, Result.count)
				else
					Result := {STRING_32} "*" + Result + {STRING_32} "*"
				end
				if a_guide.edition.has (',') then
					l_author := a_guide.edition.substring (1, a_guide.edition.index_of (',', 1) - 1)
					Result := l_author + {STRING_32} ", " + Result
				end
			end
		end

end
