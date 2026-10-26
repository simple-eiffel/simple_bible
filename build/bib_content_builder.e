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
			-- Verses the last `build' wrote, across every version.

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
				run (l_db, "INSERT INTO verse_text SELECT v.abbreviation, b.book_id, b.chapter, b.verse, coalesce(b.text, ''), 100 + v.id FROM src.bible_verses b JOIN src.bible_versions v ON v.id = b.version_id ORDER BY v.abbreviation, b.book_id, b.chapter, b.verse")
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

	Builder_name: STRING = "bible_build 0.2.0"
			-- The build row's builder.

	Schema: ARRAY [STRING_8]
			-- content.db v1's tables (research/18).
		once
			Result := <<
				"CREATE TABLE source_provenance(provenance_key INTEGER PRIMARY KEY, source_key TEXT NOT NULL, edition TEXT NOT NULL, license_id TEXT NOT NULL, non_commercial INTEGER NOT NULL, share_alike INTEGER NOT NULL, restricted INTEGER NOT NULL, credit TEXT NOT NULL, caveat TEXT NOT NULL)",
				"CREATE TABLE build_run(build_id TEXT PRIMARY KEY, built_at TEXT NOT NULL, builder TEXT NOT NULL)",
				"CREATE TABLE book_catalog(book_id INTEGER PRIMARY KEY, code TEXT NOT NULL, name TEXT NOT NULL, is_deuterocanonical INTEGER NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE version_info(version_code TEXT PRIMARY KEY, name TEXT NOT NULL, language TEXT NOT NULL, direction TEXT NOT NULL, versification TEXT NOT NULL, caveat TEXT NOT NULL, sort_order INTEGER NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE verse_text(version_code TEXT NOT NULL, book_id INTEGER NOT NULL, chapter INTEGER NOT NULL, verse INTEGER NOT NULL, text TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (version_code, book_id, chapter, verse)) WITHOUT ROWID"
				>>
		end

	Versions_provenance_sql: STRING_8 = "INSERT INTO source_provenance SELECT 100 + v.id, 'bible.db bible_versions ' || v.abbreviation, v.name, coalesce(nullif(v.license, ''), 'unknown'), CASE WHEN coalesce(v.caveat, '') LIKE '%%BY-NC%%' THEN 1 ELSE 0 END, CASE WHEN coalesce(v.license, '') LIKE '%%SA%%' THEN 1 ELSE 0 END, CASE WHEN coalesce(v.license, '') LIKE 'personal%%' THEN 1 ELSE 0 END, v.name, coalesce(v.caveat, '') FROM src.bible_versions v ORDER BY v.id"
			-- One source row per version (keys 100 and up): the vault's licence and caveat as given
			-- (its licence column is not authoritative; the caveat says so), restricted when personal only.

	Version_info_sql: STRING_8 = "INSERT INTO version_info SELECT v.abbreviation, CASE v.abbreviation WHEN 'KJV' THEN 'King James Version (1769)' WHEN 'BSB' THEN 'Berean Standard Bible' WHEN 'ASV' THEN 'American Standard Version (1901)' WHEN 'YLT' THEN 'Young''s Literal Translation (1898)' WHEN 'WLC' THEN 'Hebrew: Westminster Leningrad Codex' WHEN 'MapM' THEN 'Hebrew: Miqra according to the Masorah' WHEN 'SP' THEN 'Samaritan Pentateuch' WHEN 'TR' THEN 'Greek NT: Textus Receptus (Scrivener)' WHEN 'Byz' THEN 'Greek NT: Byzantine (Robinson-Pierpont)' WHEN 'Peshitta' THEN 'Syriac NT: Peshitta' WHEN 'LXX' THEN 'Greek OT: Septuagint (Rahlfs)' WHEN 'TgO' THEN 'Aramaic: Targum Onkelos' WHEN 'TgJ' THEN 'Aramaic: Targum Jonathan' WHEN 'TgW' THEN 'Aramaic: Targum to the Writings' WHEN 'TgN' THEN 'Aramaic: Targum Neofiti' WHEN 'WH' THEN 'Greek NT: Westcott-Hort (1881)' WHEN 'Tyn' THEN 'Tyndale (1526 and 1530)' WHEN 'Wyc' THEN 'Wycliffe (about 1395, NT)' WHEN 'Vul' THEN 'Latin: Clementine Vulgate (NT)' WHEN 'NWT2013' THEN 'New World Translation (2013)' WHEN 'NWT1984' THEN 'New World Translation (1984)' ELSE v.name END, CASE WHEN v.abbreviation IN ('WLC', 'MapM', 'SP') THEN 'hbo' WHEN v.abbreviation IN ('TgO', 'TgJ', 'TgW', 'TgN') THEN 'arc' WHEN v.abbreviation = 'Peshitta' THEN 'syc' WHEN v.abbreviation IN ('LXX', 'TR', 'Byz', 'WH') THEN 'grc' WHEN v.abbreviation = 'Vul' THEN 'lat' ELSE 'eng' END, CASE WHEN v.abbreviation IN ('WLC', 'MapM', 'SP', 'TgO', 'TgJ', 'TgW', 'TgN', 'Peshitta') THEN 'rtl' ELSE 'ltr' END, CASE WHEN v.abbreviation IN ('WLC', 'MapM', 'SP', 'TgO', 'TgJ', 'TgW', 'TgN') THEN 'hebrew' WHEN v.abbreviation = 'LXX' THEN 'lxx' WHEN v.abbreviation IN ('Vul', 'Wyc') THEN 'vulgate' ELSE 'kjv' END, trim(CASE WHEN instr(coalesce(v.caveat, ''), '|| LICENSE COLUMN IS NOT AUTHORITATIVE') > 0 THEN substr(v.caveat, 1, instr(v.caveat, '|| LICENSE COLUMN IS NOT AUTHORITATIVE') - 1) ELSE coalesce(v.caveat, '') END), v.id, 100 + v.id FROM src.bible_versions v ORDER BY v.id"
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
				last_error := a_what.to_string_32
				if attached a_db.last_error_message as al_message and attached last_error as al_text then
					al_text.append_string_general (": ")
					al_text.append (al_message)
				end
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
