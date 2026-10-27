note
	description: "[
		The commentary pack, version 1 (2026-10-27): ONE pack for every book Larry
		comments on (Larry: "later i will be adding other bible books"), the first generic private pack
		(spec fold 2026-10-26, debate 03 pathway B'), shaped with the COMMENTARY
		session for Larry's Jude commentary and tentatively approved by Larry the
		same day. The builder writes these tables and the reader reads them; this
		class is the one place they are named.

		THE PACK RULES IT KEEPS (BIB_PRIVATE_SOURCE checks them at attach):
		`user_version' 1; a `meta' table (pack_kind "commentary", title, status);
		`source_provenance' in the same file; every other table carries a
		NOT NULL `voice' and a NOT NULL `provenance_key'. A section's verses are
		kept as numbers and as hub ids (BIB_HUB_ID: English numbering), with its
		versification named.

		A CLAIM IS NEVER UNLABELED: `commentary_claim.label' is SOURCED (from
		Larry's writings, `source_ref' names where) or DEDUCED (reasoned from his
		frameworks, not his words); the window shows the label on every claim.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_COMMENTARY_SCHEMA

feature -- Constants

	Pack_kind: STRING_8 = "commentary"
			-- `meta.pack_kind' of a commentary pack.

	Pack_file_name: STRING_8 = "commentary.db"
			-- The one commentary pack's file in the packs folder.

	Pack_title: STRING_8 = "Larry Rix: Commentaries"

	Schema_version: INTEGER = 1
			-- The pack's `user_version' (BIB_PRIVATE_SOURCE.Pack_schema_version).

	Field_kinds: ARRAY [STRING_8]
			-- A section's fields, in the order the window shows them.
		once
			Result := <<"teaser", "text", "common_reading", "commentary", "variants">>
		end

	List_kinds: ARRAY [STRING_8]
			-- A section's lists.
		once
			Result := <<"framework", "question", "further_reading">>
		end

	Schema_statements: ARRAY [STRING_8]
			-- The tables of a new commentary pack, then its version.
		once
			Result := <<
				"CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT NOT NULL)",
				"CREATE TABLE source_provenance(provenance_key INTEGER PRIMARY KEY, source_key TEXT NOT NULL, edition TEXT NOT NULL, license_id TEXT NOT NULL, non_commercial INTEGER NOT NULL, share_alike INTEGER NOT NULL, restricted INTEGER NOT NULL, credit TEXT NOT NULL, caveat TEXT NOT NULL)",
				"CREATE TABLE commentary_book(book_id INTEGER PRIMARY KEY, title TEXT NOT NULL, status TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE commentary_section(section_id TEXT PRIMARY KEY, ordinal INTEGER NOT NULL, heading TEXT NOT NULL, start_book INTEGER NOT NULL, start_chapter INTEGER NOT NULL, start_verse INTEGER NOT NULL, end_book INTEGER NOT NULL, end_chapter INTEGER NOT NULL, end_verse INTEGER NOT NULL, start_hub INTEGER NOT NULL, end_hub INTEGER NOT NULL, versification TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE INDEX ix_commentary_section_hub ON commentary_section(start_hub, end_hub)",
				"CREATE TABLE commentary_field(section_id TEXT NOT NULL REFERENCES commentary_section(section_id), field_kind TEXT NOT NULL, ordinal INTEGER NOT NULL, body_markdown TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (section_id, field_kind))",
				"CREATE TABLE commentary_claim(claim_id TEXT NOT NULL, section_id TEXT NOT NULL REFERENCES commentary_section(section_id), field_kind TEXT NOT NULL, ordinal INTEGER NOT NULL, label TEXT NOT NULL CHECK (label IN ('SOURCED', 'DEDUCED')), claim_text TEXT NOT NULL, summary TEXT NOT NULL, source_ref TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (section_id, claim_id))",
				"CREATE TABLE commentary_term(section_id TEXT NOT NULL REFERENCES commentary_section(section_id), ordinal INTEGER NOT NULL, script TEXT NOT NULL, translit TEXT NOT NULL, pron TEXT NOT NULL, english TEXT NOT NULL, language TEXT NOT NULL, lemma_key TEXT NOT NULL, strongs TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (section_id, ordinal))",
				"CREATE TABLE commentary_list(section_id TEXT NOT NULL REFERENCES commentary_section(section_id), list_kind TEXT NOT NULL, ordinal INTEGER NOT NULL, item_markdown TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (section_id, list_kind, ordinal))",
				"CREATE TABLE commentary_restricted_quote(section_id TEXT NOT NULL REFERENCES commentary_section(section_id), ordinal INTEGER NOT NULL, source TEXT NOT NULL, ship_class TEXT NOT NULL, note TEXT NOT NULL, body_markdown TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (section_id, ordinal))",
				"PRAGMA user_version = 1">>
		end

end
