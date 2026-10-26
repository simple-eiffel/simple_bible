note
	description: "[
		A small conc-shaped pack, built by the tests (Phase 4, Task 2) and deleted
		after them; no conc.db data is ever committed. The tables copy conc.db's
		own definitions (read 2026-10-26) for the tables the engine reads, plus
		pack v1's additions (research/17): `token.translit', `lemma_corpus_count',
		`lemma_english' and `PRAGMA user_version' 1.

		It holds the shapes the Phase 2 review named: a Hebrew token with an empty
		surface (ruling 1.2, A1), an English token with the basis
		"computed:spacy-lemma", "tagged:<source>" bases, a Strong's row in
		`lemma_xref', corpora with `license' and `ship_class', and the Greek
		article with more than one page of places (paging). Words are ASCII
		stand-ins (no UTF-8 literals in Eiffel sources).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	CONC_FIXTURE

feature -- Building

	build (a_path: STRING)
			-- Write the fixture pack to `a_path' at the expected version with every table.
		do
			build_variant (a_path, Pack_version, "")
		end

	build_variant (a_path: STRING; a_version: INTEGER; a_omitted_table: STRING)
			-- Write the fixture pack to `a_path', stamped `a_version', without table
			-- `a_omitted_table' (none when empty): the refusal cases of FR-164.
		require
			path_not_empty: not a_path.is_empty
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			delete_file (a_path)
			create l_db.make (a_path)
			across schema as ic_table loop
				if not ic_table.table.same_string (a_omitted_table) then
					l_db.execute (ic_table.sql)
				end
			end
			across rows as ic_row loop
				if not ic_row.table.same_string (a_omitted_table) then
					l_db.execute (ic_row.sql)
				end
			end
			l_db.execute ("PRAGMA user_version = " + a_version.out)
			l_db.close
		ensure
			file_written: (create {RAW_FILE}.make_with_name (a_path)).exists
		end

	build_main (a_path: STRING)
			-- Write a stand-in content.db (table t holding one row) to `a_path', for a source set to open.
		require
			path_not_empty: not a_path.is_empty
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			delete_file (a_path)
			create l_db.make (a_path)
			l_db.execute ("CREATE TABLE t (id INTEGER PRIMARY KEY)")
			l_db.execute ("INSERT INTO t (id) VALUES (1)")
			l_db.close
		end

	build_content (a_path: STRING; a_version: INTEGER; a_without_provenance: BOOLEAN)
			-- content.db v1 (research/18) at `a_path', stamped `a_version'; with `a_without_provenance'
			-- the book catalog lacks its provenance column (the K7-A refusal).
		require
			path_not_empty: not a_path.is_empty
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			delete_file (a_path)
			create l_db.make (a_path)
			l_db.execute ("CREATE TABLE source_provenance(provenance_key INTEGER PRIMARY KEY, source_key TEXT NOT NULL, edition TEXT NOT NULL, license_id TEXT NOT NULL, non_commercial INTEGER NOT NULL, share_alike INTEGER NOT NULL, restricted INTEGER NOT NULL, credit TEXT NOT NULL, caveat TEXT NOT NULL)")
			l_db.execute ("CREATE TABLE build_run(build_id TEXT PRIMARY KEY, built_at TEXT NOT NULL, builder TEXT NOT NULL)")
			if a_without_provenance then
				l_db.execute ("CREATE TABLE book_catalog(book_id INTEGER PRIMARY KEY, code TEXT NOT NULL, name TEXT NOT NULL, is_deuterocanonical INTEGER NOT NULL)")
				l_db.execute ("INSERT INTO book_catalog VALUES (1, 'GEN', 'Genesis', 0)")
			else
				l_db.execute ("CREATE TABLE book_catalog(book_id INTEGER PRIMARY KEY, code TEXT NOT NULL, name TEXT NOT NULL, is_deuterocanonical INTEGER NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))")
				l_db.execute ("INSERT INTO book_catalog VALUES (1, 'GEN', 'Genesis', 0, 1)")
			end
			l_db.execute ("INSERT INTO source_provenance VALUES (1, 'test-books', 'fixture', 'CC0', 0, 0, 0, 'test fixture', '')")
			l_db.execute ("INSERT INTO build_run VALUES ('test-build-0', '2026-10-25T09:00:00', 'testing/conc_fixture.e'), ('" + Content_edition + "', '2026-10-26T12:00:00', 'testing/conc_fixture.e')")
			l_db.execute ("PRAGMA user_version = " + a_version.out)
			l_db.close
		ensure
			file_written: (create {SIMPLE_FILE}.make (a_path)).is_file
		end

	Content_version: INTEGER = 1
			-- content.db v1 (BIB_CONTENT_SOURCE.Content_schema_version).

	Content_edition: STRING = "test-build-1"
			-- The fixture content.db's latest build: its edition.

	delete_file (a_path: STRING)
			-- Delete `a_path' if present.
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_path)
			if l_file.exists then
				l_file.delete
			end
		end

feature -- Facts the tests check against

	Pack_version: INTEGER = 1
			-- The `user_version' of pack v1 (BIB_CONC_PACK.Expected_user_version).

	Create_lemma: INTEGER_64 = 1
			-- Hebrew "bara" (create): one place, Strong's H1254, one English link.

	Article_lemma: INTEGER_64 = 2
			-- The Greek article in the LXX: more places than one page holds.

	English_lemma: INTEGER_64 = 3
			-- English "create": basis "computed:spacy-lemma", no transliteration.

	Unwritten_lemma: INTEGER_64 = 4
			-- A Hebrew lemma whose one token has an empty surface (ruling 1.2).

	Article_places: INTEGER = 251
			-- Places of `Article_lemma': token 4, then tokens 1001 to 1250.

	Edition_label: STRING = "TEST FIXTURE - not for distribution"
			-- The fixture's `meta' edition_label (pack v1).

feature {NONE} -- Tables (conc.db's own definitions, plus pack v1)

	schema: ARRAYED_LIST [TUPLE [table: STRING; sql: STRING]]
			-- CREATE statement per table, in creation order.
		once
			create Result.make (12)
			Result.extend (["corpus", "CREATE TABLE corpus(corpus_id INTEGER PRIMARY KEY, code TEXT UNIQUE NOT NULL, name TEXT, language TEXT, script TEXT, edition TEXT, versification TEXT, source_name TEXT, source_url TEXT, source_commit TEXT, license TEXT, ship_class TEXT, lemma_basis TEXT, morph_scheme TEXT, notes TEXT)"])
			Result.extend (["work", "CREATE TABLE work(work_id INTEGER PRIMARY KEY, code TEXT UNIQUE NOT NULL, name TEXT, collection TEXT, sort_order INTEGER, notes TEXT)"])
			Result.extend (["work_book", "CREATE TABLE work_book(work_id INTEGER PRIMARY KEY, book_id INTEGER NOT NULL)"])
			Result.extend (["unit", "CREATE TABLE unit(unit_id INTEGER PRIMARY KEY, corpus_id INTEGER NOT NULL, work_id INTEGER NOT NULL, recension TEXT NOT NULL DEFAULT '', div1 TEXT, div2 TEXT, div3 TEXT NOT NULL DEFAULT '', seq INTEGER, UNIQUE(corpus_id, work_id, recension, div1, div2, div3))"])
			Result.extend (["lemma", "CREATE TABLE lemma(lemma_id INTEGER PRIMARY KEY, language TEXT NOT NULL, key TEXT NOT NULL, headword TEXT, search TEXT, pos TEXT, n_tokens INTEGER DEFAULT 0, translit TEXT, pron TEXT, pron_basis TEXT, UNIQUE(language, key))"])
			Result.extend (["token", "CREATE TABLE token(token_id INTEGER PRIMARY KEY, corpus_id INTEGER NOT NULL, unit_id INTEGER NOT NULL, pos INTEGER, surface TEXT, after TEXT, search TEXT, language TEXT, lemma_id INTEGER, lemma_basis TEXT, pos_tag TEXT, morph TEXT, stem TEXT, sense TEXT, translit TEXT)"])
			Result.extend (["link", "CREATE TABLE link(from_token INTEGER, to_token INTEGER, kind TEXT, source TEXT, method TEXT, PRIMARY KEY(from_token, to_token, kind))"])
			Result.extend (["lemma_xref", "CREATE TABLE lemma_xref(lemma_id INTEGER, scheme TEXT, value TEXT, n INTEGER, PRIMARY KEY(lemma_id, scheme, value))"])
			Result.extend (["meaning_source", "CREATE TABLE meaning_source(code TEXT PRIMARY KEY, name TEXT, year TEXT, kind TEXT, via TEXT, license TEXT, ship_class TEXT, url TEXT, credit TEXT)"])
			Result.extend (["lex_sense", "CREATE TABLE lex_sense(sense_id INTEGER PRIMARY KEY, lemma_id INTEGER NOT NULL, source TEXT NOT NULL, entry TEXT, seq INTEGER, label TEXT, depth INTEGER, gloss TEXT, text TEXT, page TEXT, basis TEXT, code TEXT, domain TEXT, forms TEXT, note TEXT, period TEXT)"])
			Result.extend (["lemma_corpus_count", "CREATE TABLE lemma_corpus_count(lemma_id INTEGER, corpus_id INTEGER, n INTEGER, PRIMARY KEY(lemma_id, corpus_id))"])
			Result.extend (["lemma_english", "CREATE TABLE lemma_english(lemma_id INTEGER, corpus_id INTEGER, english TEXT, n INTEGER, PRIMARY KEY(lemma_id, corpus_id, english))"])
			Result.extend (["meta", "CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT)"])
		end

	rows: ARRAYED_LIST [TUPLE [table: STRING; sql: STRING]]
			-- INSERT statements, each tagged with its table.
		once
			create Result.make (16)
			Result.extend (["corpus", "INSERT INTO corpus(corpus_id, code, name, language, license, ship_class, lemma_basis) VALUES (1, 'WLC-MACULA', 'Hebrew Bible', 'hbo+arc', 'CC BY 4.0', 'attribution', 'tagged: MACULA Hebrew lemma'), (4, 'LXX-RAHLFS', 'Septuagint', 'grc', 'non-commercial with a signed declaration', 'restricted_nc (RESEARCH ONLY)', 'tagged: CATSS lemma'), (5, 'ENG-BSB', 'Berean Standard Bible', 'eng', 'public domain', 'VERIFY', 'computed:lowercase-form')"])
			Result.extend (["work", "INSERT INTO work(work_id, code, name, sort_order) VALUES (1, 'GEN', 'Genesis', 1)"])
			Result.extend (["work_book", "INSERT INTO work_book(work_id, book_id) VALUES (1, 1)"])
			Result.extend (["unit", "INSERT INTO unit(unit_id, corpus_id, work_id, div1, div2, seq) VALUES (1, 1, 1, '1', '1', 1), (2, 5, 1, '1', '1', 1), (3, 4, 1, '1', '1', 1)"])
			Result.extend (["unit", "INSERT INTO unit(unit_id, corpus_id, work_id, div1, div2, seq) WITH RECURSIVE c(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM c WHERE n < 250) SELECT 100 + n, 4, 1, '2', CAST(n AS TEXT), 1 + n FROM c"])
			Result.extend (["lemma", "INSERT INTO lemma(lemma_id, language, key, headword, search, pos, n_tokens, translit, pron) VALUES (1, 'hbo', 'bara', 'BRA', 'bra', 'verb', 1, 'bara', 'baw-RAW'), (2, 'grc', 'ho', 'HO', 'o', 'article', 251, 'ho', 'HO'), (3, 'eng', 'create', 'create', 'create', 'verb', 1, '', ''), (4, 'hbo', 'et', 'ET', 'et', 'particle', 1, 'et', 'ET')"])
			Result.extend (["token", "INSERT INTO token(token_id, corpus_id, unit_id, pos, surface, search, language, lemma_id, lemma_basis, translit) VALUES (1, 1, 1, 1, 'BRA', 'bra', 'hbo', 1, 'tagged:MACULA-Hebrew', 'bara'), (2, 1, 1, 2, '', '', 'hbo', 4, 'tagged:MACULA-Hebrew', ''), (3, 5, 2, 1, 'created', 'created', 'eng', 3, 'computed:spacy-lemma', ''), (4, 4, 3, 1, 'HO', 'o', 'grc', 2, 'tagged:CATSS', 'ho')"])
			Result.extend (["token", "INSERT INTO token(token_id, corpus_id, unit_id, pos, surface, language, lemma_id, lemma_basis, translit) WITH RECURSIVE c(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM c WHERE n < 250) SELECT 1000 + n, 4, 100 + n, 1, 'HO', 'grc', 2, 'tagged:CATSS', 'ho' FROM c"])
			Result.extend (["link", "INSERT INTO link(from_token, to_token, kind, source, method) VALUES (1, 3, 'translation:ENG-BSB', 'BSB translation tables', 'fixture')"])
			Result.extend (["lemma_xref", "INSERT INTO lemma_xref(lemma_id, scheme, value, n) VALUES (1, 'strongs', 'H1254', 1), (2, 'strongs', 'G3588', 251)"])
			Result.extend (["meaning_source", "INSERT INTO meaning_source(code, name, year, kind, license, ship_class) VALUES ('SDBH', 'Semantic Dictionary of Biblical Hebrew', '2026', 'lexicon', 'CC BY-SA 4.0', 'open')"])
			Result.extend (["lex_sense", "INSERT INTO lex_sense(sense_id, lemma_id, source, entry, seq, label, depth, gloss, text) VALUES (1, 1, 'SDBH', 'bara', 1, '1', 0, 'create', 'to bring into being')"])
			Result.extend (["lemma_corpus_count", "INSERT INTO lemma_corpus_count(lemma_id, corpus_id, n) VALUES (1, 1, 1), (4, 1, 1), (2, 4, 251), (3, 5, 1)"])
			Result.extend (["lemma_english", "INSERT INTO lemma_english(lemma_id, corpus_id, english, n) VALUES (1, 5, 'created', 1)"])
			Result.extend (["meta", "INSERT INTO meta(key, value) VALUES ('edition_label', '" + Edition_label + "'), ('builder', 'testing/conc_fixture.e')"])
		end

end
