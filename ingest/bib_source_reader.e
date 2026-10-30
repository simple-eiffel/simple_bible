note
	description: "[
		The text of a source an ingest kit is made from (2026-10-30): the one
		place that knows which files are sources and how each kind reads, so a
		kit for one file and kits for a folder read alike.

		THE KINDS (Larry, 2026-10-30, the ingest plan's readers):
		 - plain text and Markdown, as they are;
		 - HTML (.html, .htm, .xhtml), its text as Markdown (BIB_MARKUP_TEXT);
		 - Word (.docx: word/document.xml) and LibreOffice text (.odt:
		   content.xml), opened with simple_archive, their text as Markdown;
		 - EPUB: its pages in reading order (the package's spine);
		 - PDF: Poppler's pdftotext through simple_pdf, in reading order, its
		   lines joined back into paragraphs. pdftotext and its libraries ship in
		   a pdf folder beside the program (SIMPLE_BIBLE_PDF names another for a
		   development run). A scanned PDF has no text to read.

		Not a source: a kit (".kit.md") or a prepared file (".prepared.md"),
		though both end in ".md". A path with letters beyond ASCII is read from a
		short-lived copy, since the archive and PDF tools take 8-bit paths.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SOURCE_READER

feature -- Kinds

	is_source_name (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_name' name a source of a kind this reader reads, not a kit or a prepared file?
		local
			l_name: STRING_32
		do
			l_name := a_name.to_string_32.as_lower
			if not l_name.ends_with (Kit_extension) and not l_name.ends_with (Prepared_extension) then
				Result := across Extensions as ic some l_name.ends_with (ic) end
			end
		end

	Extensions: ARRAY [STRING_32]
			-- The endings of the sources it reads.
		once
			Result := <<{STRING_32} ".txt", {STRING_32} ".md", {STRING_32} ".docx", {STRING_32} ".odt", {STRING_32} ".epub",
				{STRING_32} ".html", {STRING_32} ".htm", {STRING_32} ".xhtml", {STRING_32} ".pdf">>
		end

	dialog_filter: STRING_32
			-- The file dialog's pattern for sources: "*.txt;*.md;...".
		do
			create Result.make (80)
			across Extensions as ic loop
				if not Result.is_empty then
					Result.append_character (';')
				end
				Result.append ({STRING_32} "*" + ic)
			end
		end

	Kit_extension: STRING_32 = ".kit.md"

	Prepared_extension: STRING_32 = ".prepared.md"

feature -- Reading

	text_of (a_path: READABLE_STRING_GENERAL): detachable STRING_32
			-- The text of the source at `a_path', as Markdown for the markup kinds; Void, with
			-- `last_error', when it cannot be read or holds no text.
		local
			l_file: SIMPLE_FILE
			l_path, l_name: STRING_32
		do
			last_error := Void
			create l_path.make_from_string_general (a_path)
			create l_file.make (l_path)
			l_name := l_file.file_name.as_lower
			if not l_file.is_file then
				last_error := {STRING_32} "No file at " + l_path
			elseif not is_source_name (l_file.file_name) then
				last_error := {STRING_32} "Not a kind of file a kit is made from: " + l_file.file_name
			elseif l_name.ends_with ({STRING_32} ".txt") or l_name.ends_with ({STRING_32} ".md") then
				Result := plain_text (l_file)
			elseif l_name.ends_with ({STRING_32} ".html") or l_name.ends_with ({STRING_32} ".htm") or l_name.ends_with ({STRING_32} ".xhtml") then
				if attached plain_text (l_file) as al_html then
					Result := (create {BIB_MARKUP_TEXT}.make_html).text_of (al_html)
				end
			elseif l_name.ends_with ({STRING_32} ".docx") then
				if attached archive_entry (l_path, "word/document.xml") as al_xml then
					Result := (create {BIB_MARKUP_TEXT}.make_docx).text_of (al_xml)
				end
			elseif l_name.ends_with ({STRING_32} ".odt") then
				if attached archive_entry (l_path, "content.xml") as al_xml then
					Result := (create {BIB_MARKUP_TEXT}.make_odt).text_of (al_xml)
				end
			elseif l_name.ends_with ({STRING_32} ".epub") then
				Result := epub_text (l_path)
			else
				Result := pdf_text (l_path)
			end
			drop_local_copy
			if attached Result as al_text and then al_text.is_empty then
				Result := Void
				last_error := {STRING_32} "No text in " + l_file.file_name
					+ (if l_name.ends_with ({STRING_32} ".pdf") then {STRING_32} " (a scanned PDF holds pictures of pages, not text: OCR it first)" else {STRING_32} "" end)
			elseif Result = Void and last_error = Void then
				last_error := {STRING_32} "It could not be read: " + l_file.file_name
			elseif Result /= Void then
				last_error := Void
			end
		ensure
			read_or_why: (Result = Void) = (last_error /= Void)
			text_when_read: attached Result as r implies not r.is_empty
		end

	last_error: detachable STRING_32
			-- Why the last `text_of' read nothing.

	pdf_tool: STRING_32
			-- Where pdftotext is: SIMPLE_BIBLE_PDF's folder (a development run), else the pdf folder
			-- beside the program.
		do
			if attached (create {SIMPLE_ENV}).item ("SIMPLE_BIBLE_PDF") as al_folder and then not al_folder.is_empty then
				Result := al_folder.to_string_32 + {STRING_32} "\pdftotext.exe"
			else
				Result := (create {SIMPLE_ENV}).executable_folder.to_string_32 + {STRING_32} "\pdf\pdftotext.exe"
			end
		end

	is_pdf_readable: BOOLEAN
			-- Is pdftotext where `pdf_tool' looks?
		do
			Result := (create {SIMPLE_FILE}.make (pdf_tool)).is_file
		end

feature {NONE} -- The kinds

	plain_text (a_file: SIMPLE_FILE): detachable STRING_32
			-- The text of `a_file' as UTF-8; Void, with `last_error', when it cannot be read.
		do
			Result := a_file.read_text_utf_8
			if not Result.is_empty and then Result [1].code = 0xFEFF then
					-- scan 72: a byte-order mark is no text
				Result.remove_head (1)
			end
			if a_file.last_error_code /= 0 then
					-- scan 71: it could not be read, so no empty kit is made from it
				last_error := {STRING_32} "It could not be read: " + a_file.file_name
				Result := Void
			end
		end

	archive_entry (a_path, a_entry: READABLE_STRING_GENERAL): detachable STRING_32
			-- The entry `a_entry' of the zip archive at `a_path', read as UTF-8; Void, with `last_error',
			-- when the archive or the entry is not there.
		local
			l_zip: SIMPLE_ZIP
		do
			create l_zip.make
			if not attached local_path (a_path) as l_local then
					-- `last_error' says why
			elseif not l_zip.is_valid_archive (l_local) then
				last_error := {STRING_32} "Not a readable archive: " + (create {SIMPLE_FILE}.make (a_path)).file_name
			elseif attached l_zip.extract_entry (l_local, {UTF_CONVERTER}.string_32_to_utf_8_string_8 (a_entry.to_string_32)) as al_bytes and then l_zip.last_error.is_empty then
				Result := {UTF_CONVERTER}.utf_8_string_8_to_string_32 (al_bytes)
			else
				last_error := {STRING_32} "No " + a_entry.to_string_32 + {STRING_32} " in " + (create {SIMPLE_FILE}.make (a_path)).file_name
			end
		end

	epub_text (a_path: STRING_32): detachable STRING_32
			-- The pages of the EPUB at `a_path' in reading order: META-INF/container.xml names the
			-- package, whose spine orders the manifest's pages.
		local
			l_markup: BIB_MARKUP_TEXT
			l_package: detachable STRING_32
			l_base: STRING_32
			l_pages: HASH_TABLE [STRING_32, STRING_32]
		do
			create l_markup.make_html
			if attached archive_entry (a_path, "META-INF/container.xml") as al_container then
				across l_markup.tags_named (al_container, "rootfile") as ic until l_package /= Void loop
					l_package := l_markup.attribute_of (ic, "full-path")
				end
				if attached l_package as al_package and then attached archive_entry (a_path, al_package) as al_opf then
					l_base := if al_package.has ('/') then al_package.substring (1, al_package.last_index_of ('/', al_package.count)) else {STRING_32} "" end
					create l_pages.make (32)
					across l_markup.tags_named (al_opf, "item") as ic loop
						if attached l_markup.attribute_of (ic, "id") as al_id and then attached l_markup.attribute_of (ic, "href") as al_href then
							l_pages.force (archive_path (l_base, url_decoded (al_href)), al_id)
						end
					end
					create Result.make (20000)
					across l_markup.tags_named (al_opf, "itemref") as ic loop
						if attached l_markup.attribute_of (ic, "idref") as al_idref and then attached l_pages.item (al_idref) as al_page
							and then attached archive_entry (a_path, al_page) as al_html
						then
							Result.append ((create {BIB_MARKUP_TEXT}.make_html).text_of (al_html))
							Result.append_character ('%N')
						end
					end
					Result.right_adjust
				elseif last_error = Void then
					last_error := {STRING_32} "The EPUB names no package: " + (create {SIMPLE_FILE}.make (a_path)).file_name
				end
			end
		end

feature -- Text

	archive_path (a_base, a_href: STRING_32): STRING_32
			-- The entry a package in folder `a_base' names by `a_href': its "#part" dropped, "../" and
			-- "./" read (scan 72: "../Text/ch1.xhtml" lost its page).
		local
			l_parts: LIST [STRING_32]
			l_kept: ARRAYED_LIST [STRING_32]
			l_href: STRING_32
		do
			l_href := a_href.twin
			if l_href.has ('#') then
				l_href := l_href.substring (1, l_href.index_of ('#', 1) - 1)
			end
			l_parts := (a_base + l_href).split ('/')
			create l_kept.make (l_parts.count)
			across l_parts as ic loop
				if ic.same_string ({STRING_32} "..") then
					if not l_kept.is_empty then
						l_kept.finish
						l_kept.remove
					end
				elseif not ic.is_empty and not ic.same_string ({STRING_32} ".") then
					l_kept.extend (ic)
				end
			end
			create Result.make (l_href.count + a_base.count)
			across l_kept as ic loop
				if not Result.is_empty then
					Result.append_character ('/')
				end
				Result.append (ic)
			end
		end

feature {NONE} -- PDF

	pdf_text (a_path: STRING_32): detachable STRING_32
			-- The text of the PDF at `a_path' in reading order (simple_pdf's flowing text), its lines
			-- joined back into paragraphs (`prose_from_pdf').
		local
			l_reader: SIMPLE_PDF_READER
			l_text: STRING_32
		do
			if not is_pdf_readable then
				last_error := {STRING_32} "Reading a PDF needs the pdf folder beside Simple Bible (its installer puts it there); not found at " + pdf_tool
			else
				create l_reader.make_with_path ({UTF_CONVERTER}.string_32_to_utf_8_string_8 (pdf_tool))
				if attached local_path (a_path) as al_local then
					l_text := l_reader.extract_text_flowing (al_local)
					if attached l_reader.last_error as al_error then
						last_error := {STRING_32} "The PDF could not be read: " + al_error.to_string_32
					else
						Result := prose_from_pdf (l_text)
					end
				end
			end
		end

feature -- Text

	prose_from_pdf (a_text: READABLE_STRING_GENERAL): STRING_32
			-- `a_text' as pdftotext writes it (a line per printed line, a blank line between most
			-- blocks) made paragraphs: each block's lines joined by a space, a word hyphenated at a
			-- line's end joined whole, the marks that steer right-to-left text dropped (they split
			-- Hebrew; an ending mark leaves a space). A heading (`is_heading_at') is a paragraph of its
			-- own, as pdftotext often writes no blank line around one.
		local
			l_text, l_line, l_paragraph: STRING_32
			l_lines: ARRAYED_LIST [STRING_32]
			i, l_width: INTEGER
		do
			create l_text.make_from_string_general (a_text)
			l_text.replace_substring_all ({STRING_32} "%R%N", {STRING_32} "%N")
			across Direction_marks as ic loop
				if ic.code = 0x202C or ic.code = 0x2069 then
					l_text.replace_substring_all (create {STRING_32}.make_filled (ic, 1), {STRING_32} " ")
				else
					l_text.prune_all (ic)
				end
			end
			create l_lines.make (200)
			across l_text.split ('%N') as ic loop
				l_line := ic.twin
				l_line.left_adjust
				l_line.right_adjust
				from until not l_line.has_substring ({STRING_32} "  ") loop
					l_line.replace_substring_all ({STRING_32} "  ", {STRING_32} " ")
				end
				l_lines.extend (l_line)
				l_width := l_width.max (l_line.count)
			end
			create Result.make (l_text.count)
			create l_paragraph.make (400)
			from i := 1 until i > l_lines.count loop
				l_line := l_lines.i_th (i)
				if l_line.is_empty or else is_heading_at (l_lines, i, l_width) then
					if not l_paragraph.is_empty then
						Result.append (l_paragraph + {STRING_32} "%N%N")
						l_paragraph.wipe_out
					end
					if not l_line.is_empty then
						Result.append (l_line + {STRING_32} "%N%N")
					end
				elseif l_paragraph.is_empty then
					l_paragraph.append (l_line)
				elseif l_paragraph [l_paragraph.count] = '-' and then l_line [1].is_lower then
						-- "resur-" "rection": one word
					l_paragraph.remove_tail (1)
					l_paragraph.append (l_line)
				else
					l_paragraph.append_character (' ')
					l_paragraph.append (l_line)
				end
				i := i + 1
			end
			if not l_paragraph.is_empty then
				Result.append (l_paragraph)
			end
			Result.right_adjust
		end

	is_heading_at (a_lines: LIST [STRING_32]; a_index, a_width: INTEGER): BOOLEAN
			-- Is line `a_index' of `a_lines' (the widest `a_width' long) a heading: short beside the
			-- page's lines, a capital first and no closing mark last, after a blank line or a sentence's
			-- end and before a blank line or a capital? (Scan 72: a short line in a narrow column, or a
			-- heading with no blank line before it, was read wrongly.)
		require
			in_range: a_index >= 1 and a_index <= a_lines.count
		local
			l_line: STRING_32
		do
			l_line := a_lines.i_th (a_index)
			if not l_line.is_empty and then l_line [1].is_upper and then l_line.count < Heading_width
				and then l_line.count * 10 < a_width * 6 and then not ends_a_sentence (l_line, True)
			then
				Result := (a_index = 1 or else a_lines.i_th (a_index - 1).is_empty or else ends_a_sentence (a_lines.i_th (a_index - 1), False))
					and then (a_index = a_lines.count or else a_lines.i_th (a_index + 1).is_empty or else a_lines.i_th (a_index + 1) [1].is_upper)
			end
		end

	ends_a_sentence (a_line: STRING_32; a_any_mark: BOOLEAN): BOOLEAN
			-- Does `a_line' end in a sentence's last mark (any closing mark when `a_any_mark')?
		do
			if not a_line.is_empty then
				inspect a_line [a_line.count]
				when '.', '!', '?', ':', '"', '%/0x201D/' then
					Result := True
				when ',', ';', ')', ']', '%'', '%/0x2019/' then
					Result := a_any_mark
				else
				end
			end
		end

	Heading_width: INTEGER = 60
			-- The longest a line read as a heading may be.

feature {NONE} -- Decoding

	Direction_marks: ARRAY [CHARACTER_32]
			-- The invisible marks that steer right-to-left text (U+200E, U+200F, U+202A to U+202E,
			-- U+2066 to U+2069).
		once
			Result := <<'%/0x200E/', '%/0x200F/', '%/0x202A/', '%/0x202B/', '%/0x202C/', '%/0x202D/', '%/0x202E/',
				'%/0x2066/', '%/0x2067/', '%/0x2068/', '%/0x2069/'>>
		end

	url_decoded (a_href: STRING_32): STRING_32
			-- `a_href' with "%20" and its kind read back, as an EPUB package may write a page's name.
		local
			i, l_high, l_low: INTEGER
			l_bytes: STRING_8
		do
			if not a_href.has ('%%') then
				Result := a_href
			else
				create l_bytes.make (a_href.count)
				from i := 1 until i > a_href.count loop
					l_high := -1
					l_low := -1
					if a_href [i] = '%%' and then i + 2 <= a_href.count then
						l_high := ("0123456789abcdef").index_of (a_href [i + 1].as_lower.to_character_8, 1) - 1
						l_low := ("0123456789abcdef").index_of (a_href [i + 2].as_lower.to_character_8, 1) - 1
					end
					if l_high >= 0 and l_low >= 0 then
						l_bytes.append_character ((l_high * 16 + l_low).to_character_8)
						i := i + 3
					else
						l_bytes.append ({UTF_CONVERTER}.string_32_to_utf_8_string_8 (a_href.substring (i, i)))
						i := i + 1
					end
				end
				Result := {UTF_CONVERTER}.utf_8_string_8_to_string_32 (l_bytes)
			end
		end

feature {NONE} -- Paths

	local_path (a_path: READABLE_STRING_GENERAL): detachable STRING_8
			-- `a_path' for a tool that takes an 8-bit path: as it is when plain ASCII, else a copy in
			-- the temporary folder (`drop_local_copy' removes it); Void, with `last_error', when the
			-- copy could not be made (scan 72: the tools were given a path to nothing).
		local
			l_path, l_copy: STRING_32
			l_dot: INTEGER
			l_ok: BOOLEAN
		do
			create l_path.make_from_string_general (a_path)
			if across l_path as ic all ic.code < 128 end then
				Result := l_path.to_string_8
			else
				l_dot := l_path.last_index_of ('.', l_path.count)
				l_copy := temp_folder + {STRING_32} "\simple_bible_source" + (if l_dot > 0 then l_path.substring (l_dot, l_path.count) else {STRING_32} "" end)
				if attached local_copy as al_copy and then al_copy.same_string (l_copy) then
					Result := l_copy.to_string_8
				else
					l_ok := (create {SIMPLE_FILE}.make (l_path)).copy_to (l_copy)
					if l_ok then
						local_copy := l_copy
						Result := l_copy.to_string_8
					else
						last_error := {STRING_32} "A copy to read could not be made in " + temp_folder
					end
				end
			end
		end

	local_copy: detachable STRING_32
			-- The copy `local_path' made, until `drop_local_copy'.

	drop_local_copy
			-- The copy `local_path' made, removed.
		local
			l_ok: BOOLEAN
		do
			if attached local_copy as al_copy then
				l_ok := (create {SIMPLE_FILE}.make (al_copy)).delete
				local_copy := Void
			end
		end

	temp_folder: STRING_32
			-- The temporary folder when its path is plain ASCII, else the system's.
		do
			if attached (create {SIMPLE_ENV}).item ("TEMP") as al_temp and then across al_temp.to_string_32 as ic all ic.code < 128 end then
				Result := al_temp.to_string_32
			else
				Result := {STRING_32} "C:\Windows\Temp"
			end
		end

end
