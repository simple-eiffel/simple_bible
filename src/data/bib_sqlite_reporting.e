note
	description: "[
		SQLite's own words for a failure (FR-138, never "Unknown error"), shared by
		the classes that run statements on the connection: BIB_SOURCE_SET and
		BIB_CONC_PACK (design scan 27: the second copy had appeared). Stateless;
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

end
