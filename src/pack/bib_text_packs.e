note
	description: "[
		Every kind of pack of Larry's long texts (design scan 62): books, then essays,
		in the order the Author Library lists them. The facade, the link reader and
		the builder loop over `schemas'; a new kind is one more schema here.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_TEXT_PACKS

feature -- Access

	schemas: ARRAYED_LIST [BIB_TEXT_PACK_SCHEMA]
			-- Every kind, books first.
		once
			create Result.make (2)
			Result.extend (create {BIB_BOOK_SCHEMA})
			Result.extend (create {BIB_ESSAY_SCHEMA})
		ensure
			some_kind: not Result.is_empty
		end

	schema_of_kind (a_kind: READABLE_STRING_GENERAL): detachable BIB_TEXT_PACK_SCHEMA
			-- The schema whose pack kind is `a_kind'; Void for none.
		do
			across schemas as ic loop
				if Result = Void and then ic.Pack_kind.same_string_general (a_kind) then
					Result := ic
				end
			end
		ensure
			of_kind: attached Result as r implies r.Pack_kind.same_string_general (a_kind)
		end

end
