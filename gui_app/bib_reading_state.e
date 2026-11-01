note
	description: "[
		The place read, one copy of each fact (research/23 phase 3, 2026-11-01):
		the version, the book, chapter and verse, and the trail Back and Forward
		walk. Each door tells its listeners only on a real change, and joining
		tells a listener the present at once.

		The events are split by what they change, so a listener redraws only
		what depends on it: `chapter_changed' when the chapter's text is another
		(a new book, chapter or version), `verse_changed' whenever the verse
		read changes (also after `chapter_changed', which always comes first),
		`version_changed' for what names the version, and `history_changed'
		when the trail or its position moves.

		Before this, `open_reading' rebuilt the chapter, Parallel and nine
		Study panes on every verse click (risk 17), the Go menu asked the
		toolbar buttons whether a chapter came before or after (risk 3), and
		"a verse is chosen" was written out in 22 places (risk 20).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_READING_STATE

create
	make

feature {NONE} -- Initialization

	make
		do
			create version.make_empty
			create trail.make (40)
			create version_changed.make
			create chapter_changed.make
			create verse_changed.make
			create history_changed.make
		ensure
			nowhere: not has_place and not has_verse
			no_trail: history_count = 0 and history_index = 0
		end

feature -- Access

	version: STRING_8
			-- The version read; empty before one is chosen.

	book, chapter, verse: INTEGER
			-- The chapter read and its verse (0: none; `book' 0: nothing read yet).

	history_index: INTEGER
			-- Where Back and Forward stand on the trail (0: no trail yet).

	history_count: INTEGER
			-- Places on the trail.
		do
			Result := trail.count
		end

	history_place (a_index: INTEGER): TUPLE [book, chapter, verse: INTEGER]
			-- Place `a_index' of the trail.
		require
			valid: a_index >= 1 and a_index <= history_count
		do
			Result := trail.i_th (a_index)
		end

	has_place: BOOLEAN
			-- Is a chapter read?
		do
			Result := book > 0
		end

	has_verse: BOOLEAN
			-- Is a verse of it chosen?
		do
			Result := verse > 0
		end

	can_go_back: BOOLEAN
		do
			Result := history_index > 1
		end

	can_go_forward: BOOLEAN
		do
			Result := history_index < trail.count
		end

	is_at (a_book, a_chapter, a_verse: INTEGER): BOOLEAN
			-- Is that the place read?
		do
			Result := book = a_book and chapter = a_chapter and verse = a_verse
		end

feature -- Events

	version_changed: SW_EVENT [TUPLE [version: STRING_8]]
			-- The version read is another.

	chapter_changed: SW_EVENT [TUPLE]
			-- The chapter's text is another: a new book, chapter or version (a place being read).

	verse_changed: SW_EVENT [TUPLE]
			-- The verse read changed; told after `chapter_changed' when both did.

	history_changed: SW_EVENT [TUPLE]
			-- The trail or its position moved.

feature -- Joining (subscribe, and be told the present)

	on_version (a_action: PROCEDURE [STRING_8])
		do
			version_changed.subscribe (a_action)
			if not version.is_empty then
				a_action.call ([version])
			end
		end

	on_chapter (a_action: PROCEDURE)
		do
			chapter_changed.subscribe (a_action)
			if has_place then
				a_action.call (Void)
			end
		end

	on_verse (a_action: PROCEDURE)
		do
			verse_changed.subscribe (a_action)
			if has_place then
				a_action.call (Void)
			end
		end

	on_history (a_action: PROCEDURE)
		do
			history_changed.subscribe (a_action)
			a_action.call (Void)
		end

feature -- Doors

	set_version (a_code: READABLE_STRING_8)
			-- Read version `a_code': the same place, its text in that version.
		require
			named: not a_code.is_empty
		do
			if not version.same_string (a_code) then
				version := a_code.to_string_8
				version_changed.call ([version])
				if has_place then
					chapter_changed.call (Void)
					verse_changed.call (Void)
				end
			end
		ensure
			set: version.same_string (a_code)
		end

	go_to (a_book, a_chapter, a_verse: INTEGER)
			-- Read that place: a new step on the trail (the steps ahead are dropped), unless it is the
			-- place read already.
		require
			book_positive: a_book > 0
			chapter_positive: a_chapter > 0
			verse_not_negative: a_verse >= 0
		do
			if not is_at (a_book, a_chapter, a_verse) then
				from until trail.count <= history_index loop
					trail.finish
					trail.remove
				end
				trail.extend ([a_book, a_chapter, a_verse])
				history_index := trail.count
				move_to (a_book, a_chapter, a_verse)
				history_changed.call (Void)
			end
		ensure
			there: is_at (a_book, a_chapter, a_verse)
			at_the_trail_end: history_index = history_count
		end

	step_history (a_step: INTEGER)
			-- Back (-1) or Forward (1) along the trail.
		require
			back_or_forward: (a_step = -1 and can_go_back) or (a_step = 1 and can_go_forward)
		do
			history_index := history_index + a_step
			move_to (trail.i_th (history_index).book, trail.i_th (history_index).chapter, trail.i_th (history_index).verse)
			history_changed.call (Void)
		ensure
			stepped: history_index = old history_index + a_step
		end

	redraw
			-- Tell the chapter and the verse again, nothing changed (a highlight changed their washes).
		do
			if has_place then
				chapter_changed.call (Void)
				verse_changed.call (Void)
			end
		end

feature {NONE} -- Implementation

	trail: ARRAYED_LIST [TUPLE [book, chapter, verse: INTEGER]]
			-- The places read, for Back and Forward.

	move_to (a_book, a_chapter, a_verse: INTEGER)
			-- The place read is that one; told by what changed.
		do
			if a_book /= book or a_chapter /= chapter then
				book := a_book
				chapter := a_chapter
				verse := a_verse
				chapter_changed.call (Void)
				verse_changed.call (Void)
			elseif a_verse /= verse then
				verse := a_verse
				verse_changed.call (Void)
			end
		ensure
			there: is_at (a_book, a_chapter, a_verse)
		end

invariant
	index_on_the_trail: history_index >= 0 and history_index <= trail.count
	a_trail_has_a_position: trail.is_empty = (history_index = 0)
	verse_needs_a_chapter: has_verse implies has_place

end
