note
	description: "[
		Engine configuration (builder): database paths (exe-relative,
		%LOCALAPPDATA%, bible.toml, or portable), note folder, default version and
		the plug-in registry. `make_from_separate' copies plain values for a
		worker processor's own SIMPLE_BIBLE.
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
			-- Configuration naming core.db explicitly; other paths empty.
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
			-- Copy of `other''s plain values for this processor. Plug-ins are not copied:
			-- a private build registers its plug-ins on each processor.
		do
			create core_path.make_from_separate (other.core_path)
			create ai_data_path.make_from_separate (other.ai_data_path)
			create rix_path.make_from_separate (other.rix_path)
			create history_path.make_from_separate (other.history_path)
			create user_path.make_from_separate (other.user_path)
			create note_folder.make_from_separate (other.note_folder)
			create default_version.make_from_separate (other.default_version)
			is_portable := other.is_portable
			create plugin_registry.make
		ensure
			core_copied: core_path.same_string (create {STRING_32}.make_from_separate (other.core_path))
			validity_kept: is_valid = other.is_valid
			no_plugins: plugin_registry.plugin_count = 0
		end

	init_empty
		do
			create core_path.make_empty
			create ai_data_path.make_empty
			create rix_path.make_empty
			create history_path.make_empty
			create user_path.make_empty
			create note_folder.make_empty
			default_version := "BSB"
			create plugin_registry.make
		end

feature -- Access

	core_path: STRING_32
	ai_data_path: STRING_32
	rix_path: STRING_32
	history_path: STRING_32
	user_path: STRING_32
	note_folder: STRING_32
	default_version: STRING_8
	plugin_registry: BIB_PLUGIN_REGISTRY

feature -- Status

	is_portable: BOOLEAN

	is_valid: BOOLEAN
		do
			Result := not core_path.is_empty
		ensure
			definition: Result = not core_path.is_empty
		end

	ai_data_present: BOOLEAN
			-- Is ai_data.db configured and present?
		do
			-- Phase 4: not ai_data_path.is_empty and the file exists.
		ensure
			configured: Result implies not ai_data_path.is_empty
		end

	rix_present: BOOLEAN
			-- Is rix.db configured and present?
		do
			-- Phase 4
		ensure
			configured: Result implies not rix_path.is_empty
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
			others_unchanged: ai_data_path ~ old ai_data_path and rix_path ~ old rix_path and user_path ~ old user_path
			result_is_current: Result = Current
		end

	set_ai_data_path (a_path: READABLE_STRING_GENERAL): like Current
		do
			ai_data_path := a_path.to_string_32
			Result := Current
		ensure
			set: ai_data_path.same_string_general (a_path)
			others_unchanged: core_path ~ old core_path and rix_path ~ old rix_path and user_path ~ old user_path
			result_is_current: Result = Current
		end

	set_rix_path (a_path: READABLE_STRING_GENERAL): like Current
		do
			rix_path := a_path.to_string_32
			Result := Current
		ensure
			set: rix_path.same_string_general (a_path)
			others_unchanged: core_path ~ old core_path and ai_data_path ~ old ai_data_path and user_path ~ old user_path
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
			others_unchanged: core_path ~ old core_path and ai_data_path ~ old ai_data_path and rix_path ~ old rix_path
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

	set_plugin_registry (a_registry: BIB_PLUGIN_REGISTRY): like Current
		do
			plugin_registry := a_registry
			Result := Current
		ensure
			set: plugin_registry = a_registry
			result_is_current: Result = Current
		end

end
