note
	description: "[
		Writes content.db v1 (research/18) from the vault's bible.db (Phase 4,
		Task 10): the book catalog with the vault ids (FR-105), its provenance row
		and the build row. It writes a temporary file, checks it with the engine's
		own content check (BIB_CONTENT_SOURCE), and only then replaces the output,
		so a failed build never leaves a broken content.db behind. The content
		pipeline (FR-130: core, AI-data and author-library stages) grows from here.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CONTENT_BUILDER

inherit
	BIB_SQLITE_REPORTING

create
	make

feature {NONE} -- Initialization

	make
			-- A builder with the default build id; the build time is taken at build.
		do
			create build_id.make_from_string ("content-v1")
			create built_at.make_empty
		ensure
			no_error: last_error = Void
		end

feature -- Access

	build_id: STRING_32
			-- The build row's id: the edition every method records.

	built_at: STRING_32
			-- The build row's time (ISO 8601); empty means "now, in UTC".

	books_written: INTEGER
			-- Books the last `build' wrote.

	versions_written: INTEGER
			-- Versions the last `build' wrote.

	verses_written: INTEGER

	verses_indexed: INTEGER
			-- Rows `verse_fts' holds after the last build.

	versification_rows_written: INTEGER
			-- Rows `versification_map' holds after the last build (0 without `tvtms_path').

	versification_rows_repeated: INTEGER
			-- Hebrew rows of the last build naming a verse an earlier row already mapped (the first
			-- row kept: TVTMS lists the MT's own row first).

	versification_rows_unplaced: INTEGER
			-- Hebrew rows of the last build that move a verse the reader could not place (a book
			-- outside the Hebrew Bible, a reference list).

	tvtms_path: STRING_32
			-- STEPBible's TVTMS file, read for `versification_map'; empty for none.
		attribute
			create Result.make_empty
		end

	verses_not_indexed: INTEGER
			-- Rows of `verse_text' the last build left out of the index (a heading as verse 0, or a
			-- number out of BIB_VERSE_KEY's range).
			-- Verses the last `build' wrote, across every version.

	cross_references_written: INTEGER
			-- Cross-references the last `build' wrote.

	last_error: detachable STRING_32
			-- Why the last `build' failed.

feature -- Settings

	set_build_id (a_id: READABLE_STRING_GENERAL)
			-- Use `a_id' as the build id.
		require
			id_not_empty: not a_id.is_empty
		do
			build_id := a_id.to_string_32
		ensure
			set: build_id.same_string_general (a_id)
		end

	set_tvtms_path (a_path: READABLE_STRING_GENERAL)
			-- Read the versification map from STEPBible's TVTMS file at `a_path' (D-005, research/04).
		do
			tvtms_path := a_path.to_string_32
		ensure
			set: tvtms_path.same_string_general (a_path)
		end

	set_built_at (a_time: READABLE_STRING_GENERAL)
			-- Record `a_time' as the build time, so a rebuild from the same inputs is byte-identical.
		do
			built_at := a_time.to_string_32
		ensure
			set: built_at.same_string_general (a_time)
		end

feature -- Building

	build (a_bible_db, a_out: READABLE_STRING_GENERAL)
			-- Write content.db v1 to `a_out' from the book list of `a_bible_db'.
		require
			bible_named: not a_bible_db.is_empty
			out_named: not a_out.is_empty
		local
			l_temp: STRING_32
			l_db: SIMPLE_SQL_DATABASE
		do
			last_error := Void
			books_written := 0
			versions_written := 0
			verses_written := 0
			verses_indexed := 0
			versification_rows_written := 0
			versification_rows_repeated := 0
			versification_rows_unplaced := 0
			verses_not_indexed := 0
			cross_references_written := 0
			if not (create {SIMPLE_FILE}.make (a_bible_db)).is_file then
				last_error := {STRING_32} "bible.db was not found: " + a_bible_db.to_string_32
			else
				l_temp := a_out.to_string_32 + {STRING_32} ".tmp"
				delete (l_temp)
				create l_db.make (l_temp)
				across Schema as ic loop
					run (l_db, ic)
				end
				if last_error = Void then
					l_db.attach_read_only (a_bible_db, "src")
					note_failure (l_db, "bible.db could not be attached")
				end
				run (l_db, "INSERT INTO source_provenance VALUES (1, 'bible.db bible_books', 'vault', 'public domain (book names and order)', 0, 0, 0, 'Book list from the vault bible.db', '')")
				run (l_db, "INSERT INTO book_catalog (book_id, code, name, is_deuterocanonical, provenance_key) SELECT id, abbreviation, name, 0, 1 FROM src.bible_books ORDER BY id")
					-- v2: every version's text, each version its own source row (research/18).
				run (l_db, Versions_provenance_sql)
				run (l_db, Version_info_sql)
				run (l_db, "INSERT INTO source_provenance VALUES (2, 'bible.db cross_references', 'OpenBible.info cross-references', 'CC BY', 0, 0, 0, 'Cross-reference data courtesy of OpenBible.info, CC BY.', 'Votes may be negative.')")
				run (l_db, "INSERT INTO cross_reference SELECT from_book_id, from_chapter, from_verse, to_book_id, to_chapter, to_verse_start, coalesce(to_verse_end, to_verse_start), coalesce(votes, 0), 2 FROM src.cross_references WHERE from_book_id BETWEEN 1 AND " + {BIB_CANON}.Last_book.out + " AND to_book_id BETWEEN 1 AND " + {BIB_CANON}.Last_book.out + " AND from_chapter > 0 AND from_verse > 0 AND to_chapter > 0 AND to_verse_start > 0 ORDER BY from_book_id, from_chapter, from_verse, votes DESC, to_book_id, to_chapter, to_verse_start")
				run (l_db, "CREATE INDEX cross_reference_from ON cross_reference(from_book, from_chapter, from_verse, votes)")
				run (l_db, "INSERT INTO verse_text SELECT v.abbreviation, b.book_id, b.chapter, b.verse, coalesce(b.text, ''), 100 + v.id FROM src.bible_verses b JOIN src.bible_versions v ON v.id = b.version_id ORDER BY v.abbreviation, b.book_id, b.chapter, b.verse")
				write_verse_index (l_db)
				if last_error = Void and not tvtms_path.is_empty then
					write_versification_map (l_db)
				end
				if last_error = Void then
					across l_db.query ("SELECT count(*) AS n FROM book_catalog").rows as ic loop
						books_written := ic.integer_value ("n")
					end
					across l_db.query ("SELECT count(*) AS n FROM version_info").rows as ic loop
						versions_written := ic.integer_value ("n")
					end
					across l_db.query ("SELECT count(*) AS n FROM verse_text").rows as ic loop
						verses_written := ic.integer_value ("n")
					end
					if verses_indexed + verses_not_indexed /= verses_written then
							-- Design scan 47: a short index is a failed build, not a quiet one.
						last_error := {STRING_32} "The verse index is short: " + verses_indexed.out + {STRING_32} " indexed and " + verses_not_indexed.out + {STRING_32} " left out of " + verses_written.out + {STRING_32} " verses."
					end
					across l_db.query ("SELECT count(*) AS n FROM cross_reference").rows as ic loop
						cross_references_written := ic.integer_value ("n")
					end
					l_db.detach ("src")
					note_failure (l_db, "bible.db could not be detached")
				end
				if last_error = Void then
					l_db.execute_with_args ("INSERT INTO build_run VALUES (?, ?, ?)", {ARRAY [detachable ANY]} <<build_id, build_time, Builder_name>>)
					note_failure (l_db, "The build row could not be written")
				end
				run (l_db, "PRAGMA user_version = " + {BIB_CONTENT_SOURCE}.Content_schema_version.out)
				l_db.close
				if last_error = Void then
					verify (l_temp)
				end
				if last_error = Void then
					replace (l_temp, a_out)
				else
					delete (l_temp)
				end
			end
		ensure
			built_or_reported: last_error = Void implies (create {SIMPLE_FILE}.make (a_out)).is_file
		end

feature -- Constants

	Builder_name: STRING = "bible_build 0.4.0"
			-- The build row's builder.

	Schema: ARRAY [STRING_8]
			-- content.db v1's tables (research/18).
		once
			Result := <<
				"CREATE TABLE source_provenance(provenance_key INTEGER PRIMARY KEY, source_key TEXT NOT NULL, edition TEXT NOT NULL, license_id TEXT NOT NULL, non_commercial INTEGER NOT NULL, share_alike INTEGER NOT NULL, restricted INTEGER NOT NULL, credit TEXT NOT NULL, caveat TEXT NOT NULL)",
				"CREATE TABLE build_run(build_id TEXT PRIMARY KEY, built_at TEXT NOT NULL, builder TEXT NOT NULL)",
				"CREATE TABLE book_catalog(book_id INTEGER PRIMARY KEY, code TEXT NOT NULL, name TEXT NOT NULL, is_deuterocanonical INTEGER NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE version_info(version_code TEXT PRIMARY KEY, name TEXT NOT NULL, language TEXT NOT NULL, direction TEXT NOT NULL, versification TEXT NOT NULL, caveat TEXT NOT NULL, sort_order INTEGER NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE cross_reference(from_book INTEGER NOT NULL, from_chapter INTEGER NOT NULL, from_verse INTEGER NOT NULL, to_book INTEGER NOT NULL, to_chapter INTEGER NOT NULL, to_verse_start INTEGER NOT NULL, to_verse_end INTEGER NOT NULL, votes INTEGER NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE versification_map(system TEXT NOT NULL, from_book INTEGER NOT NULL, from_chapter INTEGER NOT NULL, from_verse INTEGER NOT NULL, to_book INTEGER NOT NULL, to_chapter INTEGER NOT NULL, to_verse INTEGER NOT NULL, rule TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (system, from_book, from_chapter, from_verse)) WITHOUT ROWID",
				"CREATE TABLE verse_text(version_code TEXT NOT NULL, book_id INTEGER NOT NULL, chapter INTEGER NOT NULL, verse INTEGER NOT NULL, text TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (version_code, book_id, chapter, verse)) WITHOUT ROWID"
				>>
		end

	Versions_provenance_sql: STRING_8 = "INSERT INTO source_provenance SELECT 100 + v.id, 'bible.db bible_versions ' || v.abbreviation, v.name, coalesce(nullif(v.license, ''), 'unknown'), CASE WHEN coalesce(v.caveat, '') LIKE '%%BY-NC%%' THEN 1 ELSE 0 END, CASE WHEN coalesce(v.license, '') LIKE '%%SA%%' THEN 1 ELSE 0 END, CASE WHEN coalesce(v.license, '') LIKE 'personal%%' THEN 1 ELSE 0 END, v.name, coalesce(v.caveat, '') FROM src.bible_versions v ORDER BY v.id"
			-- One source row per version (keys 100 and up): the vault's licence and caveat as given
			-- (its licence column is not authoritative; the caveat says so), restricted when personal only.

	Version_info_sql: STRING_8
			-- (The numbering names come from BIB_NUMBERING, design scan 53.)
		once
			Result := "INSERT INTO version_info SELECT v.abbreviation, CASE v.abbreviation WHEN 'KJV' THEN 'King James Version (1769)' WHEN 'BSB' THEN 'Berean Standard Bible' WHEN 'ASV' THEN 'American Standard Version (1901)' WHEN 'YLT' THEN 'Young''s Literal Translation (1898)' WHEN 'WLC' THEN 'Hebrew: Westminster Leningrad Codex' WHEN 'MapM' THEN 'Hebrew: Miqra according to the Masorah' WHEN 'SP' THEN 'Samaritan Pentateuch' WHEN 'TR' THEN 'Greek NT: Textus Receptus (Scrivener)' WHEN 'Byz' THEN 'Greek NT: Byzantine (Robinson-Pierpont)' WHEN 'Peshitta' THEN 'Syriac NT: Peshitta' WHEN 'LXX' THEN 'Greek OT: Septuagint (Rahlfs)' WHEN 'TgO' THEN 'Aramaic: Targum Onkelos' WHEN 'TgJ' THEN 'Aramaic: Targum Jonathan' WHEN 'TgW' THEN 'Aramaic: Targum to the Writings' WHEN 'TgN' THEN 'Aramaic: Targum Neofiti' WHEN 'WH' THEN 'Greek NT: Westcott-Hort (1881)' WHEN 'Tyn' THEN 'Tyndale (1526 and 1530)' WHEN 'Wyc' THEN 'Wycliffe (about 1395, NT)' WHEN 'Vul' THEN 'Latin: Clementine Vulgate (NT)' WHEN 'NWT2013' THEN 'New World Translation (2013)' WHEN 'NWT1984' THEN 'New World Translation (1984)' ELSE v.name END, CASE WHEN v.abbreviation IN ('WLC', 'MapM', 'SP') THEN 'hbo' WHEN v.abbreviation IN ('TgO', 'TgJ', 'TgW', 'TgN') THEN 'arc' WHEN v.abbreviation = 'Peshitta' THEN 'syc' WHEN v.abbreviation IN ('LXX', 'TR', 'Byz', 'WH') THEN 'grc' WHEN v.abbreviation = 'Vul' THEN 'lat' ELSE 'eng' END, CASE WHEN v.abbreviation IN ('WLC', 'MapM', 'SP', 'TgO', 'TgJ', 'TgW', 'TgN', 'Peshitta') THEN 'rtl' ELSE 'ltr' END, CASE WHEN v.abbreviation IN ('WLC', 'MapM', 'SP', 'TgO', 'TgJ', 'TgW', 'TgN') THEN '" + {BIB_NUMBERING}.Hebrew + "' WHEN v.abbreviation = 'LXX' THEN '" + {BIB_NUMBERING}.Septuagint + "' WHEN v.abbreviation IN ('Vul', 'Wyc') THEN '" + {BIB_NUMBERING}.Vulgate + "' ELSE '" + {BIB_NUMBERING}.English + "' END, trim(CASE WHEN instr(coalesce(v.caveat, ''), '|| LICENSE COLUMN IS NOT AUTHORITATIVE') > 0 THEN substr(v.caveat, 1, instr(v.caveat, '|| LICENSE COLUMN IS NOT AUTHORITATIVE') - 1) ELSE coalesce(v.caveat, '') END), v.id, 100 + v.id FROM src.bible_versions v ORDER BY v.id"
		end
			-- Each version's reader-facing name, language, direction and numbering, from its vault code;
			-- the caveat without the vault's own bookkeeping clause (the source row keeps it whole).

feature {NONE} -- Implementation

	build_time: STRING_32
			-- `built_at', or now in UTC.
		do
			if built_at.is_empty then
				Result := (create {SIMPLE_DATE_TIME}.make_now_utc).to_iso8601_utc.to_string_32
			else
				Result := built_at
			end
		end

	write_verse_index (a_db: SIMPLE_SQL_DATABASE)
			-- `verse_fts': each verse's search form (D-009: one Eiffel normalizer per language; the
			-- query folds the same way), keyed by BIB_VERSE_KEY and contentless, so the
			-- display text is only ever read from `verse_text'. Rows go in batches of `Index_batch'.
		local
			l_normalizers: BIB_NORMALIZER_SET
			l_keys: BIB_VERSE_KEY
			l_versions: ARRAYED_LIST [TUPLE [code, language: STRING_8; order: INTEGER]]
			l_normalizer: BIB_NORMALIZER
			l_args: ARRAYED_LIST [detachable ANY]
		do
			run (a_db, Verse_index_sql)
			if last_error = Void then
				create l_normalizers.make (create {BIB_SIMPLE_UNICODE}.make)
				create l_keys
				create l_versions.make (24)
				across a_db.query ("SELECT version_code, language, sort_order FROM version_info ORDER BY sort_order").rows as ic loop
					l_versions.extend ([ic.string_value ("version_code").to_string_8, ic.string_value ("language").to_string_8, ic.integer_value ("sort_order")])
				end
				note_failure (a_db, "The versions could not be read for the verse index")
				run (a_db, "BEGIN")
				across l_versions as iv until last_error /= Void loop
					l_normalizer := l_normalizers.for_language (iv.language)
					create l_args.make (Index_batch * 2)
					across a_db.query_with_args ("SELECT book_id, chapter, verse, text FROM verse_text WHERE version_code = ?", {ARRAY [detachable ANY]} <<iv.code>>).rows as ic loop
						if l_keys.is_indexable (ic.integer_value ("book_id"), ic.integer_value ("chapter"), ic.integer_value ("verse")) then
							l_args.extend (l_keys.verse_key (iv.order, ic.integer_value ("book_id"), ic.integer_value ("chapter"), ic.integer_value ("verse")))
							l_args.extend (l_normalizer.normalized (ic.string_value ("text")))
							if l_args.count = Index_batch * 2 then
								insert_index_rows (a_db, l_args)
								l_args.wipe_out
							end
						else
							verses_not_indexed := verses_not_indexed + 1
						end
					end
					note_failure (a_db, "A version's verses could not be read for the verse index")
					if not l_args.is_empty then
						insert_index_rows (a_db, l_args)
					end
				end
				run (a_db, "COMMIT")
				run (a_db, "INSERT INTO verse_fts(verse_fts) VALUES ('optimize')")
				if last_error = Void then
					across a_db.query ("SELECT count(*) AS n FROM verse_fts").rows as ic loop
						verses_indexed := ic.integer_value ("n")
					end
				end
			end
		end

	write_versification_map (a_db: SIMPLE_SQL_DATABASE)
			-- `versification_map' from TVTMS's expanded section (STEPBible.org, CC BY 4.0): every row
			-- whose source tradition is Hebrew and whose action moves the verse (Renumber verse;
			-- Renumber title, a Psalm title read as verse 1, where English Bibles print it; a divided
			-- or merged verse to the first verse it names). Hebrew to the Standard (English, NRSV, KJV
			-- with three small differences). A row the reader cannot place is left out and counted.
		local
			l_lines: LIST [STRING_32]
			l_in_expanded, l_found_expanded: BOOLEAN
			l_fields: LIST [STRING_32]
			l_action: STRING_32
			l_from, l_to: detachable TUPLE [book, chapter, verse: INTEGER]
			l_keys: BIB_VERSE_KEY
			l_mapped: HASH_TABLE [BOOLEAN, INTEGER_64]
		do
			l_lines := (create {SIMPLE_FILE}.make (tvtms_path)).read_text_utf_8.split ('%N')
			create l_keys
			create l_mapped.make (2048)
			if l_lines.count < 3 then
				last_error := {STRING_32} "The TVTMS file could not be read: " + tvtms_path
			elseif not across l_lines as ic some ic.has_substring ({STRING_32} "#DataStart(Expanded)") end then
					-- Design scan 53: a file without it built an empty map and said nothing.
				last_error := {STRING_32} "The TVTMS file has no expanded section (#DataStart(Expanded)): " + tvtms_path
			else
				run (a_db, "INSERT INTO source_provenance VALUES (3, 'STEPBible TVTMS', 'STEPBible-Data Versification (TVTMS)', 'CC BY 4.0', 0, 0, 0, 'Versification mapping: STEPBible.org (Tyndale House, Cambridge), TVTMS, CC BY 4.0.', 'Hebrew to English (Standard) verse numbers only.')")
				run (a_db, "BEGIN")
				across l_lines as ic until last_error /= Void loop
					if ic.has_substring ({STRING_32} "#DataStart(Expanded)") then
						l_in_expanded := True
						l_found_expanded := True
					elseif ic.has_substring ({STRING_32} "#DataEnd(Expanded)") then
						l_in_expanded := False
					elseif l_in_expanded then
						l_fields := ic.split ('%T')
						if l_fields.count >= 4 and then across l_fields.first.split ('+') as jc some jc.same_string ({STRING_32} "Hebrew") end then
							l_action := l_fields.i_th (4).twin
							l_action.left_adjust
							l_action.right_adjust
							if across Moving_actions as jc some jc.same_string (l_action) end then
								l_from := tvtms_place (l_fields.i_th (2))
								l_to := tvtms_place (l_fields.i_th (3))
								if not attached l_from or not attached l_to then
									versification_rows_unplaced := versification_rows_unplaced + 1
								elseif attached l_from as al_from and then attached l_to as al_to and then (al_from.book /= al_to.book or al_from.chapter /= al_to.chapter or al_from.verse /= al_to.verse) then
									if l_mapped.has (l_keys.packed_place (al_from.book, al_from.chapter, al_from.verse)) then
										versification_rows_repeated := versification_rows_repeated + 1
									else
										l_mapped.force (True, l_keys.packed_place (al_from.book, al_from.chapter, al_from.verse))
										a_db.execute_with_args ("INSERT INTO versification_map VALUES ('" + {BIB_NUMBERING}.Hebrew + "', ?, ?, ?, ?, ?, ?, ?, 3)",
											{ARRAY [detachable ANY]} <<al_from.book, al_from.chapter, al_from.verse, al_to.book, al_to.chapter, al_to.verse, l_action>>)
										note_failure (a_db, "The versification map could not be written")
									end
								end
							end
						end
					end
				end
				if last_error = Void then
					run (a_db, "COMMIT")
				else
						-- Design scan 53: a failed insert left the transaction open.
					a_db.execute ("ROLLBACK")
				end
				if last_error = Void then
					across a_db.query ("SELECT count(*) AS n FROM versification_map").rows as ic loop
						versification_rows_written := ic.integer_value ("n")
					end
				end
			end
		end

	Moving_actions: ARRAY [STRING_32]
			-- The TVTMS actions that move a Hebrew verse to another English number.
		once
			Result := <<{STRING_32} "Renumber verse", {STRING_32} "Renumber title", {STRING_32} "DividedPrev verse", {STRING_32} "DividedNext verse", {STRING_32} "MergedPrev verse", {STRING_32} "MergedNext verse", {STRING_32} "Concatenation">>
		end

	tvtms_place (a_reference: STRING_32): detachable TUPLE [book, chapter, verse: INTEGER]
			-- The place a TVTMS reference names ("Mal.3:19", "Psa.3:Title" as verse 1, "1Sa.20:42!b" as
			-- 20:42, "Gen.2:25-3:1" as its first verse); Void for a book outside the Hebrew Bible or
			-- anything else (a list with ";").
		local
			l_text, l_book: STRING_32
			l_dot, l_colon, l_end, l_chapter, l_verse, l_id: INTEGER
		do
			l_text := a_reference.twin
			l_text.left_adjust
			l_text.right_adjust
			l_dot := l_text.index_of ('.', 1)
			l_colon := l_text.index_of (':', 1)
			if not l_text.has (';') and l_dot > 1 and l_colon > l_dot + 1 then
				l_book := l_text.substring (1, l_dot - 1)
				across Tvtms_books as ic until l_id > 0 loop
					if ic.code.same_string_general (l_book) then
						l_id := ic.book
					end
				end
				if l_text.substring (l_dot + 1, l_colon - 1).is_integer then
					l_chapter := l_text.substring (l_dot + 1, l_colon - 1).to_integer
				end
				from l_end := l_colon + 1 until l_end > l_text.count or else not l_text [l_end].is_digit loop
					l_end := l_end + 1
				end
				if l_text.substring (l_colon + 1, l_text.count).starts_with ({STRING_32} "Title") then
					l_verse := 1
				elseif l_end > l_colon + 1 then
					l_verse := l_text.substring (l_colon + 1, l_end - 1).to_integer
				end
				if l_id >= 1 and l_chapter >= 1 and l_chapter <= {BIB_PLACE_PACKING}.Max_part and l_verse >= 1 and l_verse <= {BIB_PLACE_PACKING}.Max_part then
					Result := [l_id, l_chapter, l_verse]
				end
			end
		end

	Tvtms_books: ARRAY [TUPLE [code: STRING_8; book: INTEGER]]
			-- TVTMS's code for each book of the Hebrew Bible with its book number, written in pairs so
			-- no pair can slip against another (design scan 53: a positional list held only by its count).
		once
			Result := <<["Gen", 1], ["Exo", 2], ["Lev", 3], ["Num", 4], ["Deu", 5], ["Jos", 6], ["Jdg", 7], ["Rut", 8], ["1Sa", 9], ["2Sa", 10],
				["1Ki", 11], ["2Ki", 12], ["1Ch", 13], ["2Ch", 14], ["Ezr", 15], ["Neh", 16], ["Est", 17], ["Job", 18], ["Psa", 19], ["Pro", 20],
				["Ecc", 21], ["Sng", 22], ["Isa", 23], ["Jer", 24], ["Lam", 25], ["Ezk", 26], ["Dan", 27], ["Hos", 28], ["Jol", 29], ["Amo", 30],
				["Oba", 31], ["Jon", 32], ["Mic", 33], ["Nam", 34], ["Hab", 35], ["Zep", 36], ["Hag", 37], ["Zec", 38], ["Mal", 39]>>
		ensure
			the_hebrew_bible: Result.count = {BIB_CANON}.Last_old_testament_book
			each_book_once: across Result as ic all ic.book = @ ic.cursor_index end
		end

	insert_index_rows (a_db: SIMPLE_SQL_DATABASE; a_args: ARRAYED_LIST [detachable ANY])
			-- One INSERT of the (key, search form) pairs in `a_args'.
		require
			pairs: a_args.count \\ 2 = 0 and not a_args.is_empty
		local
			l_sql: STRING_8
			i: INTEGER
		do
			if last_error = Void then
				create l_sql.make (40 + a_args.count * 4)
				l_sql.append ("INSERT INTO verse_fts(rowid, folded) VALUES ")
				from i := 1 until i > a_args.count // 2 loop
					if i > 1 then
						l_sql.append (", ")
					end
					l_sql.append ("(?, ?)")
					i := i + 1
				end
				a_db.execute_with_args (l_sql, a_args.to_array)
				note_failure (a_db, "The verse index could not be written")
			end
		end

	Verse_index_sql: STRING_8 = "CREATE VIRTUAL TABLE verse_fts USING fts5(folded, content='', tokenize='unicode61 remove_diacritics 2')"
			-- Contentless (spec 07: the shipped index is declared content='').

	Index_batch: INTEGER = 400
			-- Verses per INSERT.

	run (a_db: SIMPLE_SQL_DATABASE; a_sql: STRING_8)
			-- Execute `a_sql' unless an earlier step failed; keep the first failure (simple_sql clears
			-- its error at each call, so every step is checked as it runs).
		do
			if last_error = Void then
				a_db.execute (a_sql)
				note_failure (a_db, "A build step failed")
			end
		end

	note_failure (a_db: SIMPLE_SQL_DATABASE; a_what: STRING_8)
			-- Keep `a_db''s failure as `last_error' unless one is already kept.
		do
			if last_error = Void and a_db.has_error then
				last_error := failure_text (a_db, a_what)
			end
		end

	verify (a_temp: STRING_32)
			-- Check the written file with the engine's content check.
		local
			l_set: BIB_SOURCE_SET
			l_source: BIB_CONTENT_SOURCE
		do
			create l_set.make
			create l_source.make (a_temp)
			l_source.open_on (l_set)
			if attached l_source.last_error as al_error then
				last_error := {STRING_32} "The written content.db fails the engine's check: " + al_error.message
			else
				l_set.close
				l_source.close
			end
		end

	replace (a_temp: STRING_32; a_out: READABLE_STRING_GENERAL)
			-- Put the checked file at `a_out'. The previous content.db is set aside first and put
			-- back if the move fails, and the temporary file never stays behind (design scan 31:
			-- the old file was deleted before a move that could fail).
		local
			l_old: STRING_32
			l_set_aside, l_restored: BOOLEAN
		do
			l_old := a_out.to_string_32 + {STRING_32} ".old"
			delete (l_old)
			if (create {SIMPLE_FILE}.make (a_out)).is_file then
				l_set_aside := (create {SIMPLE_FILE}.make (a_out)).move_to (l_old)
				if not l_set_aside then
					last_error := {STRING_32} "The previous content.db could not be set aside: " + a_out.to_string_32
				end
			end
			if last_error = Void then
				if (create {SIMPLE_FILE}.make (a_temp)).move_to (a_out) then
					delete (l_old)
				else
					last_error := {STRING_32} "The built file could not be moved to " + a_out.to_string_32
					if l_set_aside then
						l_restored := (create {SIMPLE_FILE}.make (l_old)).move_to (a_out)
					end
				end
			end
			delete (a_temp)
		ensure
			no_temporary_file: not (create {SIMPLE_FILE}.make (a_temp)).is_file
		end

	delete (a_path: READABLE_STRING_GENERAL)
			-- Delete `a_path' if it is a file.
		local
			l_ok: BOOLEAN
			l_file: SIMPLE_FILE
		do
			create l_file.make (a_path)
			if l_file.is_file then
				l_ok := l_file.unlink
			end
		end

end
