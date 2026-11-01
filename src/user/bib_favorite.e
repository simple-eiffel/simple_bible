note
	description: "[
		One of the reader's favorites (research/24 stage C, 2026-11-01): a passage
		(a verse, a range of verses or a whole chapter) kept in a folder of the
		reader's own, with the version it was saved in (Larry: "record the
		version of the favorite"). The passage is keyed to canonical hub ids, so
		its star shows in every version (AC-1a-39); the version is what it was
		read in. Documents and quotations (stage D) use the same row: a target
		link, the quoted text and the characters it spans.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_FAVORITE

inherit
	BIB_USER_ITEM

create
	make_passage,
	make_document,
	make_quotation

feature {NONE} -- Initialization

	make_passage (a_from, a_to: INTEGER_64; a_version: READABLE_STRING_8; a_label: READABLE_STRING_GENERAL)
			-- Verses `a_from' to `a_to' (one verse when equal), read in `a_version', named `a_label'.
		require
			from_positive: a_from > 0
			in_order: a_to >= a_from
		do
			favorite_kind := Passage
			hub_id := a_from
			end_hub_id := a_to
			version := a_version.to_string_8
			label := a_label.to_string_32
			create target.make_empty
			create quote.make_empty
		ensure
			passage: is_passage
			spans: hub_id = a_from and end_hub_id = a_to
			version_kept: version.same_string (a_version)
		end

	make_document (a_target, a_label: READABLE_STRING_GENERAL)
			-- A whole document: the book, chapter, essay or framework link `a_target' opens, named
			-- `a_label' (research/24 stage D).
		require
			has_target: not a_target.is_empty
		do
			favorite_kind := Document
			target := a_target.to_string_32
			label := a_label.to_string_32
			create version.make_empty
			create quote.make_empty
		ensure
			document: is_document
			target_kept: target.same_string_general (a_target)
		end

	make_quotation (a_target, a_quote: READABLE_STRING_GENERAL; a_hub: INTEGER_64; a_version: READABLE_STRING_8;
			a_from, a_to: INTEGER_64; a_label: READABLE_STRING_GENERAL)
			-- The text `a_quote' selected in the document `a_target' opens (Larry: a part of a
			-- framework, a commentary, a book), from position `a_from' to `a_to' of it (item * 1,000,000
			-- + offset, as `Anchor_scale' says: a hint, the quote itself is what is found again);
			-- verse `a_hub' and `a_version' when it is a verse's part (0 and empty otherwise).
		require
			has_target: not a_target.is_empty
			has_quote: not a_quote.is_empty
			hub_non_negative: a_hub >= 0
			anchors_ordered: 0 <= a_from and a_from <= a_to
		do
			favorite_kind := Quotation
			target := a_target.to_string_32
			quote := a_quote.to_string_32
			hub_id := a_hub
			end_hub_id := a_hub
			version := a_version.to_string_8
			anchor_from := a_from
			anchor_to := a_to
			label := a_label.to_string_32
		ensure
			quotation: is_quotation
			kept: target.same_string_general (a_target) and quote.same_string_general (a_quote) and anchor_from = a_from and anchor_to = a_to
		end

feature -- Access

	favorite_kind: INTEGER
			-- `Passage', `Document' or `Quotation'.

	end_hub_id: INTEGER_64
			-- The last verse a passage spans (`hub_id' for one verse).

	version: STRING_8
			-- The version it was saved in (empty when none applies).

	label: STRING_32
			-- Its name in the Favorites tree.

	target: STRING_32
			-- A document's link (stage D); empty for a passage.

	quote: STRING_32
			-- A quotation's text (stage D); empty otherwise.

	anchor_from, anchor_to: INTEGER_64
			-- Where a quotation starts and ends in its source: item * `Anchor_scale' + offset.

	Anchor_scale: INTEGER_64 = 1_000_000
			-- An anchor's item and offset in one number.

	anchor_item (a_anchor: INTEGER_64): INTEGER
			-- The item of anchor `a_anchor'.
		do
			Result := (a_anchor // Anchor_scale).to_integer_32
		end

	anchor_offset (a_anchor: INTEGER_64): INTEGER
			-- The offset of anchor `a_anchor'.
		do
			Result := (a_anchor \\ Anchor_scale).to_integer_32
		end

	folder_id: INTEGER_64
			-- The folder it is in (0: the root).

	kind: INTEGER
		do
			Result := {BIB_USER_STORE}.Kind_favorite
		end

feature -- Status

	is_passage: BOOLEAN
		do
			Result := favorite_kind = Passage
		end

	is_document: BOOLEAN
		do
			Result := favorite_kind = Document
		end

	is_quotation: BOOLEAN
		do
			Result := favorite_kind = Quotation
		end

	is_single_verse: BOOLEAN
		do
			Result := is_passage and end_hub_id = hub_id
		end

	covers (a_hub: INTEGER_64): BOOLEAN
			-- Does this passage take in verse `a_hub'?
		do
			Result := is_passage and hub_id <= a_hub and a_hub <= end_hub_id
		end

	is_whole_chapter: BOOLEAN
			-- Does this passage span a chapter from its first part to its last?
		local
			l_hub: BIB_HUB_ID
		do
			create l_hub
			Result := is_passage and then l_hub.is_valid_hub (hub_id) and then l_hub.verse_of (hub_id) = 1
				and then end_hub_id = l_hub.hub_id (l_hub.book_of (hub_id), l_hub.chapter_of (hub_id), l_hub.Max_part)
		end

feature -- Kinds

	Passage: INTEGER = 1
	Document: INTEGER = 2
	Quotation: INTEGER = 3

feature {BIB_USER_STORE} -- Store bookkeeping

	set_folder (a_folder_id: INTEGER_64)
		require
			non_negative: a_folder_id >= 0
		do
			folder_id := a_folder_id
		ensure
			set: folder_id = a_folder_id
		end

	set_label (a_label: READABLE_STRING_GENERAL)
		do
			label := a_label.to_string_32
		end

invariant
	known_kind: favorite_kind >= Passage and favorite_kind <= Quotation
	passage_in_order: is_passage implies (hub_id > 0 and end_hub_id >= hub_id)
	document_has_target: is_document implies not target.is_empty
	quotation_has_its_text: is_quotation implies (not target.is_empty and not quote.is_empty)
	folder_non_negative: folder_id >= 0

end
