note
	description: "[
		File > Import prepared folder (2026-10-30, Larry): every *.prepared.md in a
		folder checked (BIB_NOTE_IMPORTER) and kept, each pack built once at the
		end. File > Import prepared notes runs one file through it too
		(`run_files'), so one import and a folder's keep alike.

		TWO KINDS (2026-10-30, the Scholar Guides): a note goes to the notes folder
		and pack, a scholar guide ("kind: guide") to the guides folder and pack
		(BIB_INGEST_PLACES). A guide whose id was a note's (the Unseen Realm
		chapters, imported as notes before guides existed) retires that note, so
		nothing is listed twice; when the last note retires, the notes pack is to
		go (`notes_now_empty').

		NEVER TWICE: a file kept already, unchanged (its manifest and every chapter
		file as it would write them: BIB_NOTE_IMPORTER.is_already_kept), is passed
		over, so pointing at a folder again brings nothing in twice; a file
		changed since replaces its earlier form. A refused file is named with its
		problems and the rest still come in; two files with one id are one too
		many. When a write or a build fails, every file this run wrote is put back
		and every retired note restored.

		A PACK NOT PUT IN PLACE (scan 70): the files are kept before the window
		swaps the built pack in; when that swap fails the window marks the folder
		(`set_pack_stale'), and the next run builds that pack from every file even
		when none is new, clearing the way.
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
			-- An importer checking against `a_bible''s books and names.
		require
			open: a_bible.is_open
		do
			bible := a_bible
			create kept.make (0)
			create replaced.make (0)
			create skipped.make (0)
			create refused.make (0)
			create warnings.make (0)
			create retired.make (0)
		end

feature -- Access

	bible: SIMPLE_BIBLE

	kept: ARRAYED_LIST [TUPLE [file, title, id, kind: STRING_32]]
			-- The files the last run kept, with each one's title, id and pack kind ("notes", "guides").

	replaced: ARRAYED_LIST [STRING_32]
			-- Those of `kept' kept before in another form, now replaced.

	skipped: ARRAYED_LIST [STRING_32]
			-- The files passed over: kept already, unchanged.

	refused: ARRAYED_LIST [TUPLE [file: STRING_32; problems: LIST [STRING_32]]]
			-- The files that failed a check, with why.

	warnings: ARRAYED_LIST [STRING_32]
			-- What the run let pass but should be looked at, each "file: warning".

	retired: ARRAYED_LIST [STRING_32]
			-- The notes retired because a guide took their id.

	last_error: detachable STRING_32
			-- Why the last run kept nothing (a write, a retirement or a build failed; all put back), or Void.

	notes_built, guides_built: BOOLEAN
			-- Did the last run build that pack, to be put in place?

	notes_now_empty: BOOLEAN
			-- Did the last run retire the last note, so the notes pack is to go?

	built_blocks, built_suggestions: INTEGER
			-- What the last run's builds wrote, across both packs.

	file_count: INTEGER
			-- The files the last run was given.

	has_new_notes: BOOLEAN
			-- Did the last run keep new or changed files?
		do
			Result := last_error = Void and not kept.is_empty
		end

	is_built: BOOLEAN
			-- Did the last run leave a pack to put in place or to take away?
		do
			Result := notes_built or guides_built or notes_now_empty
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

	is_pack_stale (a_folder: READABLE_STRING_GENERAL): BOOLEAN
			-- Was a pack built from `a_folder' never put in place?
		do
			Result := (create {SIMPLE_FILE}.make (a_folder.to_string_32 + {STRING_32} "\" + Stale_marker)).is_file
		end

	set_pack_stale (a_folder: READABLE_STRING_GENERAL; a_stale: BOOLEAN)
			-- Mark `a_folder''s files as not yet in their live pack (`a_stale'), or clear the mark.
		local
			l_ok: BOOLEAN
		do
			if a_stale and (create {SIMPLE_FILE}.make (a_folder)).is_directory then
				l_ok := (create {SIMPLE_FILE}.make (a_folder.to_string_32 + {STRING_32} "\" + Stale_marker)).write_text_utf_8 ("The pack built from these files was not put in place; the next import builds it again.%N")
			elseif not a_stale and is_pack_stale (a_folder) then
				l_ok := (create {SIMPLE_FILE}.make (a_folder.to_string_32 + {STRING_32} "\" + Stale_marker)).delete
			end
		end

	Stale_marker: STRING_32 = "notes-pack-stale.txt"

feature -- Importing

	run (a_folder: READABLE_STRING_GENERAL; a_places: BIB_INGEST_PLACES)
			-- Every prepared file in `a_folder' (`run_files').
		do
			run_files (a_folder, prepared_files (a_folder), a_places)
		end

	run_files (a_folder: READABLE_STRING_GENERAL; a_files: LIST [STRING_32]; a_places: BIB_INGEST_PLACES)
			-- The files `a_files' of `a_folder' checked; the new and changed kept in `a_places', notes and
			-- guides apart; notes a guide took the id of retired; each pack built once from every file
			-- in its folder (frameworks linked). `kept', `replaced', `skipped', `refused', `retired' and
			-- `last_error' say how it went.
		local
			l_written: ARRAYED_LIST [BIB_NOTE_IMPORTER]
			l_guides: ARRAYED_LIST [STRING_32]
			l_importer: BIB_NOTE_IMPORTER
			l_ids: HASH_TABLE [STRING_32, STRING_32]
			l_folder, l_name, l_text: STRING_32
			l_source: SIMPLE_FILE
			l_was_kept, l_failed, l_any_note, l_any_guide: BOOLEAN
			i: INTEGER
		do
			if l_failed then
				last_error := {STRING_32} "Importing failed unexpectedly; everything is as it was."
				if attached l_written as al_written then
					across al_written as ic loop
						ic.put_back (ic.folder_for (a_places.notes_folder, a_places.guides_folder))
					end
				end
				restore_retired (a_places.notes_folder)
				kept.wipe_out
				replaced.wipe_out
			else
				kept.wipe_out
				replaced.wipe_out
				skipped.wipe_out
				refused.wipe_out
				warnings.wipe_out
				retired.wipe_out
				last_error := Void
				notes_built := False
				guides_built := False
				notes_now_empty := False
				built_blocks := 0
				built_suggestions := 0
				create l_written.make (0)
				create l_guides.make (0)
				create l_ids.make (0)
				create l_folder.make_from_string_general (a_folder)
				file_count := a_files.count
				from i := 1 until i > a_files.count or last_error /= Void loop
					l_name := a_files.i_th (i)
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
						across l_importer.warnings as ic loop
							warnings.extend (l_name + {STRING_32} ": " + ic)
						end
						if l_importer.is_guide then
							l_guides.extend (l_importer.id)
						end
						if l_importer.is_already_kept (l_importer.folder_for (a_places.notes_folder, a_places.guides_folder)) then
							skipped.extend (l_name)
						else
							l_was_kept := (create {SIMPLE_FILE}.make (l_importer.manifest_path (l_importer.folder_for (a_places.notes_folder, a_places.guides_folder)))).is_file
							if not l_importer.set_aside (l_importer.folder_for (a_places.notes_folder, a_places.guides_folder)) then
									-- scan 70: it undid itself; joining `l_written' only after, so a rollback
									-- never deletes an earlier file left in place
								last_error := l_name + {STRING_32} ": " + l_importer.set_aside_refusal (l_importer.folder_for (a_places.notes_folder, a_places.guides_folder))
							else
								l_written.extend (l_importer)
								if l_importer.write_files (l_importer.folder_for (a_places.notes_folder, a_places.guides_folder)) then
									kept.extend ([l_name, l_importer.title, l_importer.id, l_importer.schema.Pack_kind.to_string_32])
									if l_was_kept then
										replaced.extend (l_name)
									end
									if l_importer.is_guide then
										l_any_guide := True
									else
										l_any_note := True
									end
								else
									last_error := {STRING_32} "The files of " + l_name + {STRING_32} " could not be written in " + l_importer.folder_for (a_places.notes_folder, a_places.guides_folder).to_string_32
								end
							end
						end
					end
					i := i + 1
				end
				if last_error = Void then
						-- a guide takes a note's id: the note retires
					across l_guides as ic until last_error /= Void loop
						if (create {SIMPLE_FILE}.make (a_places.notes_folder + {STRING_32} "\" + ic + Note_schema.Manifest_extension)).is_file then
							if retire_note (a_places.notes_folder, ic) then
								retired.extend (ic)
							else
								last_error := {STRING_32} "The note " + ic + {STRING_32} " could not be retired for its guide; nothing was changed."
							end
						end
					end
				end
				if last_error = Void and (l_any_guide or (is_pack_stale (a_places.guides_folder) and has_files (a_places.guides_folder))) then
					last_error := build_pack (Guide_schema, a_places.guides_folder, a_places.guides_pack, a_places.frameworks_pack)
					guides_built := last_error = Void
				end
				if last_error = Void and (l_any_note or not retired.is_empty or is_pack_stale (a_places.notes_folder)) then
					if has_files (a_places.notes_folder) then
						last_error := build_pack (Note_schema, a_places.notes_folder, a_places.notes_pack, a_places.frameworks_pack)
						notes_built := last_error = Void
					else
						notes_now_empty := True
					end
				end
				if attached last_error then
					across l_written as ic loop
						ic.put_back (ic.folder_for (a_places.notes_folder, a_places.guides_folder))
					end
					restore_retired (a_places.notes_folder)
					kept.wipe_out
					replaced.wipe_out
					retired.wipe_out
					notes_built := False
					guides_built := False
					notes_now_empty := False
				else
					across l_written as ic loop
						ic.drop_set_aside (ic.folder_for (a_places.notes_folder, a_places.guides_folder))
					end
					drop_retired (a_places.notes_folder)
				end
			end
		ensure
			nothing_kept_on_failure: last_error /= Void implies (kept.is_empty and not is_built)
			every_file_accounted: last_error = Void implies kept.count + skipped.count + refused.count = file_count
			new_files_built: has_new_notes implies is_built
		rescue
			if not l_failed then
				l_failed := True
				retry
			end
		end

feature {NONE} -- Building

	build_pack (a_schema: BIB_TEXT_PACK_SCHEMA; a_folder, a_pack, a_frameworks_pack: STRING_32): detachable STRING_32
			-- The `a_schema' pack `a_pack' built from every file in `a_folder'; Void when built, else why not.
		local
			l_importer: BIB_NOTE_IMPORTER
		do
			create l_importer.make (bible)
			Result := l_importer.build_with (a_schema, a_folder, a_pack, a_frameworks_pack)
			built_blocks := built_blocks + l_importer.built_blocks
			built_suggestions := built_suggestions + l_importer.built_suggestions
		end

	has_files (a_folder: STRING_32): BOOLEAN
			-- Does `a_folder' hold a manifest to build from?
		do
			Result := (create {SIMPLE_FILE}.make (a_folder)).is_directory and then not (create {SIMPLE_FILE}.make (a_folder)).files_with_extension (".json").is_empty
		end

	Note_schema: BIB_NOTE_SCHEMA
		once
			create Result
		end

	Guide_schema: BIB_GUIDE_SCHEMA
		once
			create Result
		end

feature {NONE} -- Retiring a note

	retire_note (a_notes_folder, a_id: STRING_32): BOOLEAN
			-- The note `a_id''s manifest and chapter files renamed with ".retired", out of the builder's
			-- sight; False, every rename undone, when one fails.
		local
			l_dir: STRING_32
		do
			Result := True
			l_dir := a_notes_folder + {STRING_32} "\" + a_id
			retiring := a_id
			if (create {SIMPLE_FILE}.make (l_dir)).is_directory then
				across (create {SIMPLE_FILE}.make (l_dir)).files_with_extension (".md") as ic until not Result loop
					Result := (create {SIMPLE_FILE}.make (l_dir + {STRING_32} "\" + ic)).rename_to (ic + Retired_suffix)
				end
			end
			if Result then
				Result := (create {SIMPLE_FILE}.make (a_notes_folder + {STRING_32} "\" + a_id + Note_schema.Manifest_extension)).rename_to (a_id + Note_schema.Manifest_extension + Retired_suffix)
			end
			if not Result then
				restore_note (a_notes_folder, a_id)
			end
			retiring := Void
		end

	retiring: detachable STRING_32
			-- The note being retired, for the rescue.

	restore_retired (a_notes_folder: STRING_32)
			-- Every note `retired' (and one caught retiring) given its names back.
		do
			across retired as ic loop
				restore_note (a_notes_folder, ic)
			end
			if attached retiring as al_id then
				restore_note (a_notes_folder, al_id)
			end
		end

	restore_note (a_notes_folder, a_id: STRING_32)
			-- The note `a_id''s retired files given their names back.
		local
			l_dir: STRING_32
			l_ok: BOOLEAN
		do
			l_dir := a_notes_folder + {STRING_32} "\" + a_id
			if (create {SIMPLE_FILE}.make (l_dir)).is_directory then
				across (create {SIMPLE_FILE}.make (l_dir)).files_with_extension ({STRING_32} ".md" + Retired_suffix) as ic loop
					l_ok := (create {SIMPLE_FILE}.make (l_dir + {STRING_32} "\" + ic)).rename_to (ic.substring (1, ic.count - Retired_suffix.count))
				end
			end
			if (create {SIMPLE_FILE}.make (a_notes_folder + {STRING_32} "\" + a_id + Note_schema.Manifest_extension + Retired_suffix)).is_file then
				l_ok := (create {SIMPLE_FILE}.make (a_notes_folder + {STRING_32} "\" + a_id + Note_schema.Manifest_extension + Retired_suffix)).rename_to (a_id + Note_schema.Manifest_extension)
			end
		end

	drop_retired (a_notes_folder: STRING_32)
			-- Every `retired' note's files gone, its folder too.
		local
			l_dir: STRING_32
			l_ok: BOOLEAN
		do
			across retired as ic_id loop
				l_dir := a_notes_folder + {STRING_32} "\" + ic_id
				if (create {SIMPLE_FILE}.make (l_dir)).is_directory then
					across (create {SIMPLE_FILE}.make (l_dir)).files_with_extension ({STRING_32} ".md" + Retired_suffix) as ic loop
						l_ok := (create {SIMPLE_FILE}.make (l_dir + {STRING_32} "\" + ic)).delete
					end
					if (create {SIMPLE_FILE}.make (l_dir)).files.is_empty then
						l_ok := (create {SIMPLE_FILE}.make (l_dir)).delete_directory
					end
				end
				l_ok := (create {SIMPLE_FILE}.make (a_notes_folder + {STRING_32} "\" + ic_id + Note_schema.Manifest_extension + Retired_suffix)).delete
			end
		end

	Retired_suffix: STRING_32 = ".retired"

end
