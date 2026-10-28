note
	description: "[
		The frameworks pack, version 1 (2026-10-28): Larry's FRAMEWORKS(TM) rewritten
		for the common Christian reader (research/18-FRAMEWORKS-PACK-SIDECAR.md),
		one pack for all of them. The builder writes these tables and the reader
		reads them; this class is the one place they are named.

		THE PACK RULES IT KEEPS (BIB_PRIVATE_SOURCE checks them at attach):
		`user_version' 1; a `meta' table (pack_kind "frameworks", title);
		`source_provenance' in the same file; every other table carries a NOT NULL
		`voice' and a NOT NULL `provenance_key'.

		WHAT IT HOLDS: each framework (its name, whether prose marks it (TM), its
		full title, tier, review status and the hover text), the spellings that
		link to it, its plain-reader sections, the frameworks related to it, and
		where the commentary uses it (worked out at build time from the
		commentary pack's "Frameworks at work" lists, so it never goes stale).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_FRAMEWORK_SCHEMA

feature -- Constants

	Pack_kind: STRING_8 = "frameworks"
			-- `meta.pack_kind' of a frameworks pack.

	Pack_file_name: STRING_8 = "frameworks.db"
			-- The frameworks pack's file in the packs folder.

	Pack_title: STRING_8 = "Larry Rix: Frameworks"

	Schema_version: INTEGER = 1
			-- The pack's `user_version' (BIB_PRIVATE_SOURCE.Pack_schema_version).

	Max_hover: INTEGER = 280
			-- The most characters a hover text may hold.

	Min_sections: INTEGER = 3
			-- The sections every framework carries at least ("What it is", "Why it matters", "The
			-- question it asks of a passage").

	Tiers: ARRAY [STRING_8]
			-- A framework's tier, in the order the tool lists them: the JESUS Cornerstone, the
			-- cognitive bedrock (THMR, FOF), the master lenses, the recovery frameworks, the sub-tools.
		once
			Result := <<"cornerstone", "bedrock", "master", "recovery", "sub">>
		end

	Draft: STRING_8 = "draft"
	Reviewed: STRING_8 = "reviewed"
			-- A framework's `status': a draft until Larry approves it.

	tier_rank (a_tier: READABLE_STRING_GENERAL): INTEGER
			-- `a_tier''s place in `Tiers'; 0 for none.
		local
			i: INTEGER
		do
			from i := Tiers.lower until i > Tiers.upper or Result > 0 loop
				if Tiers [i].same_string_general (a_tier) then
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= Tiers.count
		end

	is_status (a_status: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_status' `Draft' or `Reviewed'?
		do
			Result := Draft.same_string_general (a_status) or Reviewed.same_string_general (a_status)
		end

	is_framework_id (a_id: READABLE_STRING_GENERAL): BOOLEAN
			-- Lowercase ASCII letters and digits, at least one: a `framework:' link target's id.
		do
			Result := not a_id.is_empty and then across a_id.to_string_32 as al_c all (al_c >= 'a' and al_c <= 'z') or (al_c >= '0' and al_c <= '9') end
		end

	Link_prefix: STRING_32 = "framework:"
			-- A link to a framework: "framework:kacc".

	Schema_statements: ARRAY [STRING_8]
			-- The tables of a new frameworks pack, then its version.
		once
			Result := <<
				"CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT NOT NULL)",
				"CREATE TABLE source_provenance(provenance_key INTEGER PRIMARY KEY, source_key TEXT NOT NULL, edition TEXT NOT NULL, license_id TEXT NOT NULL, non_commercial INTEGER NOT NULL, share_alike INTEGER NOT NULL, restricted INTEGER NOT NULL, credit TEXT NOT NULL, caveat TEXT NOT NULL)",
				"CREATE TABLE framework(framework_id TEXT PRIMARY KEY, name TEXT NOT NULL, mark INTEGER NOT NULL, title TEXT NOT NULL, tier TEXT NOT NULL, tier_rank INTEGER NOT NULL, status TEXT NOT NULL CHECK (status IN ('draft', 'reviewed')), hover TEXT NOT NULL, source TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE framework_alias(alias TEXT PRIMARY KEY, framework_id TEXT NOT NULL REFERENCES framework(framework_id), needs_mark INTEGER NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE framework_section(framework_id TEXT NOT NULL REFERENCES framework(framework_id), ordinal INTEGER NOT NULL, heading TEXT NOT NULL, body_markdown TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (framework_id, ordinal))",
				"CREATE TABLE framework_related(framework_id TEXT NOT NULL REFERENCES framework(framework_id), ordinal INTEGER NOT NULL, related_id TEXT NOT NULL REFERENCES framework(framework_id), voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (framework_id, ordinal))",
				"CREATE TABLE framework_use(framework_id TEXT NOT NULL REFERENCES framework(framework_id), ordinal INTEGER NOT NULL, section_id TEXT NOT NULL, heading TEXT NOT NULL, start_book INTEGER NOT NULL, start_chapter INTEGER NOT NULL, start_verse INTEGER NOT NULL, end_chapter INTEGER NOT NULL, end_verse INTEGER NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (framework_id, ordinal))",
				"PRAGMA user_version = 1">>
		end

end
