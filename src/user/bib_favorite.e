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
	make_passage

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

	anchor_from, anchor_to: INTEGER
			-- The characters a quotation spans in its source (stage D).

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
	folder_non_negative: folder_id >= 0

end
