note
	description: "[
		File > Import prepared folder (2026-10-30, Larry): every *.prepared.md in a
		folder checked (BIB_NOTE_IMPORTER) and kept as a note, the notes pack built
		once at the end.

		NEVER TWICE: a file whose note is kept already, unchanged (its manifest and
		every chapter file as it would write them: BIB_NOTE_IMPORTER.is_already_kept),
		is passed over, so pointing at a folder again brings nothing in twice; a
		file changed since replaces its note. A refused file is named with its
		problems and the rest still come in; two files with one id are one too
		many. When a write or the one build fails, every note this run wrote is
		put back as it was.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_NOTE_BATCH

create
	make

feature {NONE} -- Initialization

	make (a_bible: SIMPLE_BIBLE)
			-- A folder importer checking against `a_bible''s books and names.
		require
			open: a_bible.is_open
		do
			bible := a_bible
			create kept.make (0)
			create replaced.make (0)
			create skipped.make (0)
			create refused.make (0)
		end

feature -- Access

	bible: SIMPLE_BIBLE

	kept: ARRAYED_LIST [TUPLE [file, title: STRING_32]]
			-- The files the last `run' kept as notes, with each note's title.

	replaced: ARRAYED_LIST [STRING_32]
			-- Those of `kept' whose note was kept before in another form, now replaced.

	skipped: ARRAYED_LIST [STRING_32]
			-- The files passed over: their notes are kept already, unchanged.

	refused: ARRAYED_LIST [TUPLE [file: STRING_32; problems: LIST [STRING_32]]]
			-- The files that failed a check, with why.

	last_error: detachable STRING_32
			-- Why the last `run' kept nothing (a write or the build failed; every note put back), or Void.

	built_blocks, built_suggestions: INTEGER
			-- What the last `run''s build wrote, across every note.

	file_count: INTEGER
			-- The prepared files the last `run' found.

	has_new_notes: BOOLEAN
			-- Did the last `run' build a notes pack with new or changed notes?
		do
			Result := last_error = Void and not kept.is_empty
		end

	prepared_files (a_folder: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- The names in `a_folder' ending ".prepared.md", in name order.
		local
			l_sorted: SORTED_TWO_WAY_LIST [STRING_32]
		do
			create l_sorted.make
			if (create {SIMPLE_FILE}.make (a_folder)).is_directory then
				across (create {SIMPLE_FILE}.make (a_folder)).files_with_extension (".md") as ic loop
					if ic.as_lower.ends_with (Prepared_extension) then
						l_sorted.extend (ic)
					end
				end
			end
			create Result.make_from_iterable (l_sorted)
		end

	Prepared_extension: STRING_32 = ".prepared.md"

feature -- Importing

	run (a_folder, a_notes_folder, a_pack, a_frameworks_pack: READABLE_STRING_GENERAL)
			-- Every prepared file in `a_folder' checked; the new and changed kept in `a_notes_folder' and
			-- the notes pack `a_pack' built once from every note there (frameworks pack
			-- `a_frameworks_pack' linked when it exists). `kept', `replaced', `skipped', `refused' and
			-- `last_error' say how it went.
		require
			pack_named: not a_pack.is_empty
		local
			l_written: ARRAYED_LIST [BIB_NOTE_IMPORTER]
			l_importer: BIB_NOTE_IMPORTER
			l_ids: HASH_TABLE [STRING_32, STRING_32]
			l_files: ARRAYED_LIST [STRING_32]
			l_folder, l_name, l_text: STRING_32
			l_source: SIMPLE_FILE
			l_was_kept, l_failed: BOOLEAN
			i: INTEGER
		do
			if l_failed then
				last_error := {STRING_32} "Importing the folder failed unexpectedly; every note is as it was."
				if attached l_written as al_written then
					across al_written as ic loop
						ic.put_back (a_notes_folder)
					end
				end
				kept.wipe_out
				replaced.wipe_out
			else
				kept.wipe_out
				replaced.wipe_out
				skipped.wipe_out
				refused.wipe_out
				last_error := Void
				built_blocks := 0
				built_suggestions := 0
				create l_written.make (0)
				create l_ids.make (0)
				create l_folder.make_from_string_general (a_folder)
				l_files := prepared_files (l_folder)
				file_count := l_files.count
				from i := 1 until i > l_files.count or last_error /= Void loop
					l_name := l_files.i_th (i)
					l_text := (create {SIMPLE_FILE}.make (l_folder + {STRING_32} "\" + l_name)).read_text_utf_8
					create l_importer.make (bible)
					l_importer.read (l_text, Void)
					if l_importer.is_accepted and then not l_importer.source.is_empty then
							-- its source beside it, when there, for the length check (as File > Import does)
						create l_source.make (l_folder + {STRING_32} "\" + l_importer.source)
						if l_source.is_file then
							l_importer.read (l_text, l_source.read_text_utf_8)
						end
					end
					if not l_importer.is_accepted then
						refused.extend ([l_name, l_importer.problems])
					elseif attached l_ids.item (l_importer.id) as al_first then
						refused.extend ([l_name, create {ARRAYED_LIST [STRING_32]}.make_from_array (<<{STRING_32} "its id " + l_importer.id + {STRING_32} " is the id of " + al_first + {STRING_32} " too">>)])
					else
						l_ids.put (l_name, l_importer.id)
						if l_importer.is_already_kept (a_notes_folder) then
							skipped.extend (l_name)
						else
							l_was_kept := (create {SIMPLE_FILE}.make (l_importer.manifest_path (a_notes_folder))).is_file
							l_importer.set_aside (a_notes_folder)
							l_written.extend (l_importer)
							if l_importer.write_files (a_notes_folder) then
								kept.extend ([l_name, l_importer.title])
								if l_was_kept then
									replaced.extend (l_name)
								end
							else
								last_error := {STRING_32} "The files of " + l_name + {STRING_32} " could not be written in " + a_notes_folder.to_string_32
							end
						end
					end
					i := i + 1
				end
				if last_error = Void and not l_written.is_empty then
					last_error := l_written.first.build (a_notes_folder, a_pack, a_frameworks_pack)
					built_blocks := l_written.first.built_blocks
					built_suggestions := l_written.first.built_suggestions
				end
				if attached last_error then
					across l_written as ic loop
						ic.put_back (a_notes_folder)
					end
					kept.wipe_out
					replaced.wipe_out
				else
					across l_written as ic loop
						ic.drop_set_aside (a_notes_folder)
					end
				end
			end
		ensure
			nothing_kept_on_failure: last_error /= Void implies kept.is_empty
			every_file_accounted: last_error = Void implies kept.count + skipped.count + refused.count = file_count
		rescue
			if not l_failed then
				l_failed := True
				retry
			end
		end

end
