note
	description: "[
		A chiasm pack, read (BIB_CHIASM_SCHEMA; research 28, 2026-11-11): the
		structures covering a verse, innermost first, and a structure's members
		in reading order with their partners and pair scores. Attached
		read-only under `pack_alias' by BIB_PRIVATE_SOURCE.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CHIASM_PACK

inherit
	BIB_PRIVATE_PACK_READER

create
	make

feature -- Access

	structures_at (a_book_id, a_ch, a_v: INTEGER): ARRAYED_LIST [like structure_type]
			-- The structures covering verse `a_book_id' `a_ch':`a_v' (KJV numbering), the
			-- innermost (shortest) first.
		require
			available: is_available
			a_book: a_book_id >= 1 and a_book_id <= 66
			counted_from_one: a_ch >= 1 and a_v >= 1
		do
			create Result.make (4)
			run_query ("SELECT structure_id, parent_id, under_letter, book_id, ch_from, v_from, ch_to, v_to, title, kind_printed, pattern, grade, source, "
				+ "whole, p_shape, p_pairing, repaired FROM " + pack_alias + ".structure WHERE book_id = ? AND ch_from * 1000 + v_from <= ? AND ? <= ch_to * 1000 + v_to "
				+ "ORDER BY (ch_to * 1000 + v_to) - (ch_from * 1000 + v_from), structure_id",
				{ARRAY [detachable ANY]} <<a_book_id, a_ch * 1000 + a_v, a_ch * 1000 + a_v>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					Result.extend ([ic.integer_value ("structure_id"), ic.integer_value ("parent_id"), ic.string_value ("under_letter"), ic.integer_value ("book_id"),
						ic.integer_value ("ch_from"), ic.integer_value ("v_from"), ic.integer_value ("ch_to"), ic.integer_value ("v_to"), ic.string_value ("title"),
						ic.string_value ("kind_printed"), ic.string_value ("pattern"), ic.string_value ("grade"), ic.string_value ("source"), ic.real_value ("whole"), ic.real_value ("p_shape"),
						ic.real_value ("p_pairing"), ic.integer_value ("repaired")])
				end
			end
		ensure
			covers_the_verse: across Result as al_s all al_s.ch_from * 1000 + al_s.v_from <= a_ch * 1000 + a_v and a_ch * 1000 + a_v <= al_s.ch_to * 1000 + al_s.v_to end
			innermost_first: across 2 |..| Result.count as i all span (Result [i - 1]) <= span (Result [i]) end
		end

	members_of (a_structure_id: INTEGER): ARRAYED_LIST [like member_type]
			-- The members of structure `a_structure_id', in reading order.
		require
			available: is_available
		do
			create Result.make (8)
			run_query ("SELECT seq, letter, letter_inferred, ch_from, v_from, ch_to, v_to, label, pair_seq, pair_score, repair FROM " + pack_alias
				+ ".member WHERE structure_id = ? ORDER BY seq", {ARRAY [detachable ANY]} <<a_structure_id>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					Result.extend ([ic.integer_value ("seq"), ic.string_value ("letter"), ic.integer_value ("letter_inferred") = 1, ic.integer_value ("ch_from"),
						ic.integer_value ("v_from"), ic.integer_value ("ch_to"), ic.integer_value ("v_to"), ic.string_value ("label"), ic.integer_value ("pair_seq"),
						ic.real_value ("pair_score"), ic.string_value ("repair")])
				end
			end
		ensure
			in_order: across 2 |..| Result.count as i all Result [i - 1].seq < Result [i].seq end
		end

	structure_count: INTEGER
			-- How many structures the pack holds.
		require
			available: is_available
		do
			run_query ("SELECT count(*) AS n FROM " + pack_alias + ".structure", {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows and then not al_rows.rows.is_empty then
				Result := al_rows.rows.first.integer_value ("n")
			end
		ensure
			not_negative: Result >= 0
		end

	structure_type: TUPLE [structure_id, parent_id: INTEGER; under_letter: STRING_32; book_id, ch_from, v_from, ch_to, v_to: INTEGER;
			title, kind_printed, pattern, grade, source: STRING_32; whole, p_shape, p_pairing: REAL_64; repaired: INTEGER]
			-- One structure read: `parent_id' 0 at the top; scores 0 when not graded.
		do
			Result := [0, 0, {STRING_32} "", 0, 0, 0, 0, 0, {STRING_32} "", {STRING_32} "", {STRING_32} "", {STRING_32} "", {STRING_32} "", 0.0, 0.0, 0.0, 0]
		end

	member_type: TUPLE [seq: INTEGER; letter: STRING_32; letter_inferred: BOOLEAN; ch_from, v_from, ch_to, v_to: INTEGER; label: STRING_32;
			pair_seq: INTEGER; pair_score: REAL_64; repair: STRING_32]
			-- One member read: `pair_seq' 0 for the center or an alternation's member.
		do
			Result := [0, {STRING_32} "", False, 0, 0, 0, 0, {STRING_32} "", 0, 0.0, {STRING_32} ""]
		end

	span (a_structure: like structure_type): INTEGER
			-- How far `a_structure' reaches, as the ordering of places counts it.
		do
			Result := (a_structure.ch_to * 1000 + a_structure.v_to) - (a_structure.ch_from * 1000 + a_structure.v_from)
		end

feature {NONE} -- The heir's part

	query_failed_message: STRING_8 = "A chiasm query failed."
	not_open_message: STRING_8 = "The chiasm pack is not attached."

	pack_noun: STRING_32
		once
			Result := {STRING_32} "chiasm pack"
		end

end
