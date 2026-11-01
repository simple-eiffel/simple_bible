note
	description: "[
		One of Larry's memes as meme.db keeps it (research/25, 2026-11-01): its
		words, its credit, the cuts of its picture, and the passages it names.
		The pictures themselves stay in meme.db until one is asked for
		(BIB_MEME_STORE.picture).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_MEME

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_slug, a_title, a_description: READABLE_STRING_GENERAL)
		require
			slug_named: not a_slug.is_empty
		do
			id := a_id
			slug := a_slug.to_string_32
			title := a_title.to_string_32
			description := a_description.to_string_32
			create trigger_line.make_empty
			create hook.make_empty
			create punch.make_empty
			create meme_set.make_empty
			create credit.make_empty
			create license.make_empty
			create variants.make (2)
			create passages.make (2)
		ensure
			kept: id = a_id and slug.same_string_general (a_slug)
		end

feature -- Access

	id: INTEGER_64
	slug: STRING_32
	title: STRING_32

	description: STRING_32
			-- The words that go with it (Larry's post copy).

	trigger_line, hook, punch: STRING_32
			-- The card's three lines, as the notes name them (empty when it has none).

	meme_set: STRING_32
			-- The set it belongs to ("FB Memes", "Truth over Tribe").

	credit, license: STRING_32
			-- Who made it (and whose photograph it uses); the license it goes out under (empty: Larry's
			-- own, free to share).

	variants: ARRAYED_LIST [TUPLE [cut: STRING_8; width, height: INTEGER]]
			-- Its pictures, the feed design first.

	passages: ARRAYED_LIST [TUPLE [hub_from, hub_to: INTEGER_64; wording: STRING_32]]
			-- The passages it names.

	names_verse (a_hub: INTEGER_64): BOOLEAN
			-- Does one of its passages take in verse `a_hub'?
		do
			Result := across passages as ic some ic.hub_from <= a_hub and a_hub <= ic.hub_to end
		end

	names_chapter (a_book, a_chapter: INTEGER): BOOLEAN
			-- Does one of its passages lie in that chapter?
		local
			l_hub: BIB_HUB_ID
		do
			create l_hub
			Result := across passages as ic some
				l_hub.book_of (ic.hub_from) <= a_book and a_book <= l_hub.book_of (ic.hub_to)
				and then (l_hub.book_of (ic.hub_from) < a_book or l_hub.chapter_of (ic.hub_from) <= a_chapter)
				and then (l_hub.book_of (ic.hub_to) > a_book or a_chapter <= l_hub.chapter_of (ic.hub_to))
			end
		end

	references_text: STRING_32
			-- Its passages as written, joined: "John 3:16 %/183/ Romans 8:1" (a middle dot between).
		do
			create Result.make (32)
			across passages as ic loop
				if not Result.is_empty then
					Result.append ({STRING_32} " %/183/ ")
				end
				Result.append (ic.wording)
			end
		end

feature {BIB_MEME_STORE} -- Filled by the store

	set_lines (a_trigger, a_hook, a_punch, a_set, a_credit, a_license: READABLE_STRING_GENERAL)
		do
			trigger_line := a_trigger.to_string_32
			hook := a_hook.to_string_32
			punch := a_punch.to_string_32
			meme_set := a_set.to_string_32
			credit := a_credit.to_string_32
			license := a_license.to_string_32
		end

invariant
	slug_named: not slug.is_empty
	passages_ordered: across passages as ic all ic.hub_from > 0 and ic.hub_to >= ic.hub_from end

end
