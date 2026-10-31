note
	description: "[
		One claim about when something happened (Plan 22): the date as
		written (EDTF) and the years it allows, the chronology it follows,
		who holds it, its basis (evidence, the text's own reckoning, a
		regnal reckoning, or tradition), whether it is the view the program
		shows first, and its citation. No grade: the claim and its holder
		speak for themselves.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CLAIM

create
	make

feature {NONE} -- Initialization

	make (a_edtf: BIB_EDTF; a_chronology, a_held_by, a_basis, a_citation, a_remark: READABLE_STRING_GENERAL; a_lean: BOOLEAN)
		require
			a_date: a_edtf.is_valid
			basis_known: is_basis (a_basis)
		do
			edtf := a_edtf
			create chronology.make_from_string_general (a_chronology)
			create held_by.make_from_string_general (a_held_by)
			create basis.make_from_string_general (a_basis)
			create citation_id.make_from_string_general (a_citation)
			create remark.make_from_string_general (a_remark)
			is_lean := a_lean
		ensure
			kept: edtf = a_edtf and is_lean = a_lean
		end

feature -- Access

	edtf: BIB_EDTF
	chronology, held_by, basis, citation_id, remark: STRING_32
			-- (`remark' is the claim's note; `note' is an Eiffel keyword.)
	is_lean: BOOLEAN
			-- Is this the position the program shows first (never pre-selected as true)?

	earliest: INTEGER
		do
			Result := edtf.earliest
		end

	latest: INTEGER
		do
			Result := edtf.latest
		end

	label: STRING_32
			-- How a position names itself: who holds it, else its chronology, else its date.
		do
			if not held_by.is_empty then
				Result := held_by.twin
			elseif not chronology.is_empty then
				Result := chronology + {STRING_32} " chronology"
			else
				Result := edtf.text.twin
			end
		end

feature -- Bases

	Bases: ARRAY [STRING_8]
		once
			Result := <<"evidence", "text", "reckoning", "tradition">>
		end

	is_basis (a_basis: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := across Bases as b some b.same_string_general (a_basis) end
		end

invariant
	ordered: earliest <= latest

end
