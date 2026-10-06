note
	description: "[
		Where a search or count looks: versions, a canonical book range and the
		counting unit. Its `label' is the scope label every count shows
		("NT, SBLGNT, word tokens"; A-025). Collections arrive in 1b.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SEARCH_SCOPE

create
	make

feature {NONE} -- Initialization

	make (a_label: READABLE_STRING_GENERAL; a_versions: ITERABLE [READABLE_STRING_8]; a_first_book, a_last_book: INTEGER; a_unit: READABLE_STRING_GENERAL)
			-- Scope over `a_versions', books `a_first_book'..`a_last_book', counting `a_unit'.
		require
			label_not_empty: not a_label.is_empty
			books_ordered: a_first_book >= 1 and a_first_book <= a_last_book
			unit_not_empty: not a_unit.is_empty
		do
			label := a_label.to_string_32
			first_book := a_first_book
			last_book := a_last_book
			unit := a_unit.to_string_32
			create versions.make (2)
			across a_versions as v loop
				versions.extend (v.to_string_8)
			end
		ensure
			label_set: label.same_string_general (a_label)
			not_wide: not is_user_confirmed_wide
		end

feature -- Access

	label: STRING_32
	first_book: INTEGER
	last_book: INTEGER
	unit: STRING_32
			-- Counting unit: "word tokens", "verses", ...

	book_count: INTEGER
		do
			Result := last_book - first_book + 1
		end

	version_count: INTEGER
		do
			Result := versions.count
		end

feature -- Status

	is_user_confirmed_wide: BOOLEAN
			-- Did the user confirm a multi-version regex search?

	contains (a_ref: BIB_REF): BOOLEAN
			-- Is `a_ref' inside the book range?
		do
			Result := a_ref.book_id >= first_book and a_ref.book_id <= last_book
		end

feature -- Element change

	confirm_wide
			-- Record the user's confirmation of a wide regex search.
		do
			is_user_confirmed_wide := True
		ensure
			confirmed: is_user_confirmed_wide
			versions_unchanged: versions_model |=| old versions_model
		end

feature -- Model

	versions_model: MML_SEQUENCE [STRING_8]
		do
			create Result
			across versions as v loop
				Result := Result & v
			end
		end

feature {NONE} -- Representation

	versions: ARRAYED_LIST [STRING_8]

invariant
	label_not_empty: not label.is_empty
	books_ordered: first_book >= 1 and first_book <= last_book
	unit_not_empty: not unit.is_empty

end
