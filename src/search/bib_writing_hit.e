note
	description: "[
		One place in Larry's writings a search found (research/20): which pack, the
		address a reading pane follows ("book:beacon/2#14", "framework:prism",
		"bible:48.2.15-2.21"), where it stands ("Beacon, Chapter 2"), a snippet
		with the matched words marked, its rank within its pack (bm25: lower is
		better) and its voice.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_WRITING_HIT

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_pack_kind, a_address, a_place, a_snippet: READABLE_STRING_GENERAL; a_rank: REAL_64; a_voice: READABLE_STRING_GENERAL; a_provenance: BIB_PROVENANCE)
			-- A hit at `a_address' in a pack of kind `a_pack_kind'.
		require
			kind_given: not a_pack_kind.is_empty
			address_given: not a_address.is_empty
		do
			pack_kind := a_pack_kind.to_string_32
			address := a_address.to_string_32
			place := a_place.to_string_32
			snippet := a_snippet.to_string_32
			rank := a_rank
			voice := a_voice.to_string_32
			provenance := a_provenance
		ensure
			addressed: address.same_string_general (a_address)
			ranked: rank = a_rank
		end

feature -- Access

	pack_kind: STRING_32
			-- "commentary", "frameworks" or "books".

	address: STRING_32
			-- The link a reading pane follows.

	place: STRING_32
			-- Where the hit stands, as a reader names it.

	snippet: STRING_32
			-- The words around the match, the matched words between marks.

	rank: REAL_64
			-- bm25 within its pack: lower is better.

	voice: STRING_32
			-- Whose words: "author" for Larry's own.

	provenance: BIB_PROVENANCE

invariant
	kind_present: not pack_kind.is_empty
	address_present: not address.is_empty

end
