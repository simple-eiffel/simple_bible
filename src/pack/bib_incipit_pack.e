note
	description: "[
		An incipit pack, read (BIB_INCIPIT_SCHEMA; research 27, 2026-11-11):
		the links a New Testament verse makes into the Old (LXX numbering), the
		links an LXX verse receives, and the source unit a link points into.
		Each link comes with its kind, loudness, volume and witnesses, loudest
		first. Attached read-only under `pack_alias' by BIB_PRIVATE_SOURCE.
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
			Result := links_where ("l.nt_book = ? AND l.nt_ch = ? AND ? BETWEEN l.nt_v_from AND l.nt_v_to", a_nt_book, a_ch, a_v)
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
			Result := links_where ("l.lxx_book = ? AND l.lxx_ch = ? AND ? BETWEEN l.lxx_v_from AND l.lxx_v_to", a_lxx_book, a_ch, a_v)
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
			Result := links_where ("l.en_book_id = ? AND l.en_ch = ? AND l.en_v = ?", a_book_id, a_ch, a_v)
		ensure
			loudest_first: across 2 |..| Result.count as i all Result [i - 1].volume >= Result [i].volume end
			into_that_verse: across Result as al_l all al_l.en_book_id = a_book_id and al_l.en_ch = a_ch and al_l.en_v = a_v end
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

	links_where (a_condition: STRING_8; a_book: ANY; a_ch, a_v: INTEGER): ARRAYED_LIST [like link_type]
			-- The links meeting `a_condition' (three parameters: book, chapter, verse), loudest first.
		do
			create Result.make (4)
			run_query ("SELECT l.link_id, l.nt_book, l.nt_ch, l.nt_v_from, l.lxx_book, l.lxx_ch, l.lxx_v_from, l.kind, l.loudness, l.volume, "
				+ "u.title, u.book_class, l.en_book_id, l.en_ch, l.en_v, group_concat(w.witness || w.detail, ' ') AS witnesses FROM "
				+ pack_alias + ".incipit_link l JOIN " + pack_alias + ".source_unit u ON u.unit_id = l.unit_id JOIN "
				+ pack_alias + ".link_witness w ON w.link_id = l.link_id WHERE " + a_condition
				+ " GROUP BY l.link_id ORDER BY l.volume DESC, l.link_id", {ARRAY [detachable ANY]} <<book_argument (a_book), a_ch, a_v>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					Result.extend ([ic.integer_value ("link_id"), ic.string_value ("nt_book"), ic.integer_value ("nt_ch"), ic.integer_value ("nt_v_from"),
						ic.string_value ("lxx_book"), ic.integer_value ("lxx_ch"), ic.integer_value ("lxx_v_from"), ic.string_value ("kind"),
						ic.string_value ("loudness"), ic.real_value ("volume"), ic.string_value ("title"), ic.string_value ("book_class"),
						ic.string_value ("witnesses"), ic.integer_value ("en_book_id"), ic.integer_value ("en_ch"), ic.integer_value ("en_v")])
				end
			end
		end

	book_argument (a_book: ANY): detachable ANY
			-- A book code as STRING_32, a book number as itself.
		do
			if attached {READABLE_STRING_GENERAL} a_book as al_code then
				Result := al_code.to_string_32
			else
				Result := a_book
			end
		end

	query_failed_message: STRING_8 = "An incipit query failed."
	not_open_message: STRING_8 = "The incipit pack is not attached."

	pack_noun: STRING_32
		once
			Result := {STRING_32} "incipit pack"
		end

end
