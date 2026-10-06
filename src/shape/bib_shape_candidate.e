note
	description: "A candidate reference with the tag-level evidence a shape needs (column to value)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SHAPE_CANDIDATE

create
	make

feature {NONE} -- Initialization

	make (a_reference: BIB_REF; a_hub_id: INTEGER_64)
		require
			hub_positive: a_hub_id > 0
		do
			ref := a_reference
			hub_id := a_hub_id
			create tags.make (8)
		ensure
			no_tags: tags_model.is_empty
		end

feature -- Access

	ref: BIB_REF
	hub_id: INTEGER_64

	tag (a_column: STRING_8): STRING_32
		require
			present: tags_model.domain [a_column]
		do
			if attached tags.item (a_column) as l_value then
				Result := l_value
			else
				check present: False then end
			end
		end

feature -- Status

	has_required_tags (a_columns: ARRAY [STRING_8]): BOOLEAN
			-- Is every column of `a_columns' tagged?
		do
			Result := across a_columns as c all tags.has (c) end
		ensure
			definition: Result = across a_columns as c all tags_model.domain [c] end
		end

feature -- Element change

	put_tag (a_column: STRING_8; a_value: READABLE_STRING_GENERAL)
		require
			column_not_empty: not a_column.is_empty
			new_column: not tags_model.domain [a_column]
		do
			tags.put (a_value.to_string_32, a_column)
		ensure
			added: tags_model |=| old tags_model.updated (a_column, a_value.to_string_32)
		end

feature -- Model

	tags_model: MML_MAP [STRING_8, STRING_32]
		do
			create Result
			across tags as t loop
				Result := Result.updated (@t.key, t)
			end
		end

feature {NONE} -- Representation

	tags: HASH_TABLE [STRING_32, STRING_8]

invariant
	hub_positive: hub_id > 0

end
