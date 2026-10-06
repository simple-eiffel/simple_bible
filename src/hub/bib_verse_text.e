note
	description: "[
		One verse in one version: the exact display text (byte-equal to the
		source, MapM's no-break space kept, FR-008, AC-1a-20) or a typed
		omission, never an empty string (AC-1a-19); with provenance and, for
		Swete, a repair state. `display_text' has no setter (DR-009).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_VERSE_TEXT

inherit
	BIB_SOURCED

create
	make_text, make_omission

feature {NONE} -- Initialization

	make_text (a_reference: BIB_REF; a_hub_id: INTEGER_64; a_version: BIB_VERSION_INFO; a_text: READABLE_STRING_32;
			a_repair_state: BIB_REPAIR_STATE; a_provenance: BIB_PROVENANCE)
			-- The text of a verse.
		require
			hub_positive: a_hub_id > 0
			text_not_empty: not a_text.is_empty
			swete_quality_known: a_version.is_swete implies not a_repair_state.is_not_applicable
		do
			ref := a_reference
			hub_id := a_hub_id
			version := a_version
			display_text := a_text.to_string_32
			repair_state := a_repair_state
			provenance := a_provenance
		ensure
			text_kept: attached display_text as t and then t.same_string (a_text)
			no_omission: omission = Void
		end

	make_omission (a_reference: BIB_REF; a_hub_id: INTEGER_64; a_version: BIB_VERSION_INFO; a_omission: BIB_OMISSION; a_provenance: BIB_PROVENANCE)
			-- A typed omission in place of the verse.
		require
			hub_positive: a_hub_id > 0
		do
			ref := a_reference
			hub_id := a_hub_id
			version := a_version
			omission := a_omission
			if a_version.is_swete then
				create repair_state.make ({BIB_REPAIR_STATE}.As_imported_ocr)
			else
				create repair_state.make_not_applicable
			end
			provenance := a_provenance
		ensure
			omission_set: omission = a_omission
			no_text: display_text = Void
		end

feature -- Access

	ref: BIB_REF
	hub_id: INTEGER_64
	version: BIB_VERSION_INFO
	display_text: detachable STRING_32
	omission: detachable BIB_OMISSION
	repair_state: BIB_REPAIR_STATE
	provenance: BIB_PROVENANCE

feature -- Status

	is_quarantined: BOOLEAN
		do
			Result := attached omission as o and then o.is_quarantined
		end

invariant
	hub_positive: hub_id > 0
	text_xor_omission: (display_text /= Void) xor (omission /= Void)
	text_never_empty: attached display_text as t implies not t.is_empty
	swete_quality_known: version.is_swete implies not repair_state.is_not_applicable

end
