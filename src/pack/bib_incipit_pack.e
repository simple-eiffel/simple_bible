note
	description: "[
		An incipit pack, read (BIB_INCIPIT_SCHEMA; research 27, 2026-11-11):
		the links a New Testament verse makes into the Old (LXX numbering), the
		links an LXX verse or an English Old Testament verse receives, and every
		link at once in New Testament or Old Testament order (Larry, 2026-11-12:
		"I want the ability to see all of both in a list"). Each link comes with
		its kind, loudness, volume and witnesses. Attached read-only under
		`pack_alias' by BIB_PRIVATE_SOURCE.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_INCIPIT_PACK

inherit
	BIB_PRIVATE_PACK_READER

create
	make

feature -- Access

	links_from (a_nt_book: READABLE_STRING_GENERAL; a_ch, a_v: INTEGER): ARRAYED_LIST [like link_type]
			-- The links New Testament verse `a_nt_book' `a_ch':`a_v' makes, loudest first.
		require
			available: is_available
			book_named: not a_nt_book.is_empty
			counted_from_one: a_ch >= 1 and a_v >= 1
		do
			Result := links_where ("l.nt_book = ? AND l.nt_ch = ? AND ? BETWEEN l.nt_v_from AND l.nt_v_to", <<a_nt_book.to_string_32, a_ch, a_v>>, Loudest_first)
		ensure
			loudest_first: across 2 |..| Result.count as i all Result [i - 1].volume >= Result [i].volume end
		end

	links_into (a_lxx_book: READABLE_STRING_GENERAL; a_ch, a_v: INTEGER): ARRAYED_LIST [like link_type]
			-- The links LXX verse `a_lxx_book' `a_ch':`a_v' receives, loudest first.
		require
			available: is_available
			book_named: not a_lxx_book.is_empty
			counted_from_one: a_ch >= 1 and a_v >= 1
		do
			Result := links_where ("l.lxx_book = ? AND l.lxx_ch = ? AND ? BETWEEN l.lxx_v_from AND l.lxx_v_to", <<a_lxx_book.to_string_32, a_ch, a_v>>, Loudest_first)
		ensure
			loudest_first: across 2 |..| Result.count as i all Result [i - 1].volume >= Result [i].volume end
		end

	links_into_english (a_book_id, a_ch, a_v: INTEGER): ARRAYED_LIST [like link_type]
			-- The links Old Testament verse `a_book_id' `a_ch':`a_v' (English numbering, as the reader
			-- shows it) receives, loudest first.
		require
			available: is_available
			old_testament: a_book_id >= 1 and a_book_id <= 39
			counted_from_one: a_ch >= 1 and a_v >= 1
		do
			Result := links_where ("l.en_book_id = ? AND l.en_ch = ? AND l.en_v = ?", <<a_book_id, a_ch, a_v>>, Loudest_first)
		ensure
			loudest_first: across 2 |..| Result.count as i all Result [i - 1].volume >= Result [i].volume end
			into_that_verse: across Result as al_l all al_l.en_book_id = a_book_id and al_l.en_ch = a_ch and al_l.en_v = a_v end
		end

	all_links (a_by_old_testament: BOOLEAN): ARRAYED_LIST [like link_type]
			-- Every link, in New Testament order (book, chapter, verse), or in Old Testament order
			-- when `a_by_old_testament' (English place first, a book only the LXX has after its
			-- canon by the LXX place); the loudest first within a verse.
		require
			available: is_available
		do
			if a_by_old_testament then
				Result := links_where ("1 = 1", {ARRAY [detachable ANY]} <<>>, "ORDER BY l.en_book_id IS NULL, l.en_book_id, l.en_ch, l.en_v, l.lxx_book, l.lxx_ch, l.lxx_v_from, l.volume DESC, l.link_id")
			else
				Result := links_where ("1 = 1", {ARRAY [detachable ANY]} <<>>, "ORDER BY instr('" + Nt_order + "', '|' || l.nt_book || '|'), l.nt_ch, l.nt_v_from, l.volume DESC, l.link_id")
			end
		ensure
			every_link: Result.count = link_count
		end

	link_count: INTEGER
			-- How many links the pack holds.
		require
			available: is_available
		do
			run_query ("SELECT count(*) AS n FROM " + pack_alias + ".incipit_link", {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows and then not al_rows.rows.is_empty then
				Result := al_rows.rows.first.integer_value ("n")
			end
		ensure
			not_negative: Result >= 0
		end

	link_type: TUPLE [link_id: INTEGER; nt_book: STRING_32; nt_ch, nt_v: INTEGER; lxx_book: STRING_32; lxx_ch, lxx_v: INTEGER;
			kind, loudness: STRING_32; volume: REAL_64; unit_title, book_class, witnesses: STRING_32; en_book_id, en_ch, en_v: INTEGER]
			-- The shape of one link read: `witnesses' lists each witness and its detail ("ubs huhn**");
			-- `en_book_id' is 0 when the LXX verse has no English place (a book the English Bibles lack).
		do
			Result := [0, {STRING_32} "", 0, 0, {STRING_32} "", 0, 0, {STRING_32} "", {STRING_32} "", 0.0, {STRING_32} "", {STRING_32} "", {STRING_32} "", 0, 0, 0]
		end

feature {NONE} -- Implementation

	Loudest_first: STRING_8 = "ORDER BY l.volume DESC, l.link_id"

	Nt_order: STRING_8 = "|MAT|MRK|LUK|JHN|ACT|ROM|1CO|2CO|GAL|EPH|PHP|COL|1TH|2TH|1TI|2TI|TIT|PHM|HEB|JAS|1PE|2PE|1JN|2JN|3JN|JUD|REV|"
			-- The New Testament books in canonical order, for sorting by book code.

	links_where (a_condition: STRING_8; a_args: ARRAY [detachable ANY]; a_order: STRING_8): ARRAYED_LIST [like link_type]
			-- The links meeting `a_condition' with `a_args', in `a_order'.
		do
			create Result.make (4)
			run_query ("SELECT l.link_id, l.nt_book, l.nt_ch, l.nt_v_from, l.lxx_book, l.lxx_ch, l.lxx_v_from, l.kind, l.loudness, l.volume, "
				+ "u.title, u.book_class, l.en_book_id, l.en_ch, l.en_v, group_concat(w.witness || w.detail, ' ') AS witnesses FROM "
				+ pack_alias + ".incipit_link l JOIN " + pack_alias + ".source_unit u ON u.unit_id = l.unit_id JOIN "
				+ pack_alias + ".link_witness w ON w.link_id = l.link_id WHERE " + a_condition
				+ " GROUP BY l.link_id " + a_order, a_args)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					Result.extend ([ic.integer_value ("link_id"), ic.string_value ("nt_book"), ic.integer_value ("nt_ch"), ic.integer_value ("nt_v_from"),
						ic.string_value ("lxx_book"), ic.integer_value ("lxx_ch"), ic.integer_value ("lxx_v_from"), ic.string_value ("kind"),
						ic.string_value ("loudness"), ic.real_value ("volume"), ic.string_value ("title"), ic.string_value ("book_class"),
						ic.string_value ("witnesses"), ic.integer_value ("en_book_id"), ic.integer_value ("en_ch"), ic.integer_value ("en_v")])
				end
			end
		end

	query_failed_message: STRING_8 = "An incipit query failed."
	not_open_message: STRING_8 = "The incipit pack is not attached."

	pack_noun: STRING_32
		once
			Result := {STRING_32} "incipit pack"
		end

end
