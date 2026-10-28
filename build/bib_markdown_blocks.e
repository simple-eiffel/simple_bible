note
	description: "[
		A chapter's Markdown as BLOCKS for the books pack (research/19): each heading,
		paragraph, block quote, list item and fenced code block, in order. A
		heading keeps its text and level; the others keep their Markdown as
		written (an item with its marker, a quote with its ">"), so the blocks
		joined again read as the chapter did.

		CLEANED ON THE WAY: YAML front matter, HTML comments, embedded images and
		horizontal rules are left out; a wiki link becomes its label ("[[ZAKAR#Ch
		4|chapter four]]" reads "chapter four", "[[ZAKAR]]" reads "ZAKAR"); a
		footnote marker "[^3]" reads "[3]" and its note "[^3]: ..." reads "[3] ...";
		a section whose heading is one of `skip_headings' (working notes) is left
		out down to the next heading of its level or above. From COMMENTARY's
		inventory (2026-10-28): a typesetting placeholder, a line wholly
		"*[...]*", is left out, and so is an italic status line ("*Draft ...*")
		before a chapter's first heading.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_MARKDOWN_BLOCKS

create
	make

feature {NONE} -- Initialization

	make (a_skip_headings: ITERABLE [READABLE_STRING_GENERAL])
			-- A splitter that leaves out the sections headed `a_skip_headings' (any case).
		do
			create skip_headings.make (4)
				-- `has' compares text, not identity (oracle gotcha)
			skip_headings.compare_objects
			across a_skip_headings as ic loop
				skip_headings.extend (ic.to_string_32.as_lower)
			end
			create blocks.make (64)
			create current_lines.make (4)
			create current_kind.make_empty
		end

feature -- Access

	blocks: ARRAYED_LIST [TUPLE [kind: STRING_8; level: INTEGER; markdown: STRING_32]]
			-- The blocks of the last `split'.

	skip_headings: ARRAYED_LIST [STRING_32]
			-- Headings whose sections are left out, lowercase.

	is_starting_at_title: BOOLEAN
			-- Does a chapter begin at its first "# " title (an essay: a draft note, a status line or an
			-- image above it left out, and an italic production line of wiki links right under it)?

feature -- Settings

	start_at_title
			-- Begin each chapter at its first "# " title (the essays pack, 2026-10-28).
		do
			is_starting_at_title := True
		ensure
			set: is_starting_at_title
		end

feature -- Splitting

	split (a_markdown: READABLE_STRING_GENERAL)
			-- `blocks' from the chapter text `a_markdown'.
		local
			l_lines: LIST [STRING_32]
			l_line, l_trimmed: STRING_32
			l_in_code: BOOLEAN
			l_skip_level, l_level: INTEGER
		do
			blocks.wipe_out
			reset_current
			if is_starting_at_title then
				l_lines := from_title (without_comments (without_front_matter (a_markdown.to_string_32))).split ('%N')
			else
				l_lines := without_comments (without_front_matter (a_markdown.to_string_32)).split ('%N')
			end
			across l_lines as ic loop
				l_line := ic.twin
				l_line.prune_all ('%R')
				l_trimmed := l_line.twin
				l_trimmed.left_adjust
				l_trimmed.right_adjust
				if l_in_code then
					current_lines.extend (l_line)
					if l_trimmed.starts_with ({STRING_32} "```") then
						l_in_code := False
						flush
					end
				elseif l_skip_level > 0 and then not (heading_level (l_trimmed) > 0 and heading_level (l_trimmed) <= l_skip_level) then
						-- inside a left-out section
				elseif l_trimmed.starts_with ({STRING_32} "```") then
					flush
					current_kind := "code"
					current_lines.extend (l_line)
					l_in_code := True
				elseif l_trimmed.is_empty then
					flush
				elseif is_rule (l_trimmed) then
						-- a horizontal rule: a break, never a block
					flush
				elseif heading_level (l_trimmed) > 0 then
					flush
					l_level := heading_level (l_trimmed)
					l_skip_level := 0
					if skip_headings.has (heading_text (l_trimmed).as_lower) then
						l_skip_level := l_level
					else
						add_block ("heading", l_level, heading_text (l_trimmed))
					end
				elseif is_item (l_trimmed) then
					flush
					current_kind := "item"
					current_lines.extend (l_trimmed)
				elseif l_trimmed.starts_with ({STRING_32} ">") then
					if not current_kind.same_string ("quote") then
						flush
						current_kind := "quote"
					end
					current_lines.extend (l_trimmed)
				else
					if current_kind.is_empty then
						current_kind := "paragraph"
					elseif current_kind.same_string ("quote") then
						flush
						current_kind := "paragraph"
					end
						-- a continuation of a paragraph, or of an item when indented
					current_lines.extend (l_trimmed)
				end
			end
			flush
		ensure
			no_empty_block: across blocks as al_b all not al_b.markdown.is_empty end
		end

feature {NONE} -- An essay's start

	from_title (a_text: STRING_32): STRING_32
			-- `a_text' from its first "# " title line on; and, when the first line after the title is
			-- one italic line holding wiki links (Good Ground's production line), without it. All of
			-- `a_text' when it has no title.
		local
			l_start, l_end, l_next, l_stop: INTEGER
			l_line: STRING_32
		do
			if a_text.starts_with ({STRING_32} "# ") then
				l_start := 1
			else
				l_start := a_text.substring_index ({STRING_32} "%N# ", 1)
				if l_start > 0 then
					l_start := l_start + 1
				end
			end
			if l_start = 0 then
				Result := a_text
			else
				Result := a_text.substring (l_start, a_text.count)
				l_end := Result.index_of ('%N', 1)
				if l_end > 0 then
					from l_next := l_end + 1 until l_next > Result.count or else not (Result [l_next] = '%N' or Result [l_next] = '%R' or Result [l_next] = ' ') loop
						l_next := l_next + 1
					end
					l_stop := Result.index_of ('%N', l_next.min (Result.count))
					if l_stop = 0 then
						l_stop := Result.count + 1
					end
					if l_next <= Result.count then
						l_line := Result.substring (l_next, l_stop - 1)
						l_line.prune_all ('%R')
						l_line.right_adjust
						if l_line.has_substring ({STRING_32} "[[") and then l_line.count >= 2
							and then ((l_line [1] = '*' and l_line [l_line.count] = '*') or (l_line [1] = '_' and l_line [l_line.count] = '_'))
						then
							Result := Result.substring (1, l_end) + Result.substring (l_stop.min (Result.count + 1), Result.count)
						end
					end
				end
			end
		ensure
			not_longer: Result.count <= a_text.count
			at_the_title: a_text.has_substring ({STRING_32} "%N# ") or a_text.starts_with ({STRING_32} "# ") implies Result.starts_with ({STRING_32} "# ")
		end

feature {NONE} -- Implementation

	current_kind: STRING_8
	current_lines: ARRAYED_LIST [STRING_32]
			-- The block being gathered.

	reset_current
		do
			create current_kind.make_empty
			current_lines.wipe_out
		end

	flush
			-- The gathered lines as one block (when they say anything once cleaned).
		local
			l_text: STRING_32
		do
			if not current_kind.is_empty and not current_lines.is_empty then
				create l_text.make (200)
				across current_lines as ic loop
					if not l_text.is_empty then
						l_text.append_character ('%N')
					end
					l_text.append (ic)
				end
				add_block (current_kind, 0, l_text)
			end
			reset_current
		end

	add_block (a_kind: STRING_8; a_level: INTEGER; a_markdown: STRING_32)
			-- A block of `a_kind', cleaned; none when nothing is left, or when it is a typesetting
			-- placeholder, or a status line before the chapter's first heading.
		local
			l_text: STRING_32
		do
			if a_kind.same_string ("code") then
				l_text := a_markdown
			else
				l_text := cleaned (a_markdown)
			end
			l_text.left_adjust
			l_text.right_adjust
			if l_text.is_empty or else (a_kind.same_string ("item") and l_text.count <= 2) then
					-- nothing said
			elseif a_kind.same_string ("paragraph") and then is_placeholder (l_text) then
					-- "*[Copyright page - to be supplied at typesetting.]*"
			elseif a_kind.same_string ("paragraph") and then is_status_line (l_text)
				and then not across blocks as al_b some al_b.kind.same_string ("heading") end
			then
					-- "*Draft - first draft, ...*" above the chapter's heading
			else
				blocks.extend ([a_kind, a_level, l_text])
			end
		end

	heading_level (a_line: STRING_32): INTEGER
			-- 1 to 6 for "# x" to "###### x"; 0 for no heading.
		local
			i: INTEGER
		do
			from i := 1 until i > a_line.count or else a_line [i] /= '#' loop
				i := i + 1
			end
			if i >= 2 and i <= 7 and then i <= a_line.count and then a_line [i] = ' ' then
				Result := i - 1
			end
		ensure
			in_range: Result >= 0 and Result <= 6
		end

	heading_text (a_line: STRING_32): STRING_32
			-- The text of heading line `a_line', its marks and closing hashes gone.
		require
			a_heading: heading_level (a_line) > 0
		do
			Result := a_line.substring (heading_level (a_line) + 2, a_line.count)
			Result.right_adjust
			from until Result.is_empty or else Result [Result.count] /= '#' loop
				Result.remove_tail (1)
			end
			Result.right_adjust
		end

	is_rule (a_line: STRING_32): BOOLEAN
			-- "---", "***" or "___" (three or more, spaces allowed): a horizontal rule.
		local
			l_compact: STRING_32
		do
			l_compact := a_line.twin
			l_compact.prune_all (' ')
			Result := l_compact.count >= 3 and then (l_compact.occurrences ('-') = l_compact.count
				or l_compact.occurrences ('*') = l_compact.count or l_compact.occurrences ('_') = l_compact.count)
		end

	is_placeholder (a_text: STRING_32): BOOLEAN
			-- Is `a_text' one line wholly "*[...]*"?
		do
			Result := not a_text.has ('%N') and then a_text.starts_with ({STRING_32} "*[") and then a_text.ends_with ({STRING_32} "]*")
		end

	is_status_line (a_text: STRING_32): BOOLEAN
			-- Is `a_text' one italic line beginning "Draft"?
		do
			Result := not a_text.has ('%N') and then a_text.starts_with ({STRING_32} "*Draft") and then a_text.ends_with ({STRING_32} "*")
		end

	is_item (a_line: STRING_32): BOOLEAN
			-- "- x", "* x", "+ x", "1. x" or "1) x"?
		local
			i: INTEGER
		do
			if a_line.count >= 2 and then (a_line [1] = '-' or a_line [1] = '*' or a_line [1] = '+') and then a_line [2] = ' ' then
				Result := not (a_line.count >= 3 and then a_line.has_substring ({STRING_32} "---") and then a_line.occurrences ('-') = a_line.count)
			else
				from i := 1 until i > a_line.count or else not a_line [i].is_digit loop
					i := i + 1
				end
				Result := i > 1 and i < a_line.count and then (a_line [i] = '.' or a_line [i] = ')') and then a_line [i + 1] = ' '
			end
		end

	without_front_matter (a_text: STRING_32): STRING_32
			-- `a_text' without a YAML block at its very start.
		local
			l_end: INTEGER
		do
			Result := a_text
			if a_text.starts_with ({STRING_32} "---%N") or a_text.starts_with ({STRING_32} "---%R%N") then
				l_end := a_text.substring_index ({STRING_32} "%N---", 4)
				if l_end > 0 then
					l_end := a_text.index_of ('%N', l_end + 1)
					if l_end > 0 then
						Result := a_text.substring (l_end + 1, a_text.count)
					else
						create Result.make_empty
					end
				end
			end
		end

	without_comments (a_text: STRING_32): STRING_32
			-- `a_text' without HTML comments.
		local
			l_start, l_end: INTEGER
		do
			Result := a_text.twin
			from l_start := Result.substring_index ({STRING_32} "<!--", 1) until l_start = 0 loop
				l_end := Result.substring_index ({STRING_32} "-->", l_start + 4)
				if l_end = 0 then
					Result.keep_head (l_start - 1)
					l_start := 0
				else
					Result.remove_substring (l_start, l_end + 2)
					l_start := Result.substring_index ({STRING_32} "<!--", l_start)
				end
			end
		end

	cleaned (a_text: STRING_32): STRING_32
			-- `a_text' without embedded images, its wiki links read as their labels.
		local
			l_start, l_end, l_bar, l_hash: INTEGER
			l_inner, l_label: STRING_32
		do
			Result := a_text.twin
				-- ![[image.png]]
			from l_start := Result.substring_index ({STRING_32} "![[", 1) until l_start = 0 loop
				l_end := Result.substring_index ({STRING_32} "]]", l_start + 3)
				if l_end = 0 then
					l_start := 0
				else
					Result.remove_substring (l_start, l_end + 1)
					l_start := Result.substring_index ({STRING_32} "![[", l_start)
				end
			end
				-- ![alt](picture.png)
			from l_start := Result.substring_index ({STRING_32} "![", 1) until l_start = 0 loop
				l_end := Result.index_of (')', l_start)
				if l_end = 0 or else not Result.substring (l_start, l_end).has_substring ({STRING_32} "](") then
					l_start := 0
				else
					Result.remove_substring (l_start, l_end)
					l_start := Result.substring_index ({STRING_32} "![", l_start)
				end
			end
				-- footnotes: "[^3]: note" at a line's start reads "[3] note"; "[^3]" reads "[3]"
			from l_start := Result.substring_index ({STRING_32} "[^", 1) until l_start = 0 loop
				Result.remove (l_start + 1)
				l_start := Result.substring_index ({STRING_32} "[^", l_start)
			end
			from l_start := 1 until l_start = 0 loop
				l_start := footnote_definition_at (Result, l_start)
			end
				-- [[target#part|label]], [[target]]
			from l_start := Result.substring_index ({STRING_32} "[[", 1) until l_start = 0 loop
				l_end := Result.substring_index ({STRING_32} "]]", l_start + 2)
				if l_end = 0 then
					l_start := 0
				else
					l_inner := Result.substring (l_start + 2, l_end - 1)
					l_bar := l_inner.index_of ('|', 1)
					if l_bar > 0 then
						l_label := l_inner.substring (l_bar + 1, l_inner.count)
					else
						l_hash := l_inner.index_of ('#', 1)
						if l_hash > 1 then
							l_label := l_inner.substring (1, l_hash - 1)
						else
							l_label := l_inner
						end
					end
					Result.replace_substring (l_label, l_start, l_end + 1)
					l_start := Result.substring_index ({STRING_32} "[[", l_start + l_label.count)
				end
			end
		end

feature {NONE} -- Footnotes

	footnote_definition_at (a_text: STRING_32; a_from: INTEGER): INTEGER
			-- Turn the next "[n]:" at a line's start, from `a_from', into "[n]"; the index after it,
			-- or 0 when there is none.
		local
			i, j: INTEGER
		do
			from i := a_text.substring_index ({STRING_32} "]:", a_from.max (1)) until i = 0 or Result > 0 loop
				j := i - 1
				from until j < 1 or else not a_text [j].is_digit loop
					j := j - 1
				end
				if j >= 1 and then j < i - 1 and then a_text [j] = '[' and then (j = 1 or else a_text [j - 1] = '%N') then
					a_text.remove (i + 1)
					Result := i + 1
				else
					i := a_text.substring_index ({STRING_32} "]:", i + 2)
				end
			end
		end

invariant
	lists_attached: blocks /= Void and current_lines /= Void and skip_headings /= Void

end
