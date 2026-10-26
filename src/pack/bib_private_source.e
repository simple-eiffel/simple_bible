note
	description: "[
		A generic private data pack (2026-10-26 spec fold, debate 03 pathway B'):
		a versioned SQLite file in the public pack schema, found by the pack-folder
		scan and attached read-only through SIMPLE_SQL_DATABASE.attach_read_only.
		At attach its `user_version' and its NOT NULL voice column are checked, so
		a private result is never unlabeled. No private code: the public engine
		reads every pack with the same generic primitives. conc.db is not one: it
		is a concordance pack, opened by BIB_CONC_PACK's own check (settlement S6).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_PRIVATE_SOURCE

inherit
	BIB_DATA_SOURCE

create
	make

feature {NONE} -- Initialization

	make (a_path: READABLE_STRING_GENERAL; a_alias: READABLE_STRING_8; a_voice: BIB_VOICE)
			-- Describe the pack at `a_path', attached as `a_alias', its results labeled `a_voice'.
		require
			path_not_empty: not a_path.is_empty
			alias_not_empty: not a_alias.is_empty
			not_main: not a_alias.same_string ("main")
			not_concordance: not a_alias.same_string ({BIB_CONC_PACK}.Pack_alias)
		do
			path := a_path.to_string_32
			alias_text := a_alias.to_string_8
			voice := a_voice
			create sqlite_version.make_empty
		ensure
			path_set: path.same_string_general (a_path)
			alias_set: alias_name.same_string (a_alias)
			voice_set: voice = a_voice
			closed: not is_open
		end

feature -- Access

	alias_name: STRING_8
		do
			Result := alias_text
		end

	voice: BIB_VOICE
			-- How results from this pack are labeled.

	expected_schema_version: INTEGER
		do
			Result := Pack_schema_version
		end

feature -- Status

	pack_voice_column_present: BOOLEAN
			-- Does every pack table carry its NOT NULL voice column?
		do
			-- Phase 4: PRAGMA table_info over the pack's tables.
		end

feature -- Commands

	open_on (a_set: BIB_SOURCE_SET)
			-- Attach this pack to `a_set', read-only.
		do
			-- Phase 4: a_set.attach (alias_name, path); read user_version; check the voice column.
		ensure then
			voice_column_checked: is_open implies pack_voice_column_present
			user_version_checked: is_open implies schema_version = expected_schema_version
		end

	close
		do
			-- Phase 4
		end

feature -- Constants

	Pack_schema_version: INTEGER = 1

feature {NONE} -- Implementation

	alias_text: STRING_8

invariant
	not_main: not alias_text.same_string ("main")
	not_concordance: not alias_text.same_string ({BIB_CONC_PACK}.Pack_alias)

end
