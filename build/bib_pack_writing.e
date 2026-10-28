note
	description: "[
		A private pack's writer (design scan 58): what BIB_COMMENTARY_BUILDER and
		BIB_FRAMEWORK_BUILDER had line for line - the failure kept in
		`last_error', a fresh pack file made from the schema's statements in one
		transaction and committed or rolled back at the end, `meta' rows, SQLite's
		words on a failure, and a sidecar's strings read from JSON. The heir reads
		its sidecars and writes its own tables between `fresh_pack' (or
		`begin_private_pack', which writes the `meta' rows every private pack
		carries) and `finish_pack'. Scan 59 moved up what the books builder had
		copied again: `fail_unless', `sidecars_with', `put_private_provenance'.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_PACK_WRITING

inherit
	BIB_SQLITE_REPORTING

feature -- Access

	last_error: detachable STRING_32
			-- Why the last build failed.

feature {NONE} -- The pack file

	fresh_pack (a_pack: READABLE_STRING_GENERAL; a_statements: ARRAY [STRING_8]): SIMPLE_SQL_DATABASE
			-- The pack `a_pack' made anew: an old file deleted (one that cannot be is `last_error'),
			-- the tables of `a_statements' made, a transaction begun. Always answered, to be closed
			-- by `finish_pack'.
		require
			pack_named: not a_pack.is_empty
		local
			l_file: SIMPLE_FILE
		do
			create l_file.make (a_pack)
			if l_file.exists and then not l_file.delete and last_error = Void then
				last_error := {STRING_32} "The old pack could not be deleted: " + a_pack.to_string_32
			end
			create Result.make (a_pack)
			across a_statements as ic until last_error /= Void loop
				Result.execute (ic)
				check_db (Result, "The pack's tables could not be made.")
			end
			if last_error = Void then
				Result.begin_transaction
				check_db (Result, "The pack's transaction could not begin.")
			end
		end

	begin_private_pack (a_pack: READABLE_STRING_GENERAL; a_schema: BIB_PRIVATE_PACK_SCHEMA; a_builder: READABLE_STRING_GENERAL): SIMPLE_SQL_DATABASE
			-- The pack `a_pack' made anew from `a_schema' (`fresh_pack'), with the `meta' rows every
			-- private pack carries: its kind, title, author, and `a_builder' (the command that built it).
		require
			pack_named: not a_pack.is_empty
		do
			Result := fresh_pack (a_pack, a_schema.schema_statements)
			put_meta (Result, "pack_kind", a_schema.Pack_kind.to_string_32)
			put_meta (Result, "title", a_schema.Pack_title.to_string_32)
			put_meta (Result, "author", a_schema.Pack_author.to_string_32)
			put_meta (Result, "builder", a_builder.to_string_32)
		end

	put_private_provenance (a_db: SIMPLE_SQL_DATABASE; a_key: INTEGER; a_source_key, a_edition, a_caveat: READABLE_STRING_GENERAL)
			-- Provenance row `a_key': Larry's own text, private, never shared, unless the build
			-- already failed.
		require
			key_positive: a_key > 0
		do
			if last_error = Void then
				a_db.execute_with_args ("INSERT INTO source_provenance VALUES (?, ?, ?, 'private', 1, 0, 1, 'Larry Rix', ?)",
					<<a_key, a_source_key.to_string_32, a_edition.to_string_32, a_caveat.to_string_32>>)
				check_db (a_db, "The pack's provenance could not be written.")
			end
		end

	finish_pack (a_db: SIMPLE_SQL_DATABASE)
			-- Commit what was written when the build has not failed, else roll it back; close.
		do
			if last_error = Void and then a_db.is_in_transaction then
				a_db.commit
				check_db (a_db, "The pack could not be committed.")
			end
			if a_db.is_in_transaction then
				a_db.rollback
			end
			a_db.close
		end

	put_meta (a_db: SIMPLE_SQL_DATABASE; a_key: STRING_8; a_value: STRING_32)
			-- One `meta' row, unless the build already failed.
		do
			if last_error = Void then
				a_db.execute_with_args ("INSERT INTO meta(key, value) VALUES (?, ?)", <<a_key, a_value>>)
				check_db (a_db, "A meta row could not be written.")
			end
		end

	check_db (a_db: SIMPLE_SQL_DATABASE; a_what: READABLE_STRING_GENERAL)
			-- When `a_db' failed: `last_error' says `a_what', with SQLite's own words.
		do
			if a_db.has_error and last_error = Void then
				last_error := failure_text (a_db, a_what)
			end
		end

feature {NONE} -- Sidecars

	sidecars_with (a_folder, a_extension: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- Every file ending `a_extension' in the folder `a_folder'; or `a_folder' itself when it
			-- names a file.
		require
			extension_given: not a_extension.is_empty
		local
			l_root: SIMPLE_FILE
		do
			create Result.make (16)
			create l_root.make (a_folder)
			if l_root.is_directory then
				across l_root.files_with_extension (a_extension) as ic_file loop
					Result.extend (a_folder.to_string_32 + {STRING_32} "\" + ic_file)
				end
			elseif l_root.is_file then
				Result.extend (a_folder.to_string_32)
			end
		end

	fail_unless (a_condition: BOOLEAN; a_file, a_rule: READABLE_STRING_GENERAL)
			-- Unless `a_condition': `last_error' names `a_file' and `a_rule' (the first failure stands).
		do
			if not a_condition and last_error = Void then
				last_error := a_file.to_string_32 + {STRING_32} ": " + a_rule.to_string_32
			end
		ensure
			first_failure_stands: old last_error /= Void implies last_error = old last_error
		end

	text_of (a_object: SIMPLE_JSON_OBJECT; a_key: READABLE_STRING_GENERAL): STRING_32
			-- The string under `a_key'; empty when absent, null or not a string.
		do
			if attached a_object.item (a_key.to_string_32) as al_value and then al_value.is_string then
				Result := al_value.as_string_32
			else
				create Result.make_empty
			end
		end

	strings_of (a_object: SIMPLE_JSON_OBJECT; a_key: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- The strings of the array under `a_key'; empty when absent or not an array.
		local
			i: INTEGER
		do
			create Result.make (4)
			if attached a_object.array_item (a_key.to_string_32) as al_array then
				from i := 1 until i > al_array.count loop
					if al_array [i].is_string then
						Result.extend (al_array [i].as_string_32)
					end
					i := i + 1
				end
			end
		end

end
