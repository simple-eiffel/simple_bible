note
	description: "An immutable token id in core.db `word'."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_WORD_ID

inherit
	BIB_KEY

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER_64)
			-- Create word id `a_id'.
		require
			positive: a_id > 0
		do
			id := a_id
			text := a_id.out.to_string_32
		ensure
			id_set: id = a_id
		end

feature -- Access

	id: INTEGER_64

	kind_label: STRING_32
		do
			Result := {STRING_32} "word"
		end

invariant
	id_positive: id > 0

end
