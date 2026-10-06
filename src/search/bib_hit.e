note
	description: "One search hit: reference, hub id, version, a copy of the display text and the matched spans, with provenance."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_HIT

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_reference: BIB_REF; a_hub_id: INTEGER_64; a_version: READABLE_STRING_8; a_text: READABLE_STRING_32;
			a_spans: ITERABLE [BIB_TEXT_SPAN]; a_provenance: BIB_PROVENANCE)
		require
			hub_positive: a_hub_id > 0
			version_not_empty: not a_version.is_empty
			spans_within_text: across a_spans as s all s.finish <= a_text.count end
		do
			ref := a_reference
			hub_id := a_hub_id
			version_code := a_version.to_string_8
			display_text := a_text.to_string_32
			provenance := a_provenance
			create spans.make (2)
			across a_spans as s loop
				spans.extend (s)
			end
		ensure
			text_kept: display_text.same_string (a_text)
		end

feature -- Access

	ref: BIB_REF
	hub_id: INTEGER_64
	version_code: STRING_8
	display_text: STRING_32
	provenance: BIB_PROVENANCE

	span_count: INTEGER
		do
			Result := spans.count
		end

feature -- Model

	spans_model: MML_SEQUENCE [BIB_TEXT_SPAN]
		do
			create Result
			across spans as s loop
				Result := Result & s
			end
		end

feature {NONE} -- Representation

	spans: ARRAYED_LIST [BIB_TEXT_SPAN]

invariant
	hub_positive: hub_id > 0
	version_not_empty: not version_code.is_empty

end
