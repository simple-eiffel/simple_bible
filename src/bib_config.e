note
	description: "[
		Engine configuration (builder): the content.db path, the user store, the
		concordance pack (`conc_path'), the pack folder for generic private packs,
		the note export folder and the default version (exe-relative,
		%LOCALAPPDATA%, bible.toml, or portable). `make_from_separate' copies plain
		values for a worker processor's own SIMPLE_BIBLE. (2026-10-26 spec fold:
		the AI-data and author-library paths left with debate 01's single
		content.db; the plug-in registry left with debate 03.)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CONFIG

create
	make_with_core, make_default, make_portable, make_from_file, make_from_separate

feature {NONE} -- Initialization

	make_with_core (a_core_path: READABLE_STRING_GENERAL)
			-- Configuration naming content.db explicitly; other paths empty.
		require
			path_not_empty: not a_core_path.is_empty
		do
			init_empty
			core_path := a_core_path.to_string_32
		ensure
			core_set: core_path.same_string_general (a_core_path)
			valid: is_valid
		end

	make_default
			-- Paths from the executable folder, %LOCALAPPDATA%\simple_bible\ and bible.toml.
		do
			init_empty
			-- Phase 4: discovery.
		end

	make_portable
			-- Every path beside the executable; no registry writes (FR-NEW-021).
		do
			init_empty
			is_portable := True
			-- Phase 4: exe-relative paths.
		ensure
			portable: is_portable
		end

	make_from_file (a_toml_path: READABLE_STRING_GENERAL)
			-- Paths from a bible.toml file (simple_toml, Phase 4).
		require
			path_not_empty: not a_toml_path.is_empty
		do
			init_empty
		end

	make_from_separate (other: separate BIB_CONFIG)
			-- Copy of `other''s plain values for this processor.
		do
			create core_path.make_from_separate (other.core_path)
			create pack_folder.make_from_separate (other.pack_folder)
			create history_path.make_from_separate (other.history_path)
			create user_path.make_from_separate (other.user_path)
			create note_folder.make_from_separate (other.note_folder)
			create default_version.make_from_separate (other.default_version)
			create conc_path.make_from_separate (other.conc_path)
			is_portable := other.is_portable
		ensure
			core_copied: core_path.same_string (create {STRING_32}.make_from_separate (other.core_path))
			validity_kept: is_valid = other.is_valid
		end

	init_empty
		do
			create core_path.make_empty
			create pack_folder.make_empty
			create history_path.make_empty
			create user_path.make_empty
			create note_folder.make_empty
			create conc_path.make_empty
			default_version := "BSB"
		end

feature -- Access

	core_path: STRING_32
			-- The shipped content.db (the main database; the name is kept from the
			-- days of core.db, a Phase 4 choice per the folded contract spec).

	pack_folder: STRING_32
			-- Folder scanned for generic private packs, attached read-only at
			-- `open' (conc.db is not found here but by `conc_path': settlement G1).
			-- Name proposed by the 2026-10-26 fold; fixed in Phase 4.
	history_path: STRING_32
	user_path: STRING_32
	note_folder: STRING_32

	conc_path: STRING_32
			-- The concordance pack: conc.db (personal edition) or conc_dist.db
			-- (distribution edition). The edition swap is this one path; the
			-- engine never tests the edition (D-021, debate 05b). Empty: no pack.
	default_version: STRING_8

feature -- Status

	is_portable: BOOLEAN

	is_valid: BOOLEAN
		do
			Result := not core_path.is_empty
		ensure
			definition: Result = not core_path.is_empty
		end

feature -- Builder (returns Current for chaining; documented CQS exception)

	set_core_path (a_path: READABLE_STRING_GENERAL): like Current
		require
			path_not_empty: not a_path.is_empty
		do
			core_path := a_path.to_string_32
			Result := Current
		ensure
			set: core_path.same_string_general (a_path)
			others_unchanged: user_path ~ old user_path and conc_path ~ old conc_path
			result_is_current: Result = Current
		end

	set_pack_folder (a_path: READABLE_STRING_GENERAL): like Current
			-- Scan `a_path' for generic private packs at `open' (debate 03; name proposed by the fold).
		do
			pack_folder := a_path.to_string_32
			Result := Current
		ensure
			set: pack_folder.same_string_general (a_path)
			others_unchanged: core_path ~ old core_path and conc_path ~ old conc_path
			result_is_current: Result = Current
		end

	set_conc_path (a_path: READABLE_STRING_GENERAL): like Current
			-- Use `a_path' as the concordance pack (debate 05b).
		do
			conc_path := a_path.to_string_32
			Result := Current
		ensure
			set: conc_path.same_string_general (a_path)
			others_unchanged: core_path ~ old core_path and user_path ~ old user_path
			result_is_current: Result = Current
		end

	set_history_path (a_path: READABLE_STRING_GENERAL): like Current
		do
			history_path := a_path.to_string_32
			Result := Current
		ensure
			set: history_path.same_string_general (a_path)
			result_is_current: Result = Current
		end

	set_user_path (a_path: READABLE_STRING_GENERAL): like Current
		do
			user_path := a_path.to_string_32
			Result := Current
		ensure
			set: user_path.same_string_general (a_path)
			others_unchanged: core_path ~ old core_path and conc_path ~ old conc_path
			result_is_current: Result = Current
		end

	set_note_folder (a_path: READABLE_STRING_GENERAL): like Current
		do
			note_folder := a_path.to_string_32
			Result := Current
		ensure
			set: note_folder.same_string_general (a_path)
			result_is_current: Result = Current
		end

	set_default_version (a_code: READABLE_STRING_8): like Current
		require
			code_not_empty: not a_code.is_empty
		do
			default_version := a_code.to_string_8
			Result := Current
		ensure
			set: default_version.same_string (a_code)
			result_is_current: Result = Current
		end

end
