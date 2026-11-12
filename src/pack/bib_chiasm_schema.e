note
	description: "[
		The chiasm pack, version 1 (research 28, 2026-11-11): the literary
		structures of a passage, first from E. W. Bullinger's Companion Bible
		(public domain, read from a scan), each graded against chance. A
		structure covers a range (KJV numbering, Bullinger's own and the
		reader's English) and holds members in reading order; an introversion's
		members pair from the outside in (A with the last A ...), and each pair
		keeps the rarity-weighted share of headwords its two members share. A
		nested level is a structure of its own under its parent member's letter.
		Built by `Builder_command'.

		Every table carries NOT NULL `voice' and `provenance_key' (the pack rules
		BIB_PRIVATE_SOURCE checks). Bullinger's rows are held loosely: they were
		read from a scanned page.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CHIASM_SCHEMA

inherit
	BIB_PRIVATE_PACK_SCHEMA
		redefine
			pack_license
		end

feature -- Constants

	Pack_kind: STRING_8 = "chiasm"
			-- `meta.pack_kind' of a chiasm pack.

	Pack_file_name: STRING_8 = "chiasm.db"
			-- The chiasm pack's file in the packs folder.

	Pack_title: STRING_8 = "Chiasms and Structures"

	Builder_command: STRING_8 = "bible_build --chiasm"

	Bullinger_name: STRING_8 = "Bullinger, The Companion Bible (1909-1922)"

	pack_license: BIB_LICENSE
			-- Public domain: Bullinger's structures (the book is from before 1930, the digital
			-- edition marked public domain); the grades are the author's own work.
		do
			create Result.make ("public domain", False, False, False, Bullinger_name + "; grades by " + Pack_author)
		ensure then
			not_restricted: not Result.is_restricted
		end

	Voice_loose: STRING_8 = "hold loosely (datum only)"
	Voice_author: STRING_8 = "author"
			-- Larry's own structures.
			-- Every row: Bullinger's read from a scan, the grades a measure's.

feature -- Vocabulary

	Patterns: ARRAY [STRING_8]
			-- How a level's members repeat: a mirror, a repeated sequence, or a frame (inclusio: the
			-- same words opening and closing a passage).
		once
			Result := <<"introversion", "alternation", "extended_alternation", "mixed", "inclusio">>
		end

	Sources: ARRAY [STRING_8]
			-- Who proposed a structure.
		once
			Result := <<"bullinger", "boys", "jebb", "forbes", "larry", "measure">>
		end

	Grades: ARRAY [STRING_8]
			-- A level against chance: strong (p < 0.01), moderate (p < 0.05), thematic (the pairs
			-- by idea, not by words), untestable, or not graded (not an introversion, or a member
			-- lost to the scan).
		once
			Result := <<"strong", "moderate", "thematic", "untestable", "not_graded">>
		end

	Repairs: ARRAY [STRING_8]
			-- How a member's reference was read: as printed, re-read to keep the members in
			-- order, or mended from a misread digit.
		once
			Result := <<"", "order", "ocr">>
		end

	Table_names: ARRAY [STRING_8]
			-- The pack's own tables, in the order they are made.
		once
			Result := <<"structure", "member">>
		end

feature -- Status

	is_pattern (a_word: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := has_word (Patterns, a_word)
		end

	is_source (a_word: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := has_word (Sources, a_word)
		end

	is_grade (a_word: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := has_word (Grades, a_word)
		end

	is_repair (a_word: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := has_word (Repairs, a_word)
		end

feature -- Tables

	pack_tables: ARRAY [STRING_8]
			-- The pack's own tables and indexes, in the order they are made.
		once
			Result := <<
				"CREATE TABLE structure(structure_id INTEGER PRIMARY KEY, parent_id INTEGER REFERENCES structure(structure_id), under_letter TEXT NOT NULL, book_id INTEGER NOT NULL CHECK (book_id BETWEEN 1 AND 66), ch_from INTEGER NOT NULL, v_from INTEGER NOT NULL, ch_to INTEGER NOT NULL, v_to INTEGER NOT NULL, title TEXT NOT NULL, kind_printed TEXT NOT NULL, pattern TEXT NOT NULL CHECK " + in_list ("pattern", Patterns) + ", source TEXT NOT NULL CHECK " + in_list ("source", Sources) + ", grade TEXT NOT NULL CHECK " + in_list ("grade", Grades) + ", whole REAL, p_shape REAL, p_pairing REAL, repaired INTEGER NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), CHECK (ch_from * 1000 + v_from <= ch_to * 1000 + v_to))",
				"CREATE INDEX structure_place ON structure(book_id, ch_from, v_from)",
				"CREATE TABLE member(structure_id INTEGER NOT NULL REFERENCES structure(structure_id), seq INTEGER NOT NULL, letter TEXT NOT NULL, letter_inferred INTEGER NOT NULL, ch_from INTEGER NOT NULL, v_from INTEGER NOT NULL, ch_to INTEGER NOT NULL, v_to INTEGER NOT NULL, label TEXT NOT NULL, pair_seq INTEGER, pair_score REAL, repair TEXT NOT NULL CHECK " + in_list ("repair", Repairs) + ", voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (structure_id, seq), CHECK (ch_from * 1000 + v_from <= ch_to * 1000 + v_to))">>
		ensure then
			every_table_made: across Table_names as al_t all across Result as al_s some al_s.starts_with ("CREATE TABLE " + al_t + "(") end end
			every_table_voiced: across Result as al_s all al_s.starts_with ("CREATE TABLE") implies (al_s.has_substring ("voice TEXT NOT NULL") and al_s.has_substring ("provenance_key INTEGER NOT NULL")) end
		end

end
