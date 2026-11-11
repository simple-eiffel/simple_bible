note
	description: "[
		The incipit pack, version 1 (research 27, 2026-11-11): where the New
		Testament draws on the Old. Each link joins a New Testament range to an
		LXX range (LXX numbering is the key; Larry, 2026-11-11) and carries its
		kind, its measured volume, its loudness against the chance lines, the
		text its wording follows, its witnesses and the words the two sides
		share. Links point into whole source passages (Psalm 22, not 22:1);
		scenes gather what one New Testament passage takes from one source;
		stories tell the source, the scene and the forward use, each section
		labeled with whose words it holds. Built by `Builder_command'.

		The license is mixed: the UBS Parallel Passages rows are CC BY-SA 4.0,
		so the pack carries share-alike; the nineteenth-century lists are public
		domain; the stories are Larry's own work. Each row names its source by
		`provenance_key'.

		Every closed list a column takes (kinds, loudness, witnesses, statuses)
		is written once, below, and the CHECK constraints are built from it.
		Every table carries NOT NULL `voice' and `provenance_key' (the pack
		rules BIB_PRIVATE_SOURCE checks): UBS rows are trusted, rows read from
		a scan and the measure's scores are held loosely, Larry's words are
		the author's.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_INCIPIT_SCHEMA

inherit
	BIB_PRIVATE_PACK_SCHEMA
		redefine
			pack_license
		end

feature -- Constants

	Pack_kind: STRING_8 = "incipit"
			-- `meta.pack_kind' of an incipit pack.

	Pack_file_name: STRING_8 = "incipit.db"
			-- The incipit pack's file in the packs folder.

	Pack_title: STRING_8 = "The Old Testament in the New"

	Builder_command: STRING_8 = "bible_build --incipit"

	Ubs_source_name: STRING_8 = "UBS Paratext Parallel Passages"

	pack_license: BIB_LICENSE
			-- CC BY-SA 4.0: the share-alike terms of the UBS rows the links are built from.
		do
			create Result.make ("CC BY-SA 4.0", False, True, False, Ubs_source_name + " (United Bible Societies); stories by " + Pack_author)
		ensure then
			share_alike: Result.is_share_alike
			not_restricted: not Result.is_restricted
		end

feature -- Vocabulary

	Kinds: ARRAY [STRING_8]
			-- What a link can be: the declared tests of `link_kind'.
		once
			Result := <<"incipit", "quotation", "allusion", "echo", "word_link", "motif">>
		end

	Mark_styles: ARRAY [STRING_8]
			-- How a kind is marked in the reading text.
		once
			Result := <<"solid", "dotted", "faint">>
		end

	Loudness_levels: ARRAY [STRING_8]
			-- A link's volume against the chance lines: above 99.9%, 99%, 95%, or below (a theme).
		once
			Result := <<"loud", "clear", "quiet", "theme">>
		end

	Followed_texts: ARRAY [STRING_8]
			-- The text a link's New Testament wording follows.
		once
			Result := <<"lxx", "hebrew", "both", "unknown">>
		end

	Witnesses: ARRAY [STRING_8]
			-- Who can name a link.
		once
			Result := <<"ubs", "huhn", "dittmar", "openbible", "shape", "larry", "measure">>
		end

	Book_classes: ARRAY [STRING_8]
			-- Where a source passage's book stands: in the Hebrew canon, in the LXX only, outside both.
		once
			Result := <<"hebrew_canon", "lxx_only", "outside">>
		end

	Features: ARRAY [STRING_8]
			-- The measure's features kept as evidence for a scored link.
		once
			Result := <<"align", "lex", "form", "run", "share", "rare", "dist">>
		end

	Story_kinds: ARRAY [STRING_8]
			-- The written stories: the source passage, one scene's use, the forward use.
		once
			Result := <<"source", "scene", "forward">>
		end

	Section_statuses: ARRAY [STRING_8]
			-- Whose words a story section holds.
		once
			Result := <<"larry_posted", "larry_framework", "larry_draft", "larry_approved", "claude_take">>
		end

	Sides: ARRAY [STRING_8]
			-- The two sides of a link whose shared words are kept.
		once
			Result := <<"nt", "lxx">>
		end

	Voice_trusted: STRING_8 = "trusted"
	Voice_loose: STRING_8 = "hold loosely (datum only)"
	Voice_author: STRING_8 = "author"
			-- The voices BIB_VOICE names, as a row carries them.

	Book_codes: ARRAY [STRING_8]
			-- The 66 books' codes in content.db's book order (book_id 1 = GEN ... 66 = REV), as the
			-- links name them.
		once
			Result := <<"GEN", "EXO", "LEV", "NUM", "DEU", "JOS", "JDG", "RUT", "1SA", "2SA", "1KI", "2KI", "1CH", "2CH", "EZR", "NEH",
				"EST", "JOB", "PSA", "PRO", "ECC", "SNG", "ISA", "JER", "LAM", "EZK", "DAN", "HOS", "JOL", "AMO", "OBA", "JON",
				"MIC", "NAM", "HAB", "ZEP", "HAG", "ZEC", "MAL", "MAT", "MRK", "LUK", "JHN", "ACT", "ROM", "1CO", "2CO", "GAL",
				"EPH", "PHP", "COL", "1TH", "2TH", "1TI", "2TI", "TIT", "PHM", "HEB", "JAS", "1PE", "2PE", "1JN", "2JN", "3JN",
				"JUD", "REV">>
		ensure
			sixty_six: Result.count = 66 and Result.lower = 1
		end

	Table_names: ARRAY [STRING_8]
			-- The pack's own tables, in the order they are made.
		once
			Result := <<"link_kind", "source_unit", "measure_run", "incipit_link", "link_witness", "link_word",
				"link_feature", "scene", "story", "story_section">>
		end

feature -- Status

	is_kind (a_word: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_word' one of the declared `Kinds'?
		do
			Result := has_word (Kinds, a_word)
		end

	is_loudness (a_word: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_word' one of the `Loudness_levels'?
		do
			Result := has_word (Loudness_levels, a_word)
		end

	is_section_status (a_word: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_word' one of the `Section_statuses'?
		do
			Result := has_word (Section_statuses, a_word)
		end

feature -- Tables

	pack_tables: ARRAY [STRING_8]
			-- The pack's own tables and indexes, in the order they are made.
		once
			Result := <<
				"CREATE TABLE link_kind(kind TEXT PRIMARY KEY CHECK " + in_list ("kind", Kinds) + ", label TEXT NOT NULL, definition_formal TEXT NOT NULL, could_fail_if TEXT NOT NULL, mark_style TEXT NOT NULL CHECK " + in_list ("mark_style", Mark_styles) + ", voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE source_unit(unit_id INTEGER PRIMARY KEY, lxx_book TEXT NOT NULL, lxx_ch_from INTEGER NOT NULL, lxx_v_from INTEGER NOT NULL, lxx_ch_to INTEGER NOT NULL, lxx_v_to INTEGER NOT NULL, hebrew_ref TEXT NOT NULL, english_ref TEXT NOT NULL, title TEXT NOT NULL, book_class TEXT NOT NULL CHECK " + in_list ("book_class", Book_classes) + ", provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), voice TEXT NOT NULL)",
				"CREATE TABLE measure_run(run_id INTEGER PRIMARY KEY, measure_version TEXT NOT NULL, run_on TEXT NOT NULL, nt_edition TEXT NOT NULL, lxx_edition TEXT NOT NULL, candidates INTEGER NOT NULL, chance_95 REAL NOT NULL, chance_99 REAL NOT NULL, chance_999 REAL NOT NULL, method TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), CHECK (chance_95 <= chance_99 AND chance_99 <= chance_999))",
				"CREATE TABLE incipit_link(link_id INTEGER PRIMARY KEY, nt_book TEXT NOT NULL, nt_ch INTEGER NOT NULL, nt_v_from INTEGER NOT NULL, nt_v_to INTEGER NOT NULL, lxx_book TEXT NOT NULL, lxx_ch INTEGER NOT NULL, lxx_v_from INTEGER NOT NULL, lxx_v_to INTEGER NOT NULL, unit_id INTEGER NOT NULL REFERENCES source_unit(unit_id), kind TEXT NOT NULL REFERENCES link_kind(kind), volume REAL NOT NULL CHECK (volume >= 0), loudness TEXT NOT NULL CHECK " + in_list ("loudness", Loudness_levels) + ", follows TEXT NOT NULL CHECK " + in_list ("follows", Followed_texts) + ", run_id INTEGER REFERENCES measure_run(run_id), en_book_id INTEGER CHECK (en_book_id IS NULL OR en_book_id BETWEEN 1 AND 66), en_ch INTEGER, en_v INTEGER, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), voice TEXT NOT NULL, CHECK (nt_v_from <= nt_v_to AND lxx_v_from <= lxx_v_to))",
				"CREATE INDEX incipit_link_nt ON incipit_link(nt_book, nt_ch, nt_v_from)",
				"CREATE INDEX incipit_link_lxx ON incipit_link(lxx_book, lxx_ch, lxx_v_from)",
				"CREATE INDEX incipit_link_en ON incipit_link(en_book_id, en_ch, en_v)",
				"CREATE TABLE link_witness(link_id INTEGER NOT NULL REFERENCES incipit_link(link_id), witness TEXT NOT NULL CHECK " + in_list ("witness", Witnesses) + ", detail TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), voice TEXT NOT NULL, PRIMARY KEY (link_id, witness, detail))",
				"CREATE TABLE link_word(link_id INTEGER NOT NULL REFERENCES incipit_link(link_id), side TEXT NOT NULL CHECK " + in_list ("side", Sides) + ", seq INTEGER NOT NULL, surface TEXT NOT NULL, headword TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (link_id, side, seq))",
				"CREATE TABLE link_feature(link_id INTEGER NOT NULL REFERENCES incipit_link(link_id), feature TEXT NOT NULL CHECK " + in_list ("feature", Features) + ", value REAL NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (link_id, feature))",
				"CREATE TABLE scene(scene_id INTEGER PRIMARY KEY, unit_id INTEGER NOT NULL REFERENCES source_unit(unit_id), nt_book TEXT NOT NULL, nt_ch_from INTEGER NOT NULL, nt_v_from INTEGER NOT NULL, nt_ch_to INTEGER NOT NULL, nt_v_to INTEGER NOT NULL, title TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE story(story_id INTEGER PRIMARY KEY, unit_id INTEGER NOT NULL REFERENCES source_unit(unit_id), scene_id INTEGER REFERENCES scene(scene_id), story_kind TEXT NOT NULL CHECK " + in_list ("story_kind", Story_kinds) + ", title TEXT NOT NULL, vault_path TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), CHECK ((story_kind = 'scene') = (scene_id IS NOT NULL)))",
				"CREATE TABLE story_section(story_id INTEGER NOT NULL REFERENCES story(story_id), seq INTEGER NOT NULL, heading TEXT NOT NULL, body TEXT NOT NULL, status TEXT NOT NULL CHECK " + in_list ("status", Section_statuses) + ", sources TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (story_id, seq))">>
		ensure then
			every_table_made: across Table_names as al_t all across Result as al_s some al_s.starts_with ("CREATE TABLE " + al_t + "(") end end
			every_table_voiced: across Result as al_s all al_s.starts_with ("CREATE TABLE") implies (al_s.has_substring ("voice TEXT NOT NULL") and al_s.has_substring ("provenance_key INTEGER NOT NULL")) end
		end

feature {NONE} -- Implementation

	has_word (a_words: ARRAY [STRING_8]; a_word: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_word' one of `a_words'?
		do
			Result := across a_words as al_w some al_w.same_string_general (a_word) end
		end

	in_list (a_column: STRING_8; a_words: ARRAY [STRING_8]): STRING_8
			-- "(`a_column' IN ('w1', 'w2', ...))" for a CHECK constraint.
		require
			words_given: not a_words.is_empty
			plain_words: across a_words as al_w all not al_w.has ('%'') end
		do
			create Result.make (64)
			Result.append ("(" + a_column + " IN (")
			across a_words as al_w loop
				if Result.item (Result.count) /= '(' then
					Result.append (", ")
				end
				Result.append ("'" + al_w + "'")
			end
			Result.append ("))")
		ensure
			names_column: Result.starts_with ("(" + a_column + " IN (")
		end

end
