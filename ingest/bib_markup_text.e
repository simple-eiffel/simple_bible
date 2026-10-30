note
	description: "[
		Markup turned into the plain Markdown an ingest kit carries (2026-10-30,
		Larry: kits from Word, LibreOffice, EPUB and HTML files): one scanner for
		the XML inside a Word file (word/document.xml), a LibreOffice text
		(content.xml), and HTML or an EPUB's pages. A heading becomes a "#" line,
		paragraphs are parted by a blank line, a list item begins "- "; every
		other tag is read for what it means and dropped, and character
		references are decoded.

		WHY A SCANNER: mixed content keeps its order ("Hello <span>world</span>
		again"), which simple_xml's element model does not give, and HTML need
		not be well-formed XML. Each kind of file names its own tags.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_MARKUP_TEXT

create
	make_html,
	make_docx,
	make_odt

feature {NONE} -- Initialization

	make_html
			-- A reader of HTML and XHTML (an EPUB's pages).
		do
			kind := Html_kind
			create block.make (200)
			create output.make_empty
		end

	make_docx
			-- A reader of a Word file's word/document.xml.
		do
			kind := Docx_kind
			create block.make (200)
			create output.make_empty
		end

	make_odt
			-- A reader of a LibreOffice text's content.xml.
		do
			kind := Odt_kind
			create block.make (200)
			create output.make_empty
		end

feature -- Access

	kind: INTEGER
			-- Which markup it reads: `Html_kind', `Docx_kind' or `Odt_kind'.

	Html_kind: INTEGER = 1
	Docx_kind: INTEGER = 2
	Odt_kind: INTEGER = 3

feature -- Conversion

	text_of (a_markup: READABLE_STRING_GENERAL): STRING_32
			-- `a_markup' as Markdown: headings, paragraphs and list items, nothing else.
		local
			l_markup: STRING_32
			i, j: INTEGER
		do
			create l_markup.make_from_string_general (a_markup)
			create output.make (l_markup.count // 3 + 16)
			block.wipe_out
			heading := 0
			is_item := False
			skipping := Void
			in_docx_text := False
			in_pre := False
			from i := 1 until i > l_markup.count loop
				if l_markup [i] = '<' then
					if is_at (l_markup, i, "<!--") then
						j := l_markup.substring_index ({STRING_32} "-->", i + 4)
						i := if j = 0 then l_markup.count + 1 else j + 3 end
					elseif is_at (l_markup, i, "<![CDATA[") then
						j := l_markup.substring_index ({STRING_32} "]]>", i + 9)
						if j = 0 then
							j := l_markup.count + 1
						end
						add_text (l_markup.substring (i + 9, j - 1), False)
						i := j + 3
					elseif i < l_markup.count and then (l_markup [i + 1] = '?' or l_markup [i + 1] = '!') then
						j := l_markup.index_of ('>', i)
						i := if j = 0 then l_markup.count + 1 else j + 1 end
					else
						j := tag_end (l_markup, i)
						if j = 0 then
							i := l_markup.count + 1
						else
							read_tag (l_markup.substring (i + 1, j - 1))
							i := j + 1
						end
					end
				else
					j := l_markup.index_of ('<', i)
					if j = 0 then
						j := l_markup.count + 1
					end
					add_text (l_markup.substring (i, j - 1), True)
					i := j
				end
			end
			end_block
			Result := output
			Result.right_adjust
			if not Result.is_empty then
				Result.append_character ('%N')
			end
		end

feature -- Tags in XML

	tags_named (a_xml: READABLE_STRING_GENERAL; a_name: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- The attribute text of every tag in `a_xml' named `a_name' (any prefix: "item" finds
			-- "opf:item"), in order: an EPUB's container and package files.
		local
			l_xml, l_tag, l_name, l_wanted: STRING_32
			i, j, l_end: INTEGER
		do
			create Result.make (8)
			create l_xml.make_from_string_general (a_xml)
			l_wanted := a_name.to_string_32.as_lower
			from i := l_xml.index_of ('<', 1) until i = 0 loop
				j := tag_end (l_xml, i)
				if j = 0 then
					i := 0
				else
					l_tag := l_xml.substring (i + 1, j - 1)
					l_end := name_end (l_tag)
					if l_end > 0 then
						l_name := l_tag.substring (1, l_end).as_lower
						if l_name.has (':') then
							l_name := l_name.substring (l_name.last_index_of (':', l_name.count) + 1, l_name.count)
						end
						if l_name.same_string (l_wanted) then
							Result.extend (l_tag.substring (l_end + 1, l_tag.count))
						end
					end
					i := l_xml.index_of ('<', j)
				end
			end
		end

	attribute_of (a_attributes, a_name: READABLE_STRING_GENERAL): detachable STRING_32
			-- The value of attribute `a_name' in a tag's attribute text `a_attributes', decoded.
		local
			l_text, l_name: STRING_32
			i, l_quote_at, l_close: INTEGER
		do
			create l_text.make_from_string_general (a_attributes)
			l_name := a_name.to_string_32 + {STRING_32} "="
			from i := l_text.substring_index (l_name, 1) until i = 0 or Result /= Void loop
				l_quote_at := i + l_name.count
				if (i = 1 or else l_text [i - 1].is_space) and then l_quote_at <= l_text.count
					and then (l_text [l_quote_at] = '"' or l_text [l_quote_at] = '%'')
				then
					l_close := l_text.index_of (l_text [l_quote_at], l_quote_at + 1)
					if l_close > 0 then
						Result := decoded (l_text.substring (l_quote_at + 1, l_close - 1))
					end
				end
				if Result = Void then
					i := l_text.substring_index (l_name, i + 1)
				end
			end
		end

	decoded (a_text: READABLE_STRING_GENERAL): STRING_32
			-- `a_text' with its character references read: "&amp;", "&#8212;", "&#x2014;", "&mdash;".
		local
			l_text, l_entity: STRING_32
			i, l_semi, l_code: INTEGER
		do
			create l_text.make_from_string_general (a_text)
			if not l_text.has ('&') then
				Result := l_text
			else
				create Result.make (l_text.count)
				from i := 1 until i > l_text.count loop
					l_semi := 0
					if l_text [i] = '&' then
						l_semi := l_text.index_of (';', i + 1)
						if l_semi > 0 and then l_semi - i > 10 then
							l_semi := 0
						end
					end
					if l_semi > 0 then
						l_entity := l_text.substring (i + 1, l_semi - 1)
						l_code := 0
						if l_entity.count >= 2 and then l_entity [1] = '#' and then (l_entity [2] = 'x' or l_entity [2] = 'X') then
							l_code := hex_value (l_entity.substring (3, l_entity.count))
						elseif l_entity.count >= 2 and then l_entity [1] = '#' and then l_entity.substring (2, l_entity.count).is_natural then
							l_code := l_entity.substring (2, l_entity.count).to_integer
						elseif attached Named_entities.item (l_entity) as al_char then
							l_code := al_char.code
						end
						if l_code > 0 and l_code <= 0x10FFFF then
							Result.append_character (l_code.to_character_32)
							i := l_semi + 1
						else
							Result.append_character ('&')
							i := i + 1
						end
					else
						Result.append_character (l_text [i])
						i := i + 1
					end
				end
			end
		end

feature {NONE} -- Scanning

	output: STRING_32
			-- The Markdown so far.

	block: STRING_32
			-- The text of the block being read.

	heading: INTEGER
			-- The heading level of the block being read; 0 for none.

	is_item: BOOLEAN
			-- Is the block being read a list item?

	skipping: detachable STRING_32
			-- The tag whose content is being passed over ("script", "office:annotation").

	in_docx_text: BOOLEAN
			-- Inside a Word text run (w:t), the only place a Word file keeps its words?

	in_pre: BOOLEAN
			-- Inside HTML preformatted text, whose line breaks stay?

	read_tag (a_tag: STRING_32)
			-- The tag whose text between "<" and ">" is `a_tag', read for what it means.
		local
			l_name, l_attributes: STRING_32
			l_end: INTEGER
			l_close, l_empty: BOOLEAN
		do
			l_close := not a_tag.is_empty and then a_tag [1] = '/'
			l_empty := not a_tag.is_empty and then a_tag [a_tag.count] = '/'
			if l_close then
				l_name := a_tag.substring (2, a_tag.count)
			else
				l_name := a_tag.twin
			end
			l_end := name_end (l_name)
			if l_end > 0 then
				l_attributes := l_name.substring (l_end + 1, l_name.count)
				l_name := l_name.substring (1, l_end).as_lower
				if attached skipping as al_skipped then
					if l_close and l_name.same_string (al_skipped) then
						skipping := Void
					end
				else
					inspect kind
					when Html_kind then
						read_html_tag (l_name, l_attributes, l_close, l_empty)
					when Docx_kind then
						read_docx_tag (l_name, l_attributes, l_close, l_empty)
					else
						read_odt_tag (l_name, l_attributes, l_close, l_empty)
					end
				end
			end
		end

	read_html_tag (a_name, a_attributes: STRING_32; a_close, a_empty: BOOLEAN)
			-- An HTML tag: headings, paragraphs, list items, line breaks; script and style passed over.
		do
			if not a_close and not a_empty and across Html_passed_over as ic some ic.same_string (a_name) end then
				skipping := a_name
			elseif a_name.count = 2 and then a_name [1] = 'h' and then a_name [2] >= '1' and then a_name [2] <= '6' then
				end_block
				if not a_close then
					heading := a_name [2].code - ('0').code
				end
			elseif a_name.same_string ({STRING_32} "li") then
				end_block
				is_item := not a_close
			elseif a_name.same_string ({STRING_32} "pre") then
				end_block
				in_pre := not a_close
			elseif across Html_blocks as ic some ic.same_string (a_name) end then
				end_block
			elseif a_close and (a_name.same_string ({STRING_32} "td") or a_name.same_string ({STRING_32} "th")) then
				block.append_character (' ')
			end
		end

	read_docx_tag (a_name, a_attributes: STRING_32; a_close, a_empty: BOOLEAN)
			-- A Word tag: paragraphs (w:p) and their style (a heading, a list item), text runs (w:t),
			-- tabs and breaks. Deleted text (w:delText) and field codes (w:instrText) are no runs.
		local
			l_style: STRING_32
		do
			if a_name.same_string ({STRING_32} "w:p") then
				end_block
			elseif a_name.same_string ({STRING_32} "w:t") then
				in_docx_text := not a_close and not a_empty
			elseif a_name.same_string ({STRING_32} "w:pstyle") and then attached attribute_of (a_attributes, "w:val") as al_value then
				l_style := al_value.as_lower
				l_style.prune_all (' ')
				if l_style.same_string ({STRING_32} "title") then
					heading := 1
				elseif l_style.starts_with ({STRING_32} "heading") and then l_style.count = 8 and then l_style [8].is_digit then
					heading := (l_style [8].code - ('0').code).max (1)
				end
			elseif a_name.same_string ({STRING_32} "w:numpr") then
				is_item := True
			elseif a_name.same_string ({STRING_32} "w:tab") or a_name.same_string ({STRING_32} "w:br") or a_name.same_string ({STRING_32} "w:cr") then
				block.append_character (' ')
			end
		end

	read_odt_tag (a_name, a_attributes: STRING_32; a_close, a_empty: BOOLEAN)
			-- A LibreOffice tag: headings (text:h and its outline level), paragraphs, list items,
			-- spaces (text:s), tabs and breaks; notes, comments and tracked deletions passed over.
		do
			if not a_close and not a_empty and across Odt_passed_over as ic some ic.same_string (a_name) end then
				skipping := a_name
			elseif a_name.same_string ({STRING_32} "text:h") then
				end_block
				if not a_close then
					heading := 1
					if attached attribute_of (a_attributes, "text:outline-level") as al_level and then al_level.is_integer then
						heading := al_level.to_integer.max (1).min (6)
					end
				end
			elseif a_name.same_string ({STRING_32} "text:p") then
				end_block
			elseif a_name.same_string ({STRING_32} "text:list-item") then
				if not a_close then
					is_item := True
				end
			elseif a_name.same_string ({STRING_32} "text:s") then
				if attached attribute_of (a_attributes, "text:c") as al_count and then al_count.is_integer then
					block.append (create {STRING_32}.make_filled (' ', al_count.to_integer.max (1).min (40)))
				else
					block.append_character (' ')
				end
			elseif a_name.same_string ({STRING_32} "text:tab") or a_name.same_string ({STRING_32} "text:line-break") then
				block.append_character (' ')
			end
		end

	add_text (a_text: STRING_32; a_collapsing: BOOLEAN)
			-- The text `a_text' between tags added to the block: a Word file's only inside a run;
			-- runs of white space made one space unless preformatted or `a_collapsing' is off.
		local
			l_text: STRING_32
			i: INTEGER
		do
			if skipping = Void and (kind /= Docx_kind or in_docx_text) then
				l_text := decoded (a_text)
				if in_pre or not a_collapsing or kind = Docx_kind then
					block.append (l_text)
				else
					from i := 1 until i > l_text.count loop
						if l_text [i].is_space or l_text [i].code = 0xA0 then
							if not block.is_empty and then block [block.count] /= ' ' then
								block.append_character (' ')
							end
						else
							block.append_character (l_text [i])
						end
						i := i + 1
					end
				end
			end
		end

	end_block
			-- The block read so far written out (a heading's "#" marks or an item's "- " first), parted
			-- from the next by a blank line. An empty block keeps its heading and item marks for the
			-- text still to come ("<li><p>...").
		local
			l_text: STRING_32
		do
			l_text := block.twin
			if not in_pre then
				l_text.replace_substring_all ({STRING_32} "%N", {STRING_32} " ")
			end
			l_text.left_adjust
			l_text.right_adjust
			if not l_text.is_empty then
				if heading > 0 then
					output.append (create {STRING_32}.make_filled ('#', heading))
					output.append_character (' ')
				elseif is_item then
					output.append ({STRING_32} "- ")
				end
				output.append (l_text)
				output.append ({STRING_32} "%N%N")
				heading := 0
				is_item := False
			end
			block.wipe_out
		end

	tag_end (a_text: STRING_32; a_start: INTEGER): INTEGER
			-- The ">" closing the tag that opens at `a_start', past any quoted attribute; 0 when none.
		local
			i: INTEGER
			l_quote: CHARACTER_32
		do
			from i := a_start + 1 until i > a_text.count or Result > 0 loop
				if l_quote /= '%U' then
					if a_text [i] = l_quote then
						l_quote := '%U'
					end
				elseif a_text [i] = '"' or a_text [i] = '%'' then
					l_quote := a_text [i]
				elseif a_text [i] = '>' then
					Result := i
				end
				i := i + 1
			end
		end

	name_end (a_tag: STRING_32): INTEGER
			-- Where the name a tag's text begins with ends: before white space or "/"; 0 for no name.
		do
			from Result := 0 until Result >= a_tag.count or else (a_tag [Result + 1].is_space or a_tag [Result + 1] = '/') loop
				Result := Result + 1
			end
		end

	is_at (a_text: STRING_32; a_position: INTEGER; a_word: STRING_32): BOOLEAN
			-- Does `a_word' stand in `a_text' at `a_position'?
		local
			i: INTEGER
		do
			if a_position + a_word.count - 1 <= a_text.count then
				Result := True
				from i := 1 until i > a_word.count or not Result loop
					Result := a_text [a_position + i - 1] = a_word [i]
					i := i + 1
				end
			end
		end

	hex_value (a_digits: STRING_32): INTEGER
			-- `a_digits' read as hexadecimal; 0 when they are not, or too long.
		local
			i, l_digit: INTEGER
		do
			if a_digits.count <= 6 then
				from i := 1 until i > a_digits.count or l_digit < 0 loop
					l_digit := ("0123456789abcdef").index_of (a_digits [i].as_lower.to_character_8, 1) - 1
					if l_digit >= 0 then
						Result := Result * 16 + l_digit
					else
						Result := 0
					end
					i := i + 1
				end
			end
		end

	Html_blocks: ARRAY [STRING_32]
			-- HTML tags that begin or end a block.
		once
			Result := <<{STRING_32} "p", {STRING_32} "div", {STRING_32} "br", {STRING_32} "hr", {STRING_32} "blockquote",
				{STRING_32} "section", {STRING_32} "article", {STRING_32} "header", {STRING_32} "footer", {STRING_32} "aside",
				{STRING_32} "nav", {STRING_32} "main", {STRING_32} "figure", {STRING_32} "figcaption", {STRING_32} "ul",
				{STRING_32} "ol", {STRING_32} "dl", {STRING_32} "dt", {STRING_32} "dd", {STRING_32} "table", {STRING_32} "tr",
				{STRING_32} "body", {STRING_32} "html">>
		end

	Html_passed_over: ARRAY [STRING_32]
			-- HTML tags whose content is no text of the page.
		once
			Result := <<{STRING_32} "script", {STRING_32} "style", {STRING_32} "head", {STRING_32} "noscript",
				{STRING_32} "template", {STRING_32} "svg">>
		end

	Odt_passed_over: ARRAY [STRING_32]
			-- LibreOffice tags whose content is no running text: notes, comments, tracked deletions.
		once
			Result := <<{STRING_32} "text:note", {STRING_32} "office:annotation", {STRING_32} "text:tracked-changes">>
		end

	Named_entities: HASH_TABLE [CHARACTER_32, STRING_32]
			-- The named character references prose uses.
		once
			create Result.make (24)
			Result.put ('&', "amp")
			Result.put ('<', "lt")
			Result.put ('>', "gt")
			Result.put ('"', "quot")
			Result.put ('%'', "apos")
			Result.put (' ', "nbsp")
			Result.put ('%/0x2014/', "mdash")
			Result.put ('%/0x2013/', "ndash")
			Result.put ('%/0x2026/', "hellip")
			Result.put ('%/0x2018/', "lsquo")
			Result.put ('%/0x2019/', "rsquo")
			Result.put ('%/0x201C/', "ldquo")
			Result.put ('%/0x201D/', "rdquo")
			Result.put ('%/0xA9/', "copy")
			Result.put ('%/0xA7/', "sect")
			Result.put ('%/0xB6/', "para")
			Result.put ('%/0x2020/', "dagger")
			Result.put ('%/0xB7/', "middot")
		end

invariant
	a_known_kind: kind = Html_kind or kind = Docx_kind or kind = Odt_kind

end
