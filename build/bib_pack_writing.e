note
	description: "[
		A private pack's writer (design scan 58): what BIB_COMMENTARY_BUILDER and
		BIB_FRAMEWORK_BUILDER had line for line - the failure kept in
		`last_error', a fresh pack file made from the schema's statements in one
		transaction and committed or rolled back at the end, `meta' rows, SQLite's
		words on a failure, and a sidecar's strings read from JSON. The heir reads
		its sidecars and writes its own tables between `fresh_pack' and
		`finish_pack'.
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

feature {NONE} -- Sidecar JSON

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
