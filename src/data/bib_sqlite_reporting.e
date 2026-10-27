note
	description: "[
		SQLite's own words for a failure (FR-138, never "Unknown error"), and the
		first value of a one-row answer, shared by every class that runs statements:
		BIB_SOURCE_SET and BIB_CONC_PACK (design scan 27), the user store, the note
		store, private packs and the builders (design scan 39: five copies of the
		failure text and three of the first-value readers had appeared). Stateless;
		inherit it beside the class's real parent.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SQLITE_REPORTING

feature {NONE} -- Reporting

	sqlite_message (a_db: SIMPLE_SQL_DATABASE; a_fallback: READABLE_STRING_GENERAL): STRING_32
			-- SQLite's own message for the last failure on `a_db', or `a_fallback' when it gave none.
		do
			if attached a_db.last_error_message as al_message and then not al_message.is_empty then
				Result := al_message.twin
			else
				Result := a_fallback.to_string_32
			end
		ensure
			not_empty: not a_fallback.is_empty implies not Result.is_empty
		end

	failure_text (a_db: SIMPLE_SQL_DATABASE; a_what: READABLE_STRING_GENERAL): STRING_32
			-- `a_what', then SQLite's own words for the last failure on `a_db' when it gave any.
		local
			l_words: STRING_32
		do
			Result := a_what.to_string_32
			l_words := sqlite_message (a_db, "")
			if not l_words.is_empty then
				Result.append ({STRING_32} ": " + l_words)
			end
		ensure
			starts_with_what: Result.starts_with (a_what.to_string_32)
		end

	first_integer (a_result: SIMPLE_SQL_RESULT): INTEGER
			-- The first column of the first row as a whole number; 0 when there is none.
		do
			if not a_result.rows.is_empty and then a_result.rows.first.count >= 1 then
				Result := a_result.rows.first.integer_value (a_result.rows.first.column_name (1))
			end
		end

	first_text (a_result: SIMPLE_SQL_RESULT): STRING_32
			-- The first column of the first row as text; empty when there is none.
		do
			create Result.make_empty
			if not a_result.rows.is_empty and then a_result.rows.first.count >= 1 then
				Result := a_result.rows.first.string_value (a_result.rows.first.column_name (1))
			end
		end

end
