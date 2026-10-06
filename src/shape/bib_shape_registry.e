note
	description: "Shapes by slug. Ported shapes (BIB_SHAPE_<slug>) register here; the count is fixed after the data-dependency check (A-014)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SHAPE_REGISTRY

create
	make

feature {NONE} -- Initialization

	make
		do
			create shapes.make (32)
		ensure
			empty: count = 0
		end

feature -- Access

	count: INTEGER
		do
			Result := shapes.count
		ensure
			model_agrees: Result = shapes_model.count
		end

	shape (a_slug: READABLE_STRING_GENERAL): BIB_SHAPE
		require
			registered: has_slug (a_slug)
		do
			if attached shapes.item (a_slug.to_string_32) as l_shape then
				Result := l_shape
			else
				check registered: False then end
			end
		end

feature -- Status

	has_slug (a_slug: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := shapes.has (a_slug.to_string_32)
		ensure
			model_agrees: Result = shapes_model.domain [a_slug.to_string_32]
		end

feature -- Element change

	register (a_shape: BIB_SHAPE)
		require
			not_registered: not has_slug (a_shape.slug)
		do
			shapes.put (a_shape, a_shape.slug)
		ensure
			added: shapes_model |=| old shapes_model.updated (a_shape.slug, a_shape)
		end

feature -- Model

	shapes_model: MML_MAP [STRING_32, BIB_SHAPE]
		do
			create Result
			across shapes as s loop
				Result := Result.updated (@s.key, s)
			end
		end

feature {NONE} -- Representation

	shapes: HASH_TABLE [BIB_SHAPE, STRING_32]

end
