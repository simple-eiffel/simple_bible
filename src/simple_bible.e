note
	description: "[
		Facade: one processor's access to the simple_bible engine. Open the
		sources, then use the engines; every answer is a result object carrying
		its method and its sources (D-004: the engine owns every fact).

		One SIMPLE_BIBLE per SCOOP processor: a face's lookup worker and each job
		worker create their own (make_from_separate), each with its own source
		set. The facade names no user-cluster type (RQ-01): faces create the
		user store and the note store themselves.

		Concordance policy (Larry, 2026-10-26, Phase 2 review gate): a missing or
		refused conc.db leaves the Bible OPEN with the concordance unavailable
		(`conc_pack.is_available' False) and the reason in `conc_error'; `open'
		does not fail for it. Only content.db and the pack-count bound fail `open'.
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
			no_conc_error: conc_error = Void
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
			no_conc_error: conc_error = Void
		end

feature -- Configuration

	config: BIB_CONFIG

feature -- Lifecycle

	open
			-- Open content.db (required) read-only as the main database, attach the
			-- generic private packs found in the pack folder and the concordance pack
			-- named by `conc_path', all read-only, on this processor (2026-10-26 fold:
			-- debates 01, 03 and 05).
		require
			not_open: not is_open
		local
			l_content: BIB_CONTENT_SOURCE
		do
			last_error := Void
			conc_error := Void
			core_schema_valid := False
			has_ai_data := False
			has_author_library := False
			author_source := Void
			packs_found := 0
			if not config.is_valid then
				create last_error.make ({BIB_ERROR}.Source_unavailable, "The configuration names no content database.")
			else
				create l_content.make (config.core_path)
				content := l_content
				if not l_content.is_available then
					create last_error.make_with_details ({BIB_ERROR}.Source_unavailable, "The content database was not found.", config.core_path)
				else
					l_content.open_on (sources)
					packs_found := pack_count
					if attached l_content.last_error as al_error then
						last_error := al_error
					elseif packs_found > Max_generic_packs then
						create last_error.make_with_details ({BIB_ERROR}.Source_unavailable, "The pack folder holds " + packs_found.out + " packs; at most " + Max_generic_packs.out + " attach (FR-138).", config.pack_folder)
						close_after_refusal (l_content)
					else
						attach_private_packs
						core_schema_valid := True
						database_edition := l_content.database_edition.twin
						has_ai_data := l_content.ai_row_count > 0
						has_author_library := l_content.author_document_count > 0
						if has_author_library then
							create author_source.make (config.core_path)
						end
						open_concordance
					end
				end
			end
		ensure
			open_or_error: is_open xor (last_error /= Void)
			core_checked: is_open implies core_schema_valid
			optional_content_reflects_presence: is_open implies (has_ai_data = content_has_ai_rows and has_author_library = content_has_author_rows)
			packs_attached: is_open implies (sources.attached_count >= packs_found - pack_errors.count or last_error /= Void)
			too_many_packs: packs_found > Max_generic_packs implies last_error /= Void
			conc_attached_or_reported: (is_open and not config.conc_path.is_empty) implies (conc_pack.is_available or conc_error /= Void)
			no_history_in_release_1: not has_history
		end

	close
			-- Close every connection held by this processor.
		require
			open: is_open
		do
			across private_packs as ic loop
				ic.forget
			end
			sources.close
			if attached content as al_content and then al_content.is_open then
				al_content.close
			end
			core_schema_valid := False
		ensure
			closed: not is_open
		end

feature -- Status

	is_open: BOOLEAN
		do
			Result := sources.is_open
		end

	core_schema_valid: BOOLEAN
			-- Did content.db pass its schema-version, required-table and provenance-column checks?

	has_ai_data: BOOLEAN
	has_author_library: BOOLEAN

	content_has_ai_rows: BOOLEAN
			-- Does content.db carry AI-made rows? (Optional content ships as empty tables.)
		do
			Result := attached content as al_content and then al_content.is_open and then al_content.ai_row_count > 0
		end

	content_has_author_rows: BOOLEAN
			-- Does content.db carry the author library's documents?
		do
			Result := attached content as al_content and then al_content.is_open and then al_content.author_document_count > 0
		end

	private_packs: ARRAYED_LIST [BIB_PRIVATE_SOURCE]
			-- The generic private packs attached by the last `open' (2026-10-27).
		attribute
			create Result.make (0)
		end

	pack_errors: ARRAYED_LIST [BIB_ERROR]
			-- Why each pack the last `open' found was refused: a pack that breaks the pack rules is
			-- named and left out, and the Bible still opens (as a missing conc.db leaves it open).
		attribute
			create Result.make (0)
		end

	packs_of_kind (a_kind: READABLE_STRING_8): ARRAYED_LIST [BIB_PRIVATE_SOURCE]
			-- The attached private packs whose `meta.pack_kind' is `a_kind' (scan 58: one filter for
			-- every kind).
		do
			create Result.make (private_packs.count)
			across private_packs as ic loop
				if ic.is_open and then ic.pack_kind.same_string (a_kind) then
					Result.extend (ic)
				end
			end
		ensure
			all_of_kind: across Result as al_pack all al_pack.pack_kind.same_string (a_kind) end
		end

	commentary_packs: ARRAYED_LIST [BIB_COMMENTARY_PACK]
			-- The attached packs whose kind is "commentary" (BIB_COMMENTARY_SCHEMA).
		do
			create Result.make (1)
			across packs_of_kind ({BIB_COMMENTARY_SCHEMA}.Pack_kind) as ic loop
				Result.extend (create {BIB_COMMENTARY_PACK}.make (sources, ic.alias_name, ic.pack_title))
			end
		end

	framework_packs: ARRAYED_LIST [BIB_FRAMEWORK_PACK]
			-- The attached packs whose kind is "frameworks" (BIB_FRAMEWORK_SCHEMA, 2026-10-28).
		do
			create Result.make (1)
			across packs_of_kind ({BIB_FRAMEWORK_SCHEMA}.Pack_kind) as ic loop
				Result.extend (create {BIB_FRAMEWORK_PACK}.make (sources, ic.alias_name, ic.pack_title))
			end
		end

	packs_found: INTEGER
			-- `pack_count' as the last `open' counted it, once (design scan 29: the folder was
			-- scanned up to five times per open, and the postconditions rescanned it).

	pack_count: INTEGER
			-- Generic private packs FOUND in the pack folder, now, unclamped: a count above
			-- `Max_generic_packs' is reported by `open' (FR-138), never trimmed here
			-- (a clamp would make that report vacuous; ruling 2.4).
		local
			l_folder: SIMPLE_FILE
		do
			if not config.pack_folder.is_empty then
				create l_folder.make (config.pack_folder)
				if l_folder.is_directory then
					across l_folder.files_with_extension (".db") as ic loop
							-- conc.db is found by `conc_path', never by the folder scan (FR-166).
						if not is_conc_file (ic) then
							Result := Result + 1
						end
					end
				end
			end
		ensure
			non_negative: Result >= 0
		end

	attach_private_packs
			-- Attach each generic pack of the pack folder read-only (BIB_PRIVATE_SOURCE checks its
			-- rules); a refused pack goes to `pack_errors'. Larry's packs speak in the author voice.
		local
			l_folder: SIMPLE_FILE
			l_pack: BIB_PRIVATE_SOURCE
			l_count: INTEGER
		do
			private_packs.wipe_out
			pack_errors.wipe_out
			if not config.pack_folder.is_empty then
				create l_folder.make (config.pack_folder)
				if l_folder.is_directory then
					across l_folder.files_with_extension (".db") as ic loop
						if not is_conc_file (ic) and then l_count < Max_generic_packs then
							l_count := l_count + 1
							create l_pack.make (pack_path (ic), "pack_" + l_count.out, create {BIB_VOICE}.make_author)
							if l_pack.is_available then
								l_pack.open_on (sources)
								if l_pack.is_open then
									private_packs.extend (l_pack)
								elseif attached l_pack.last_error as al_error then
									pack_errors.extend (al_error)
								end
							end
						end
					end
				end
			end
		ensure
			every_pack_answered: private_packs.count + pack_errors.count <= packs_found
		end

	pack_path (a_name: READABLE_STRING_GENERAL): STRING_32
			-- `a_name' in the pack folder.
		do
			Result := config.pack_folder.twin
			if not Result.is_empty and then Result [Result.count] /= '\' and then Result [Result.count] /= '/' then
				Result.append_character ('\')
			end
			Result.append_string_general (a_name)
		end

	has_history: BOOLEAN
			-- history.db is v2: always False in Release 1 (RQ-07).
		do
		ensure
			release_1: not Result
		end

	database_edition: STRING_32
			-- Build id of content.db.

	last_error: detachable BIB_ERROR
			-- Why `open' failed.

	conc_error: detachable BIB_ERROR
			-- Why the concordance pack is unavailable, when `conc_path' names one that
			-- is missing, refused (FR-164: wrong `user_version', missing tables) or
			-- failed to attach. Void when no pack is configured or it attached and
			-- validated. Policy (Larry, 2026-10-26): this never closes the Bible.

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

	text_reader: BIB_TEXT_READER
			-- Bible text for reading: versions and chapters (content.db v2, fold 2026-10-26).
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources, database_edition, normalizers)
		end

	query_parser: BIB_QUERY_PARSER
			-- Query text to a clause tree (B02, B03).
		once ("OBJECT")
			create Result.make
		end

	search_scopes: BIB_SEARCH_SCOPES
			-- Named scopes: OT, NT, Gospels, Paul's letters, a book.
		require
			open: is_open
		once ("OBJECT")
			create Result.make (books)
		end

	verse_search: BIB_VERSE_SEARCH
			-- Every verse a query names: words, phrases, AND/OR/NOT, root words.
		require
			open: is_open
		once ("OBJECT")
			create Result.make (text_reader, conc_pack, versification)
		end

	conc_pack: BIB_CONC_PACK
			-- The concordance pack reader (debate 05b): conc.db or conc_dist.db,
			-- attached read-only under `{BIB_CONC_PACK}.Pack_alias'.
		require
			open: is_open
		once ("OBJECT")
			create Result.make (sources)
		end

	word_lookup: BIB_WORD_LOOKUP
			-- The word view (D-021).
		require
			open: is_open
		once ("OBJECT")
			create Result.make (conc_pack)
		end

	english_index: BIB_ENGLISH_INDEX
			-- The English lookup (D-021).
		require
			open: is_open
		once ("OBJECT")
			create Result.make (conc_pack)
		end

	verse_word_lookup: BIB_VERSE_WORDS
			-- The verse lookup (D-021).
		require
			open: is_open
		once ("OBJECT")
			create Result.make (conc_pack)
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
			-- Credits generated from source_provenance and each attached pack's own
			-- notice table; nothing typed by hand (FR-003, settlement S4).
		require
			open: is_open
		do
			check implemented_in_phase_4: False then end
		ensure
			not_empty: not Result.is_empty
		end

feature -- Constants

	Max_generic_packs: INTEGER = 9
			-- Generic private packs that fit: `{BIB_SOURCE_SET}.Max_attached' less the
			-- one slot always reserved for the concordance pack (ruling 2.4).

feature {NONE} -- Implementation

	content: detachable BIB_CONTENT_SOURCE
			-- content.db as the last `open' found it.

	open_concordance
			-- Attach and check the pack `conc_path' names. A missing or refused pack leaves the
			-- Bible open with the reason in `conc_error' (Larry, 2026-10-26); a refused pack is
			-- detached, so its slot is free.
		require
			open: is_open
		do
			if not config.conc_path.is_empty then
				if not (create {SIMPLE_FILE}.make (config.conc_path)).is_file then
					create conc_error.make_with_details ({BIB_ERROR}.Source_unavailable, "The concordance pack was not found.", config.conc_path)
				else
					sources.attach ({BIB_CONC_PACK}.Pack_alias, config.conc_path)
					if attached sources.last_error as al_error then
						conc_error := al_error
					else
						conc_pack.check_pack
						if attached conc_pack.pack_error as al_refusal then
							conc_error := al_refusal
							sources.detach ({BIB_CONC_PACK}.Pack_alias)
						end
					end
				end
			end
		ensure
			still_open: is_open
			attached_or_reported: not config.conc_path.is_empty implies (conc_pack.is_available or conc_error /= Void)
		end

	close_after_refusal (a_content: BIB_CONTENT_SOURCE)
			-- Close what `open' opened before it refused (content.db stays closed).
		require
			refused: last_error /= Void
		do
			if sources.is_open then
				sources.close
			end
			if a_content.is_open then
				a_content.close
			end
		ensure
			closed: not is_open
		end

	is_conc_file (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Is the pack-folder file `a_name' the concordance pack `conc_path' names? The same file,
			-- however each path is spelled (relative, absolute, through ".."): both are resolved to
			-- canonical absolute paths first (design scan 29).
		local
			l_entry: STRING_32
		do
			if not config.conc_path.is_empty and then (create {SIMPLE_FILE}.make (config.conc_path)).is_file then
				l_entry := config.pack_folder.twin
				if not (l_entry.ends_with ("\") or l_entry.ends_with ("/")) then
					l_entry.append_character ('\')
				end
				l_entry.append (a_name.to_string_32)
				Result := canonical (l_entry).is_case_insensitive_equal (canonical (config.conc_path))
			end
		end

	canonical (a_path: READABLE_STRING_GENERAL): STRING_32
			-- `a_path' as a canonical absolute path.
		require
			path_not_empty: not a_path.is_empty
		do
			Result := (create {SIMPLE_PATH}.make_from (a_path)).resolve.to_string
		end

	sources: BIB_SOURCE_SET
			-- This processor's single connection and its attachments.

	author_source: detachable BIB_AUTHOR_LIBRARY
			-- The author library inside content.db (debate 01, Larry's gate item 3).

	normalizers: BIB_NORMALIZER_SET
			-- Hebrew, Greek and English normalizers, shared with the build.
			-- Over simple_encoding's Unicode tables (LG-01 landed 2026-10-27: BIB_SIMPLE_UNICODE).
		once ("OBJECT")
			create Result.make (create {BIB_SIMPLE_UNICODE}.make)
		end

invariant
	error_only_when_closed: last_error /= Void implies not is_open
	conc_slot_reserved: Max_generic_packs = sources.Max_attached - 1
	no_history: not has_history
	author_library_when_flagged: has_author_library implies author_source /= Void

end
