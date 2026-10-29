note
	description: "[
		Reads back a prepared file (0.7.32, research/21-INGEST-KIT.md: the format
		BIB_INGEST_KIT asks for) and, when it passes every check, keeps it as a note:
		its chapters as files in the reader's notes folder with a manifest, and the
		notes pack rebuilt from every manifest there (BIB_BOOK_BUILDER with
		BIB_NOTE_SCHEMA), so a rebuild never needs the AI again.

		THE CHECKS (any one failing refuses the file, each named by its line):
		 - a header between "---" lines with sbn 1, an id of lowercase letters
		   and digits, a title, a known status (none: draft);
		 - every [label](target) link points at a web page, a Bible passage that
		   exists, this note itself, or a target the kit listed (BIB_NAME_LIST);
		 - every {{suggest: <reference> | <reason>}} stands on a line of its own,
		   names a reference that reads to a book the content holds, and gives a
		   reason.
		 A warning (the file still passes): a prepared text much shorter than its
		 source (a summary passed off as the notes); a note that replaces an
		 earlier one with the same id.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_NOTE_IMPORTER

create
	make

feature {NONE} -- Initialization

	make (a_bible: SIMPLE_BIBLE)
			-- An importer checking against `a_bible''s books and names.
		require
			open: a_bible.is_open
		do
			bible := a_bible
			create problems.make (0)
			create warnings.make (0)
			create chapters.make (0)
			create id.make_empty
			create title.make_empty
			create author.make_empty
			create date.make_empty
			create source.make_empty
			create status.make_empty
		end

feature -- Access

	bible: SIMPLE_BIBLE

	problems: ARRAYED_LIST [STRING_32]
			-- Why the last `read' refused the file, line by line.

	warnings: ARRAYED_LIST [STRING_32]
			-- What the last `read' let pass but should be looked at.

	id, title, author, date, source, status: STRING_32
			-- The header's fields.

	chapters: ARRAYED_LIST [TUPLE [title, text: STRING_32]]
			-- The note's chapters, each its "# " title line and its text.

	is_accepted: BOOLEAN
			-- Did the last `read' pass every check?
		do
			Result := has_read and problems.is_empty and not chapters.is_empty
		end

	suggestion_count: INTEGER
			-- The suggestions the last `read' found.

	Short_ratio: REAL_64 = 0.5
			-- A prepared text under this share of its source's length is warned about.

	schema: BIB_NOTE_SCHEMA
			-- The notes pack's.
		once
			create Result
		end

feature -- Reading

	read (a_prepared: READABLE_STRING_GENERAL; a_source_text: detachable READABLE_STRING_GENERAL)
			-- Check the prepared file `a_prepared' (its source's text `a_source_text' when known):
			-- `is_accepted', or `problems' saying why not.
		local
			l_lines: LIST [STRING_32]
			l_text: STRING_32
			l_body_start: INTEGER
		do
			has_read := True
			create problems.make (0)
			create warnings.make (0)
			create chapters.make (0)
			suggestion_count := 0
			l_text := a_prepared.to_string_32
			l_text.replace_substring_all ({STRING_32} "%R%N", {STRING_32} "%N")
			if not l_text.is_empty and then l_text [1].code = 65279 then
				l_text.remove_head (1)
			end
			l_text := unwrapped (l_text)
			l_lines := l_text.split ('%N')
			l_body_start := read_header (l_lines)
			if problems.is_empty then
				check_body (l_lines, l_body_start)
			end
			if problems.is_empty then
				split_chapters (l_lines, l_body_start)
				if attached a_source_text as al_source and then al_source.count > 0 then
					if body_length < (al_source.count * Short_ratio).truncated_to_integer then
						warnings.extend ({STRING_32} "The prepared text is " + body_length.out.to_string_32 + {STRING_32} " characters against the source's "
							+ al_source.count.out.to_string_32 + {STRING_32} ": it may be a summary, not the notes.")
					end
				end
				across bible.text_packs as ic loop
					if ic.schema.Pack_kind.same_string (schema.Pack_kind) and then ic.is_available and then attached ic.book (id) as al_old
						and then al_old.is_success and then al_old.count = 1
					then
						warnings.extend ({STRING_32} "It replaces the earlier note " + id + {STRING_32} ".")
					end
				end
			end
		ensure
			accepted_has_chapters: is_accepted implies not chapters.is_empty
		end

feature -- Keeping

	write_files (a_notes_folder: READABLE_STRING_GENERAL): BOOLEAN
			-- The accepted note's chapters as files in `a_notes_folder'\<id>\ (an earlier note's files
			-- with the same id replaced) and its manifest `a_notes_folder'\<id>.note.json. Did every
			-- file write?
		require
			accepted: is_accepted
		local
			l_folder: SIMPLE_FILE
			l_dir: STRING_32
			l_object: SIMPLE_JSON_OBJECT
			l_list: SIMPLE_JSON_ARRAY
			l_file: STRING_32
			i: INTEGER
		do
			Result := True
			create l_folder.make (a_notes_folder)
			if not l_folder.is_directory then
				Result := l_folder.create_directory_recursive
			end
			l_dir := a_notes_folder.to_string_32 + {STRING_32} "\" + id
			create l_folder.make (l_dir)
			if l_folder.is_directory then
				across l_folder.files_with_extension (".md") as ic loop
					Result := (create {SIMPLE_FILE}.make (l_dir + {STRING_32} "\" + ic)).delete and Result
				end
			elseif Result then
				Result := l_folder.create_directory
			end
			create l_list.make
			from i := 1 until i > chapters.count or not Result loop
				l_file := (if i < 10 then {STRING_32} "0" else {STRING_32} "" end) + i.out.to_string_32 + {STRING_32} ".md"
				Result := (create {SIMPLE_FILE}.make (l_dir + {STRING_32} "\" + l_file)).write_text_utf_8 (chapters.i_th (i).text)
				l_list := l_list.add_object ((create {SIMPLE_JSON_OBJECT}.make).put_string (chapters.i_th (i).title, "title")
					.put_string (l_file, "file").put_string ("chapter", "kind"))
				i := i + 1
			end
			if Result then
				create l_object.make
				l_object := l_object.put_string (id, "id").put_string (title, "title").put_string ("", "subtitle").put_string (author, "author")
					.put_string (status, "status").put_string ("", "edition").put_integer (year_of (date), "year")
					.put_string (description, "description").put_string (id, "root").put_string (source, "source")
					.put_array (create {SIMPLE_JSON_ARRAY}.make, "aliases").put_array (create {SIMPLE_JSON_ARRAY}.make, "skip_headings")
					.put_array (l_list, "chapters")
				Result := (create {SIMPLE_FILE}.make (a_notes_folder.to_string_32 + {STRING_32} "\" + id + schema.Manifest_extension)).write_text_utf_8 (l_object.to_pretty_json)
			end
		end

	build (a_notes_folder, a_pack, a_frameworks_pack: READABLE_STRING_GENERAL): detachable STRING_32
			-- The notes pack `a_pack' built afresh from every manifest in `a_notes_folder' (names of
			-- the frameworks pack `a_frameworks_pack' linked, when it exists); Void when it built, else
			-- why not.
		require
			pack_named: not a_pack.is_empty
		local
			l_builder: BIB_BOOK_BUILDER
			l_frameworks: STRING_32
		do
			create l_builder.make_with_schema (bible.books, schema)
			if l_builder.sidecars_in (a_notes_folder).is_empty then
				Result := {STRING_32} "No notes to build."
			else
				l_frameworks := a_frameworks_pack.to_string_32
				if not l_frameworks.is_empty and then not (create {SIMPLE_FILE}.make (l_frameworks)).is_file then
					create l_frameworks.make_empty
				end
				l_builder.build (l_builder.sidecars_in (a_notes_folder), a_pack, l_frameworks)
				Result := l_builder.last_error
				built_blocks := l_builder.block_count
				built_suggestions := l_builder.suggestion_count
			end
		end

	built_blocks, built_suggestions: INTEGER
			-- What the last `build' wrote.

feature {NONE} -- The header

	read_header (a_lines: LIST [STRING_32]): INTEGER
			-- The header's fields from `a_lines'; the index of the body's first line.
		local
			i, l_colon: INTEGER
			l_line, l_key, l_value: STRING_32
			l_closed: BOOLEAN
		do
			create id.make_empty
			create title.make_empty
			create author.make_empty
			create date.make_empty
			create source.make_empty
			create status.make_empty
			i := 1
			from until i > a_lines.count or else not trimmed (a_lines.i_th (i)).is_empty loop
				i := i + 1
			end
			if i > a_lines.count or else not trimmed (a_lines.i_th (i)).same_string ({STRING_32} "---") then
				problem (i.min (a_lines.count).max (1), "the file must begin with a header between two lines of three hyphens")
				Result := 1
			else
				from i := i + 1 until i > a_lines.count or l_closed loop
					l_line := trimmed (a_lines.i_th (i))
					if l_line.same_string ({STRING_32} "---") then
						l_closed := True
					elseif not l_line.is_empty then
						l_colon := l_line.index_of (':', 1)
						if l_colon > 1 then
							l_key := trimmed (l_line.substring (1, l_colon - 1)).as_lower
							l_value := trimmed (l_line.substring (l_colon + 1, l_line.count))
							if l_key.same_string ({STRING_32} "sbn") then
								if not l_value.same_string (Format_version) then
									problem (i, {STRING_32} "sbn must be " + Format_version)
								end
							elseif l_key.same_string ({STRING_32} "id") then
								id := l_value
							elseif l_key.same_string ({STRING_32} "title") then
								title := l_value
							elseif l_key.same_string ({STRING_32} "author") then
								author := l_value
							elseif l_key.same_string ({STRING_32} "date") then
								date := l_value
							elseif l_key.same_string ({STRING_32} "source") then
								source := l_value
							elseif l_key.same_string ({STRING_32} "status") then
								status := l_value.as_lower
							end
						end
					end
					i := i + 1
				end
				Result := i
				if not l_closed then
					problem (a_lines.count, "the header is never closed by a line of three hyphens")
				elseif not schema.is_book_id (id) then
					problem (1, {STRING_32} "the id %"" + id + {STRING_32} "%" must be lowercase letters and digits only")
				elseif title.is_empty then
					problem (1, "the header has no title")
				end
				if status.is_empty then
					status := {STRING_32} "draft"
				elseif not schema.is_one_of (status, schema.Statuses) then
					problem (1, {STRING_32} "the status %"" + status + {STRING_32} "%" is not draft, manuscript or published")
				end
			end
		end

	Format_version: STRING_32 = "1"

feature {NONE} -- The body

	check_body (a_lines: LIST [STRING_32]; a_start: INTEGER)
			-- Every link and suggestion from line `a_start' on, outside code fences.
		local
			l_links: HASH_TABLE [BOOLEAN, STRING_32]
			l_line, l_trim: STRING_32
			l_in_fence: BOOLEAN
			i: INTEGER
		do
			l_links := (create {BIB_NAME_LIST}.make (bible)).links ((create {BIB_NAME_LIST}.make (bible)).names (""))
			from i := a_start until i > a_lines.count loop
				l_line := a_lines.i_th (i)
				l_trim := trimmed (l_line)
				if l_trim.starts_with ({STRING_32} "```") or l_trim.starts_with ({STRING_32} "~~~") then
					l_in_fence := not l_in_fence
				elseif not l_in_fence then
					check_links (i, l_line, l_links)
					if suggestions.mentions (l_line) then
						check_suggestion (i, l_trim)
					end
				end
				i := i + 1
			end
		end

	check_links (a_number: INTEGER; a_line: STRING_32; a_links: HASH_TABLE [BOOLEAN, STRING_32])
			-- Each "](target)" of line `a_number' points somewhere allowed.
		local
			i, j: INTEGER
			l_target: STRING_32
		do
			from i := a_line.substring_index ({STRING_32} "](", 1) until i = 0 loop
				j := a_line.index_of (')', i + 2)
				if j > i + 2 then
					l_target := a_line.substring (i + 2, j - 1)
					if not is_allowed_target (l_target, a_links) then
						problem (a_number, {STRING_32} "the link target %"" + l_target + {STRING_32} "%" is not in Simple Bible")
					end
					i := a_line.substring_index ({STRING_32} "](", j)
				else
					i := 0
				end
			end
		end

	is_allowed_target (a_target: STRING_32; a_links: HASH_TABLE [BOOLEAN, STRING_32]): BOOLEAN
			-- A web page, a Bible passage that exists, this note, or a listed target?
		local
			l_link: BIB_LINK_TARGET
		do
			if a_target.starts_with ({STRING_32} "http://") or a_target.starts_with ({STRING_32} "https://") or a_target.starts_with ({STRING_32} "mailto:") then
				Result := True
			elseif a_links.has (a_target) then
				Result := True
			else
				create l_link.make (a_target, bible.books)
				Result := l_link.is_bible
					or else (l_link.is_book and then l_link.book_kind.same_string (schema.Pack_kind) and then l_link.id.same_string (id))
			end
		end

	check_suggestion (a_number: INTEGER; a_line: STRING_32)
			-- A suggestion stands alone on its line, names a reference that reads, gives a reason.
		do
			if attached suggestions.parsed (a_line) as al_suggestion then
				if place_of (al_suggestion.passage) = Void then
					problem (a_number, {STRING_32} "the suggested reference %"" + al_suggestion.passage + {STRING_32} "%" does not read")
				elseif al_suggestion.reason.is_empty then
					problem (a_number, "a suggestion needs its reason after a %"|%"")
				else
					suggestion_count := suggestion_count + 1
				end
			else
				problem (a_number, "a suggestion must stand on a line of its own: {{suggest: Romans 8:28 | why}}")
			end
		end

	split_chapters (a_lines: LIST [STRING_32]; a_start: INTEGER)
			-- `chapters': each "# " title line and the lines under it; text before the first title, or
			-- a body with none, goes under the note's title.
		local
			l_title, l_text: STRING_32
			l_in_fence: BOOLEAN
			l_trim: STRING_32
			i: INTEGER
		do
			create l_title.make_empty
			create l_text.make (2000)
			from i := a_start until i > a_lines.count loop
				l_trim := trimmed (a_lines.i_th (i))
				if l_trim.starts_with ({STRING_32} "```") or l_trim.starts_with ({STRING_32} "~~~") then
					l_in_fence := not l_in_fence
				end
				if not l_in_fence and then a_lines.i_th (i).starts_with ({STRING_32} "# ") then
					keep_chapter (l_title, l_text)
					l_title := trimmed (a_lines.i_th (i).substring (3, a_lines.i_th (i).count))
					create l_text.make (2000)
				end
				l_text.append (a_lines.i_th (i))
				l_text.append_character ('%N')
				i := i + 1
			end
			keep_chapter (l_title, l_text)
		end

	keep_chapter (a_title, a_text: STRING_32)
			-- One chapter, unless it holds nothing; untitled text titled by the note.
		local
			l_text: STRING_32
		do
			if not trimmed (a_text).is_empty then
				if a_title.is_empty then
					l_text := {STRING_32} "# " + title + {STRING_32} "%N%N" + a_text
					chapters.extend ([title.twin, l_text])
				else
					chapters.extend ([a_title.twin, a_text.twin])
				end
			end
		end

	body_length: INTEGER
			-- The chapters' characters.
		do
			across chapters as ic loop
				Result := Result + ic.text.count
			end
		end

feature {NONE} -- Implementation

	has_read: BOOLEAN

	suggestions: BIB_SUGGESTION_LINE
			-- Reads a suggestion's line (the builder reads it by the same rule).
		once
			create Result
		end

	place_of (a_reference: STRING_32): detachable TUPLE [book, chapter, verse: INTEGER]
			-- The place `a_reference' names, its book held.
		do
			if attached (create {BIB_REFERENCE_LINKER}.make_forgiving (bible.books)).place_in (a_reference) as al_place
				and then bible.books.has_book (al_place.book)
			then
				Result := al_place
			end
		end

	unwrapped (a_text: STRING_32): STRING_32
			-- `a_text' without a code fence an AI may have put around the whole file.
		local
			l_trim: STRING_32
			l_first_end, l_last_start: INTEGER
		do
			Result := a_text
			l_trim := trimmed (a_text)
			if (l_trim.starts_with ({STRING_32} "```") or l_trim.starts_with ({STRING_32} "~~~")) and then (l_trim.ends_with ({STRING_32} "```") or l_trim.ends_with ({STRING_32} "~~~")) then
				l_first_end := l_trim.index_of ('%N', 1)
				l_last_start := l_trim.last_index_of ('%N', l_trim.count)
				if l_first_end > 0 and l_last_start > l_first_end then
					Result := l_trim.substring (l_first_end + 1, l_last_start - 1)
				end
			end
		end

	description: STRING_32
			-- What the library shows for the note.
		do
			Result := {STRING_32} "Brought in from " + (if source.is_empty then {STRING_32} "a prepared file" else source end)
			if not date.is_empty then
				Result.append ({STRING_32} ", " + date)
			end
			Result.append_character ('.')
		end

	year_of (a_date: STRING_32): INTEGER
			-- The year a date begins with; 0 when none.
		do
			if a_date.count >= 4 and then a_date.substring (1, 4).is_integer then
				Result := a_date.substring (1, 4).to_integer
			end
		end

	trimmed (a_text: STRING_32): STRING_32
		do
			Result := a_text.twin
			Result.left_adjust
			Result.right_adjust
		end

	problem (a_line: INTEGER; a_why: READABLE_STRING_GENERAL)
			-- Line `a_line' fails: `a_why'.
		do
			problems.extend ({STRING_32} "line " + a_line.out.to_string_32 + {STRING_32} ": " + a_why.to_string_32)
		ensure
			one_more: problems.count = old problems.count + 1
		end

end
