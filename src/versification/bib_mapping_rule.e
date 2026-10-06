note
	description: "[
		One versification rule as data (D-010) with its provenance: TVTMS rows,
		the vault's verified LXX Jeremiah concordance, Swete entries. Pairings
		name the rule they used (AC-1a-16).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_MAPPING_RULE

inherit
	BIB_SOURCED
		redefine
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_rule_id: INTEGER_64; a_kind: INTEGER; a_name, a_description: READABLE_STRING_GENERAL; a_provenance: BIB_PROVENANCE)
			-- Create rule `a_rule_id'.
		require
			id_positive: a_rule_id > 0
			kind_valid: a_kind >= Kind_shift and a_kind <= Kind_absent
			name_not_empty: not a_name.is_empty
		do
			rule_id := a_rule_id
			kind := a_kind
			name := a_name.to_string_32
			description := a_description.to_string_32
			provenance := a_provenance
		ensure
			id_set: rule_id = a_rule_id
			kind_set: kind = a_kind
			name_set: name.same_string_general (a_name)
			provenance_set: provenance = a_provenance
		end

feature -- Access

	rule_id: INTEGER_64
	kind: INTEGER
	name: STRING_32
			-- e.g. "Ps 9/10 merge (LXX)", "Mal 4 = MT 3:19-24".
	description: STRING_32
	provenance: BIB_PROVENANCE

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
		do
			Result := rule_id = other.rule_id
		end

feature -- Constants

	Kind_shift: INTEGER = 1
	Kind_split: INTEGER = 2
	Kind_merge: INTEGER = 3
	Kind_title: INTEGER = 4
	Kind_chapter_offset: INTEGER = 5
	Kind_absent: INTEGER = 6

invariant
	id_positive: rule_id > 0
	kind_valid: kind >= Kind_shift and kind <= Kind_absent
	name_not_empty: not name.is_empty

end
