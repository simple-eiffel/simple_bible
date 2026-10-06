note
	description: "[
		Facade: one processor's access to the simple_bible engine. Open the
		sources, then use the engines; every answer is a result object carrying
		its method and its sources (D-004: the engine owns every fact).

		One SIMPLE_BIBLE per SCOOP processor: a face's lookup worker and each job
		worker create their own (make_from_separate), each with its own source
		set. The facade names no user-cluster type (RQ-01): faces create the
		user store and the note store themselves.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_BIBLE

create
	make, make_from_separate

feature {NONE} -- Initialization

	make (a_config: BIB_CONFIG)
			-- An unopened engine for `a_config'.
		require
			config_valid: a_config.is_valid
		do
			config := a_config
			create sources.make
			create database_edition.make_empty
		ensure
			config_set: config = a_config
			not_open: not is_open
			no_error: last_error = Void
		end

	make_from_separate (a_config: separate BIB_CONFIG)
			-- An unopened engine on this processor, configured from a copy of `a_config'.
			-- An invalid copy makes `open' fail with a named error.
		do
			create config.make_from_separate (a_config)
			create sources.make
			create database_edition.make_empty
		ensure
			not_open: not is_open
			no_error: last_error = Void
		end

feature -- Configuration

	config: BIB_CONFIG

	can_attach_private_source: BOOLEAN
			-- Is there room for one more attached database (SQLite limit 10)?
		do
			Result := sources.attached_count < sources.Max_attached
		end

feature -- Lifecycle

	open
			-- Open core.db (required) and the optional databases present, read-only, on this
			-- processor; then let each registered plug-in attach its private sources.
		require
			not_open: not is_open
		do
			-- Phase 4
		ensure
			open_or_error: is_open xor (last_error /= Void)
			core_checked: is_open implies core_schema_valid
			optional_sources_reflect_files: is_open implies (has_ai_data = config.ai_data_present and has_author_library = config.rix_present)
			no_history_in_release_1: not has_history
			plugins_sealed: is_open implies config.plugin_registry.is_sealed
		end

	close
			-- Close every connection held by this processor.
		require
			open: is_open
		do
			-- Phase 4
		ensure
			closed: not is_open
		end

feature -- Status

	is_open: BOOLEAN
		do
			Result := sources.is_open
		end

	core_schema_valid: BOOLEAN
			-- Did core.db pass its schema-version, required-table and provenance-column checks?

	has_ai_data: BOOLEAN
	has_author_library: BOOLEAN

	has_history: BOOLEAN
			-- history.db is v2: always False in Release 1 (RQ-07).
		do
		ensure
			release_1: not Result
		end

	database_edition: STRING_32
			-- Build id of core.db.

	last_error: detachable BIB_ERROR
			-- Why `open' failed.

feature -- Engines (one per instance)

	books: BIB_BOOK_CATALOG
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources)
		end

	parser: BIB_REFERENCE_PARSER
		require
			open: is_open
		once ("OBJECT")
			create Result.make (books)
		end

	detector: BIB_REFERENCE_DETECTOR
		require
			open: is_open
		once ("OBJECT")
			create Result.make (books)
		end

	versification: BIB_VERSIFICATION_MAP
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources, books)
		end

	hub: BIB_VERSE_HUB
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources, versification)
		end

	search: BIB_SEARCH_ENGINE
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources, normalizers)
		end

	concordance: BIB_CONCORDANCE
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources)
		end

	census: BIB_CENSUS_ENGINE
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources, concordance)
		end

	shapes: BIB_SHAPE_ENGINE
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources)
		end

	quotations: BIB_QUOTATION_COMPARER
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources, versification)
		end

	range_viewer: BIB_RANGE_VIEWER
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources)
		end

	journey: BIB_WORD_JOURNEY
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources, versification)
		end

	divine_names: BIB_DIVINE_NAME_MARKER
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources, normalizers)
		end

	guides: BIB_GUIDE_ASSEMBLER
		require
			open: is_open
		once ("OBJECT")
			create Result.make (Current)
		end

	related: BIB_RELATED_PASSAGES
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources, has_ai_data)
		end

	library: BIB_LIBRARY
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources)
		end

	names: BIB_PROPER_NAMES
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources)
		end

	author_library: BIB_AUTHOR_LIBRARY
		require
			open: is_open
			available: has_author_library
		do
			if attached author_source as l_source then
				Result := l_source
			else
				check available: False then end
			end
		end

	exporter: BIB_EXPORTER
		once ("OBJECT")
			create Result.make
		end

	ai_adapter: BIB_AI_ADAPTER
			-- Release 1 binds the null adapter (D-016, AC-1a-54).
		once ("OBJECT")
			create {BIB_NULL_AI_ADAPTER} Result
		ensure
			null_bound: attached {BIB_NULL_AI_ADAPTER} Result
		end

	plugins: BIB_PLUGIN_REGISTRY
		do
			Result := config.plugin_registry
		ensure
			from_config: Result = config.plugin_registry
		end

feature -- Convenience

	verse (a_text: READABLE_STRING_GENERAL): BIB_VERSE_RESULT
			-- Parse `a_text', map it, and look it up in the default version.
		require
			open: is_open
			text_not_empty: not a_text.is_empty
		do
			check implemented_in_phase_4: False then end
		ensure
			ambiguous_never_guessed: Result.parse_outcome.is_ambiguous implies (Result.version_count = 0 and not Result.is_success)
			method_recorded: Result.method.engine_feature.same_string_general ("verse")
			fact_closure: Result.is_fact_closed
		end

	rerun (a_method: BIB_METHOD): BIB_ENGINE_RESULT
			-- Re-run a recorded method (Show method, FR-032).
		require
			open: is_open
			rerunnable: a_method.is_rerunnable
		do
			check implemented_in_phase_4: False then end
		ensure
			same_edition_same_counts: a_method.database_edition.same_string (database_edition) implies Result.method.counts_equal (a_method)
			same_feature: Result.method.engine_feature.same_string (a_method.engine_feature)
			fact_closure: Result.is_fact_closed
		end

	credits: STRING_32
			-- Credits generated from source_provenance (FR-003).
		require
			open: is_open
		do
			check implemented_in_phase_4: False then end
		ensure
			not_empty: not Result.is_empty
		end

feature {BIB_PLUGIN} -- Private sources

	attach_private_source (a_source: BIB_PRIVATE_SOURCE)
			-- Attach `a_source' (plug-ins only, during `open').
		require
			open: is_open
			room: can_attach_private_source
			present: a_source.is_available
		do
			-- Phase 4: a_source.open_on (sources)
		ensure
			attached_or_error: a_source.is_open or a_source.last_error /= Void
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET
			-- This processor's single connection and its attachments.

	author_source: detachable BIB_AUTHOR_LIBRARY
			-- rix.db when present.

	normalizers: BIB_NORMALIZER_SET
			-- Hebrew, Greek and English normalizers, shared with the build.
			-- Bound in Phase 4 to the simple_encoding adapter of BIB_UNICODE_SERVICE (LG-01).
		once ("OBJECT")
			check bound_after_lg_01: False then end
		end

invariant
	error_only_when_closed: last_error /= Void implies not is_open
	no_history: not has_history
	author_library_when_flagged: has_author_library implies author_source /= Void

end
