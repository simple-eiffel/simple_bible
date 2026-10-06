note
	description: "An indexed NT quotation (UBS seed): NT range and hub id, MT and LXX ranges, match kind."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_QUOTATION

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_nt_range: BIB_REF_RANGE; a_nt_hub_id: INTEGER_64; a_mt_range, a_lxx_range: detachable BIB_REF_RANGE;
			a_match_kind: READABLE_STRING_GENERAL; a_provenance: BIB_PROVENANCE)
		require
			id_positive: a_id > 0
			hub_positive: a_nt_hub_id > 0
			has_source_text: a_mt_range /= Void or a_lxx_range /= Void
			kind_given: not a_match_kind.is_empty
		do
			id := a_id
			nt_range := a_nt_range
			nt_hub_id := a_nt_hub_id
			mt_range := a_mt_range
			lxx_range := a_lxx_range
			match_kind := a_match_kind.to_string_32
			provenance := a_provenance
		end

feature -- Access

	id: INTEGER_64
	nt_range: BIB_REF_RANGE
	nt_hub_id: INTEGER_64
	mt_range: detachable BIB_REF_RANGE
	lxx_range: detachable BIB_REF_RANGE
	match_kind: STRING_32
	provenance: BIB_PROVENANCE

invariant
	id_positive: id > 0
	has_source_text: mt_range /= Void or lxx_range /= Void

end
