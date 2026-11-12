note
	description: "[
		The Incipit map (research 26, feature 5: "arcs OT book to NT book,
		thickness by use; click to the links"). The Old Testament books stand
		down the left (the books only the LXX has after them), the New
		Testament books down the right, and a curve joins every pair of books
		a link joins, thicker for more links. Pointing at a book lights its
		curves and says how many links it makes, with how many books; a click
		on a book calls `on_pick' with its side and name.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_INCIPIT_MAP

inherit
	SW_WIDGET
		redefine
			wants_hover_point, handle_click
		end

create
	make

feature {NONE} -- Initialization

	make
			-- An empty map.
		do
			create left_names.make (0)
			create right_names.make (0)
			create pairs.make (0)
		ensure
			empty: pairs.is_empty
		end

feature -- Access

	left_names: ARRAYED_LIST [STRING_32]
			-- The Old Testament books, top to bottom.

	right_names: ARRAYED_LIST [STRING_32]
			-- The New Testament books, top to bottom.

	pairs: ARRAYED_LIST [TUPLE [ot, nt, links: INTEGER]]
			-- Each pair of books a link joins (`ot' into `left_names', `nt' into `right_names') and how many links.

	on_pick: detachable PROCEDURE [BOOLEAN, STRING_32]
			-- Called with (on the left?, the book's name) when a book is clicked.

feature -- Element change

	set_data (a_left, a_right: ARRAYED_LIST [STRING_32]; a_pairs: ARRAYED_LIST [TUPLE [ot, nt, links: INTEGER]])
			-- Show `a_pairs' between the books `a_left' and `a_right'.
		require
			pairs_in_range: across a_pairs as ic all ic.ot >= 1 and ic.ot <= a_left.count and ic.nt >= 1 and ic.nt <= a_right.count and ic.links >= 1 end
		do
			left_names := a_left
			right_names := a_right
			pairs := a_pairs
		ensure
			kept: left_names = a_left and right_names = a_right and pairs = a_pairs
		end

	set_on_pick (a_action: detachable PROCEDURE [BOOLEAN, STRING_32])
			-- Call `a_action' when a book is clicked.
		do
			on_pick := a_action
		ensure
			set: on_pick = a_action
		end

feature -- Measurement

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- The header, and a row for each book of the longer column.
		do
			Result := Top + left_names.count.max (right_names.count).max (1) * Min_row + Pad
		end

feature -- Queries

	book_at (a_px, a_py: REAL_64): TUPLE [left: BOOLEAN; index: INTEGER]
			-- The book under (`a_px', `a_py'): its column and its index there; index 0 for none.
		local
			l_row: INTEGER
		do
			Result := [False, 0]
			if a_py >= y + Top and a_py < y + height - Pad then
				if a_px >= x and a_px < x + Label_width and not left_names.is_empty then
					l_row := ((a_py - y - Top) / row_height (left_names.count)).floor + 1
					Result := [True, l_row.max (1).min (left_names.count)]
				elseif a_px > x + width - Label_width and a_px <= x + width and not right_names.is_empty then
					l_row := ((a_py - y - Top) / row_height (right_names.count)).floor + 1
					Result := [False, l_row.max (1).min (right_names.count)]
				end
			end
		ensure
			in_range: Result.index >= 0 and (Result.left implies Result.index <= left_names.count)
				and (not Result.left implies Result.index <= right_names.count)
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
			-- The curves (the lit ones last, on top), the two columns of books, the header.
		local
			l_hover: TUPLE [left: BOOLEAN; index: INTEGER]
			l_total, l_books: INTEGER
		do
			a_p.set_color (a_p.theme.surface)
			a_p.fill_rect (x, y, width, height)
			if is_hovered then
				l_hover := book_at (hover_px, hover_py)
			else
				l_hover := [False, 0]
			end
			across pairs as ic loop
				if not lit (ic, l_hover) then
					draw_curve (a_p, ic, if l_hover.index = 0 then 0.35 else 0.10 end)
				end
			end
			across pairs as ic loop
				if lit (ic, l_hover) then
					draw_curve (a_p, ic, 0.9)
					l_total := l_total + ic.links
					l_books := l_books + 1
				end
			end
			a_p.font (a_p.Role_ui, Label_size, False)
			across left_names as ic loop
				a_p.set_color (if l_hover.index = 0 or (l_hover.left and l_hover.index = @ic.cursor_index) then a_p.theme.ink else a_p.theme.ink_muted end)
				a_p.text (x + Pad, row_center (left_names.count, @ic.cursor_index) + a_p.font_ascent / 2.0 - 1.0, ic)
			end
			across right_names as ic loop
				a_p.set_color (if l_hover.index = 0 or (not l_hover.left and l_hover.index = @ic.cursor_index) then a_p.theme.ink else a_p.theme.ink_muted end)
				a_p.text (x + width - Label_width + Pad, row_center (right_names.count, @ic.cursor_index) + a_p.font_ascent / 2.0 - 1.0, ic)
			end
			a_p.font (a_p.Role_ui, Label_size + 1.0, True)
			a_p.set_color (a_p.theme.ink)
			a_p.text (x + Pad, y + Top - 12.0, header_text (l_hover, l_total, l_books))
		end

feature -- Input

	wants_hover_point: BOOLEAN
			-- Redraw as the pointer moves: the lit book follows it.
		do
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- A book clicked: `on_pick' with its side and name.
		local
			l_book: TUPLE [left: BOOLEAN; index: INTEGER]
		do
			l_book := book_at (a_px, a_py)
			if l_book.index > 0 and then attached on_pick as al_pick then
				if l_book.left then
					al_pick.call ([True, left_names [l_book.index]])
				else
					al_pick.call ([False, right_names [l_book.index]])
				end
				Result := True
			end
		end

feature {NONE} -- Implementation

	Top: REAL_64 = 36.0
			-- Room for the header above the columns.

	Pad: REAL_64 = 8.0

	Label_width: REAL_64 = 150.0
			-- Each column of names; the curves run between them.

	Min_row: REAL_64 = 16.0

	Label_size: REAL_64 = 11.0

	row_height (a_count: INTEGER): REAL_64
			-- One row of a column of `a_count' books.
		require
			not_empty: a_count >= 1
		do
			Result := (height - Top - Pad) / a_count
		end

	row_center (a_count, a_index: INTEGER): REAL_64
			-- The middle of row `a_index' of a column of `a_count' books.
		require
			in_column: a_index >= 1 and a_index <= a_count
		do
			Result := y + Top + (a_index - 0.5) * row_height (a_count)
		end

	lit (a_pair: TUPLE [ot, nt, links: INTEGER]; a_hover: TUPLE [left: BOOLEAN; index: INTEGER]): BOOLEAN
			-- Does `a_pair' touch the book pointed at?
		do
			Result := a_hover.index > 0 and ((a_hover.left and a_pair.ot = a_hover.index) or (not a_hover.left and a_pair.nt = a_hover.index))
		end

	draw_curve (a_p: SW_PAINTER; a_pair: TUPLE [ot, nt, links: INTEGER]; a_alpha: REAL_64)
			-- A curve from the pair's Old Testament book to its New Testament book, thicker for more links.
		local
			l_points: ARRAYED_LIST [TUPLE [px, py: REAL_64]]
			x0, y0, x3, y3, dx, t, u: REAL_64
			i: INTEGER
		do
			x0 := x + Label_width
			y0 := row_center (left_names.count, a_pair.ot)
			x3 := x + width - Label_width
			y3 := row_center (right_names.count, a_pair.nt)
			dx := (x3 - x0) * 0.45
			create l_points.make (Segments + 1)
			from i := 0 until i > Segments loop
				t := i / Segments
				u := 1.0 - t
					-- a cubic from (x0, y0) leaving flat, to (x3, y3) arriving flat
				l_points.extend ([u * u * u * x0 + 3.0 * u * u * t * (x0 + dx) + 3.0 * u * t * t * (x3 - dx) + t * t * t * x3,
					u * u * u * y0 + 3.0 * u * u * t * y0 + 3.0 * u * t * t * y3 + t * t * t * y3])
				i := i + 1
			end
			a_p.set_color_alpha (a_p.theme.accent, a_alpha)
			a_p.polyline (l_points, 0.8 + 1.2 * (a_pair.links.to_double ^ 0.5))
		end

	Segments: INTEGER = 24
			-- Straight pieces per curve.

	header_text (a_hover: TUPLE [left: BOOLEAN; index: INTEGER]; a_total, a_books: INTEGER): STRING_32
			-- What the map shows, or the book pointed at and its links.
		do
			if a_hover.index = 0 then
				Result := {STRING_32} "Old Testament on the left, New Testament on the right; a thicker line, more links. Point at a book to light its lines; click it to list them."
			else
				if a_hover.left then
					Result := left_names [a_hover.index].twin
				else
					Result := right_names [a_hover.index].twin
				end
				Result.append ({STRING_32} ": " + a_total.out + (if a_total = 1 then {STRING_32} " link with " else {STRING_32} " links with " end)
					+ a_books.out + (if a_books = 1 then {STRING_32} " book. Click to list them." else {STRING_32} " books. Click to list them." end))
			end
		end

invariant
	pairs_in_range: across pairs as ic all ic.ot >= 1 and ic.ot <= left_names.count and ic.nt >= 1 and ic.nt <= right_names.count end

end
