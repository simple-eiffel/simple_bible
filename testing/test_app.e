note
	description: "[
		Test runner for the simple_bible engine library (Phase 1: contracts).
		Every suite inherits TEST_SET_BASE. Real tests run through `run_test';
		skeletal tests (Phase 5 obligations, each naming its acceptance
		criterion) run through `run_skeletal', print SKIP and are counted apart:
		SKIPS ARE NOT PASSES.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
		do
			print ("Running SIMPLE_BIBLE engine tests (Phase 1: contracts)...%N%N")
			run_lib_tests
			run_provenance_tests
			run_reference_parser_tests
			run_versification_tests
			run_verse_hub_tests
			run_normalizer_tests
			run_search_tests
			run_census_tests
			run_shape_tests
			run_quotation_tests
			run_study_tests
			run_author_library_tests
			run_user_store_tests
			run_jobs_scoop_tests
			run_ai_seam_tests
			run_pack_purity_tests
			run_source_set_tests
			run_concordance_tests
			run_facade_open_tests
			run_content_builder_tests
			run_cli_command_tests
			run_reading_tests
			run_conc_timing_tests
			run_layering_tests
			run_scoop_consumer
			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + skipped.out + " skipped (skeletal), " + failed.out + " failed%N")
			if failed > 0 then
				print ("TESTS FAILED%N")
				(create {EXCEPTIONS}).die (1)
			else
				print ("ALL RUN TESTS PASSED (" + skipped.out + " skeletal, Phase 5)%N")
			end
		end

feature {NONE} -- Suites

	run_lib_tests
		local
			t: LIB_TESTS
		do
			print ("LIB_TESTS%N")
			create t
			run_test (agent t.test_config_builder_chains_and_frames, "test_config_builder_chains_and_frames")
			run_test (agent t.test_facade_starts_unopened, "test_facade_starts_unopened")
			run_test (agent t.test_facade_has_no_history, "test_facade_has_no_history")
			run_test (agent t.test_portable_config, "test_portable_config")
			run_skeletal (agent t.test_open_checks_core_schema, "test_open_checks_core_schema", "AC-1a-04 read side")
			run_skeletal (agent t.test_rerun_gives_identical_counts, "test_rerun_gives_identical_counts", "AC-1a-31")
		end

	run_provenance_tests
		local
			t: TEST_PROVENANCE
		do
			print ("TEST_PROVENANCE%N")
			create t
			run_test (agent t.test_unknown_license_never_ships, "test_unknown_license_never_ships")
			run_test (agent t.test_restricted_license_never_ships, "test_restricted_license_never_ships")
			run_test (agent t.test_non_commercial_ships_in_free_tool, "test_non_commercial_ships_in_free_tool")
			run_test (agent t.test_license_gate_rules, "test_license_gate_rules")
			run_test (agent t.test_ai_provenance_carries_method_and_model, "test_ai_provenance_carries_method_and_model")
			run_test (agent t.test_fact_bound_to_provenance, "test_fact_bound_to_provenance")
			run_test (agent t.test_method_states_scope, "test_method_states_scope")
			run_test (agent t.test_fact_closure_holds_when_cited, "test_fact_closure_holds_when_cited")
			run_test (agent t.test_fact_closure_detects_uncited_fact, "test_fact_closure_detects_uncited_fact")
			run_test (agent t.test_failed_result_carries_no_items, "test_failed_result_carries_no_items")
			run_skeletal (agent t.test_license_gate_names_every_refusal, "test_license_gate_names_every_refusal", "AC-1a-02/03")
		end

	run_reference_parser_tests
		local
			t: TEST_REFERENCE_PARSER
		do
			print ("TEST_REFERENCE_PARSER%N")
			create t
			run_test (agent t.test_ambiguous_outcome_keeps_every_candidate, "test_ambiguous_outcome_keeps_every_candidate")
			run_test (agent t.test_invalid_outcome_is_located, "test_invalid_outcome_is_located")
			run_test (agent t.test_valid_outcome_names_system, "test_valid_outcome_names_system")
			run_skeletal (agent t.test_parser_case_suite, "test_parser_case_suite", "AC-1a-15")
			run_skeletal (agent t.test_ju_and_ph_are_ambiguous, "test_ju_and_ph_are_ambiguous", "AC-1a-15")
			run_skeletal (agent t.test_detector_matches_r12_golden, "test_detector_matches_r12_golden", "D-020")
		end

	run_versification_tests
		local
			t: TEST_VERSIFICATION
		do
			print ("TEST_VERSIFICATION%N")
			create t
			run_test (agent t.test_one_to_many_pairing_names_every_rule, "test_one_to_many_pairing_names_every_rule")
			run_test (agent t.test_identity_pairing_needs_no_rule, "test_identity_pairing_needs_no_rule")
			run_skeletal (agent t.test_regression_set, "test_regression_set", "AC-1a-16")
			run_skeletal (agent t.test_split_verse_counted_once_per_hub, "test_split_verse_counted_once_per_hub", "AC-1a-17")
		end

	run_verse_hub_tests
		local
			t: TEST_VERSE_HUB
		do
			print ("TEST_VERSE_HUB%N")
			create t
			run_test (agent t.test_kjv_label, "test_kjv_label")
			run_test (agent t.test_septuagint_label_names_edition, "test_septuagint_label_names_edition")
			run_test (agent t.test_version_reports_count_and_seal, "test_version_reports_count_and_seal")
			run_test (agent t.test_omission_is_typed_never_empty, "test_omission_is_typed_never_empty")
			run_test (agent t.test_not_in_canon_omission, "test_not_in_canon_omission")
			run_test (agent t.test_display_text_kept_exactly, "test_display_text_kept_exactly")
			run_skeletal (agent t.test_matt_17_21_in_wh, "test_matt_17_21_in_wh", "AC-1a-19")
			run_skeletal (agent t.test_tobit_in_bsb, "test_tobit_in_bsb", "AC-1a-19")
			run_skeletal (agent t.test_every_version_answers, "test_every_version_answers", "AC-1a-19/31")
		end

	run_normalizer_tests
		local
			t: TEST_NORMALIZERS
		do
			print ("TEST_NORMALIZERS%N")
			create t
			run_test (agent t.test_pointing_marks_classified, "test_pointing_marks_classified")
			run_test (agent t.test_script_classifier, "test_script_classifier")
			run_skeletal (agent t.test_normalizers_idempotent, "test_normalizers_idempotent", "AC-1a-23 (LG-01)")
			run_skeletal (agent t.test_trap_corpus_has_no_combining_mark, "test_trap_corpus_has_no_combining_mark", "AC-1a-23 (LG-01)")
			run_skeletal (agent t.test_normalized_column_finds_display_phrase, "test_normalized_column_finds_display_phrase", "AC-1a-20")
		end

	run_search_tests
		local
			t: TEST_SEARCH
		do
			print ("TEST_SEARCH%N")
			create t
			run_test (agent t.test_query_states, "test_query_states")
			run_test (agent t.test_scope_contains_book_range, "test_scope_contains_book_range")
			run_skeletal (agent t.test_copied_phrase_finds_its_verse, "test_copied_phrase_finds_its_verse", "AC-1a-21")
			run_test (agent t.test_strongs_padding_is_one_key, "test_strongs_padding_is_one_key")
			run_skeletal (agent t.test_split_senses_reported_apart, "test_split_senses_reported_apart", "AC-1a-22")
			run_skeletal (agent t.test_every_count_states_scope, "test_every_count_states_scope", "AC-1a-31")
		end

	run_census_tests
		local
			t: TEST_CENSUS
		do
			print ("TEST_CENSUS%N")
			create t
			run_test (agent t.test_definition_starts_editable, "test_definition_starts_editable")
			run_test (agent t.test_setters_keep_frames, "test_setters_keep_frames")
			run_test (agent t.test_definition_completeness, "test_definition_completeness")
			run_test (agent t.test_mark_stored_starts_lineage, "test_mark_stored_starts_lineage")
			run_test (agent t.test_bucketed_result_has_four_buckets, "test_bucketed_result_has_four_buckets")
			run_test (agent t.test_cancelled_run_has_no_findings, "test_cancelled_run_has_no_findings")
			run_skeletal (agent t.test_freeze_at_first_run, "test_freeze_at_first_run", "AC-1a-24")
			run_skeletal (agent t.test_new_version_increments, "test_new_version_increments", "AC-1a-24")
			run_skeletal (agent t.test_rerun_identical_counts_and_controls, "test_rerun_identical_counts_and_controls", "AC-1a-24")
			run_skeletal (agent t.test_no_data_kept_apart_from_fails, "test_no_data_kept_apart_from_fails", "AC-1a-25")
			run_skeletal (agent t.test_counts_per_canonical_hub, "test_counts_per_canonical_hub", "AC-1a-17")
		end

	run_shape_tests
		local
			t: TEST_SHAPES
		do
			print ("TEST_SHAPES%N")
			create t
			run_test (agent t.test_t3_is_judgment, "test_t3_is_judgment")
			run_test (agent t.test_t3_finding_is_never_evidence, "test_t3_finding_is_never_evidence")
			run_test (agent t.test_candidate_reports_missing_tags, "test_candidate_reports_missing_tags")
			run_test (agent t.test_registry_starts_empty, "test_registry_starts_empty")
			run_skeletal (agent t.test_evidence_refuses_t3, "test_evidence_refuses_t3", "AC-1a-25")
			run_skeletal (agent t.test_shape_differential, "test_shape_differential", "AC-1a-26")
		end

	run_quotation_tests
		local
			t: TEST_QUOTATION
		do
			print ("TEST_QUOTATION%N")
			create t
			run_test (agent t.test_no_data_answer_names_edition, "test_no_data_answer_names_edition")
			run_skeletal (agent t.test_hebrews_8_they_chose, "test_hebrews_8_they_chose", "AC-1a-27")
			run_skeletal (agent t.test_unaligned_quotation_is_no_data, "test_unaligned_quotation_is_no_data", "AC-1a-27")
		end

	run_study_tests
		local
			t: TEST_STUDY
		do
			print ("TEST_STUDY%N")
			create t
			run_test (agent t.test_ai_made_related_passage_is_labeled, "test_ai_made_related_passage_is_labeled")
			run_test (agent t.test_plain_related_passage_has_reason, "test_plain_related_passage_has_reason")
			run_test (agent t.test_surface_form_mark_is_labeled, "test_surface_form_mark_is_labeled")
			run_test (agent t.test_journey_row_carries_method, "test_journey_row_carries_method")
			run_test (agent t.test_text_first_guide_holds_text, "test_text_first_guide_holds_text")
			run_test (agent t.test_share_alike_notice_exists, "test_share_alike_notice_exists")
			run_skeletal (agent t.test_ekklesia_journey, "test_ekklesia_journey", "AC-1a-28")
			run_skeletal (agent t.test_gen_7_16_divine_names, "test_gen_7_16_divine_names", "AC-1a-29")
			run_skeletal (agent t.test_range_fifty_lemma_sample, "test_range_fifty_lemma_sample", "AC-1a-30")
			run_skeletal (agent t.test_fact_closure_every_engine, "test_fact_closure_every_engine", "AC-1a-32")
			run_skeletal (agent t.test_ai_neighbors_gated_by_tokenizer_golden, "test_ai_neighbors_gated_by_tokenizer_golden", "AC-1a-33")
			run_skeletal (agent t.test_text_first_job_excludes_commentary, "test_text_first_job_excludes_commentary", "AC-1a-38")
			run_skeletal (agent t.test_export_keeps_attribution_and_labels, "test_export_keeps_attribution_and_labels", "AC-1a-51")
		end

	run_author_library_tests
		local
			t: TEST_AUTHOR_LIBRARY
		do
			print ("TEST_AUTHOR_LIBRARY%N")
			create t
			run_test (agent t.test_withdrawn_document_carries_banner, "test_withdrawn_document_carries_banner")
			run_test (agent t.test_publication_rule_seals_on_approval, "test_publication_rule_seals_on_approval")
			run_skeletal (agent t.test_search_excludes_withdrawn_by_default, "test_search_excludes_withdrawn_by_default", "AC-1a-34")
			run_skeletal (agent t.test_include_withdrawn_returns_banner, "test_include_withdrawn_returns_banner", "AC-1a-34")
			run_skeletal (agent t.test_publication_rule_excludes_listed_paths, "test_publication_rule_excludes_listed_paths", "AC-1a-14")
		end

	run_user_store_tests
		local
			t: TEST_USER_STORE
		do
			print ("TEST_USER_STORE%N")
			create t
			run_test (agent t.test_hub_id_is_english_numbering, "test_hub_id_is_english_numbering")
			run_test (agent t.test_notes_keep_every_version, "test_notes_keep_every_version")
			run_test (agent t.test_user_store_refuses_another_schema, "test_user_store_refuses_another_schema")
			run_test (agent t.test_one_rule_for_a_live_item, "test_one_rule_for_a_live_item")
			run_test (agent t.test_recent_places_one_per_chapter, "test_recent_places_one_per_chapter")
			run_test (agent t.test_tags_count_and_list_their_verses, "test_tags_count_and_list_their_verses")
			run_test (agent t.test_a_failed_item_write_is_reported, "test_a_failed_item_write_is_reported")
			run_test (agent t.test_highlights_and_bookmarks_keep_their_reason, "test_highlights_and_bookmarks_keep_their_reason")
			run_test (agent t.test_a_topical_title_survives_export_and_import, "test_a_topical_title_survives_export_and_import")
			run_test (agent t.test_notes_export_and_import_never_overwrite, "test_notes_export_and_import_never_overwrite")
			run_test (agent t.test_notes_keyed_by_hub_id, "test_notes_keyed_by_hub_id")
			run_test (agent t.test_user_items_carry_no_version, "test_user_items_carry_no_version")
			run_test (agent t.test_user_store_is_the_only_writer, "test_user_store_is_the_only_writer")
			run_test (agent t.test_note_export_names_are_file_safe, "test_note_export_names_are_file_safe")
			run_test (agent t.test_file_safe_name_scan23_gaps, "test_file_safe_name_scan23_gaps")
			run_skeletal (agent t.test_highlight_shows_in_every_version, "test_highlight_shows_in_every_version", "AC-1a-39")
			run_skeletal (agent t.test_edit_appends_and_delete_is_soft, "test_edit_appends_and_delete_is_soft", "AC-1a-40")
			run_skeletal (agent t.test_backup_on_exit_restores, "test_backup_on_exit_restores", "AC-1a-40")
			run_skeletal (agent t.test_previous_schema_migrates, "test_previous_schema_migrates", "AC-1a-41")
			run_skeletal (agent t.test_markdown_store_is_default_with_index, "test_markdown_store_is_default_with_index", "AC-1a-42")
			run_skeletal (agent t.test_markdown_external_edit_gets_conflict_copy, "test_markdown_external_edit_gets_conflict_copy", "AC-1a-43")
			run_skeletal (agent t.test_markdown_second_instance_read_only, "test_markdown_second_instance_read_only", "AC-1a-43")
			run_skeletal (agent t.test_markdown_rename_leaves_no_dangling_row, "test_markdown_rename_leaves_no_dangling_row", "AC-1a-43")
		end

	run_jobs_scoop_tests
		local
			t: TEST_JOBS_SCOOP
		do
			print ("TEST_JOBS_SCOOP%N")
			create t
			run_test (agent t.test_cancel_token_across_processors, "test_cancel_token_across_processors")
			run_test (agent t.test_cancelled_mailbox_holds_zero_pages, "test_cancelled_mailbox_holds_zero_pages")
			run_test (agent t.test_done_mailbox_keeps_pages_in_order, "test_done_mailbox_keeps_pages_in_order")
			run_test (agent t.test_waiter_wakes_on_change, "test_waiter_wakes_on_change")
			run_skeletal (agent t.test_cancelled_job_yields_no_result, "test_cancelled_job_yields_no_result", "AC-1a-37")
		end

	run_ai_seam_tests
		local
			t: TEST_AI_SEAM
		do
			print ("TEST_AI_SEAM%N")
			create t
			run_test (agent t.test_null_adapter_never_produces, "test_null_adapter_never_produces")
			run_test (agent t.test_post_check_labels_and_fails_safe, "test_post_check_labels_and_fails_safe")
			run_test (agent t.test_facade_binds_null_adapter, "test_facade_binds_null_adapter")
		end

	run_pack_purity_tests
		local
			t: TEST_PACK_PURITY
		do
			print ("TEST_PACK_PURITY%N")
			create t
			run_test (agent t.test_no_plugin_classes, "test_no_plugin_classes")
			run_test (agent t.test_private_source_is_one_generic_class, "test_private_source_is_one_generic_class")
			run_test (agent t.test_scan_sees_every_source_folder, "test_scan_sees_every_source_folder")
			run_test (agent t.test_no_private_names_in_sources, "test_no_private_names_in_sources")
			run_skeletal (agent t.test_public_executable_has_no_private_strings, "test_public_executable_has_no_private_strings", "AC-1a-57")
		end

	run_source_set_tests
		local
			t: TEST_SOURCE_SET
		do
			print ("TEST_SOURCE_SET%N")
			create t
			run_test (agent t.test_open_attach_detach_close, "test_open_attach_detach_close")
			run_test (agent t.test_open_core_missing_file_reports, "test_open_core_missing_file_reports")
			run_test (agent t.test_open_core_not_a_database_reports, "test_open_core_not_a_database_reports")
			run_test (agent t.test_open_core_folder_reports, "test_open_core_folder_reports")
			run_test (agent t.test_close_forgets_the_connection, "test_close_forgets_the_connection")
			run_test (agent t.test_attach_missing_pack_reports_sqlite_message, "test_attach_missing_pack_reports_sqlite_message")
			run_test (agent t.test_detach_refused_while_a_cursor_is_open, "test_detach_refused_while_a_cursor_is_open")
		end

	run_cli_command_tests
		local
			t: TEST_CLI_COMMANDS
		do
			print ("TEST_CLI_COMMANDS%N")
			create t
			run_test (agent t.test_banner_is_the_pack_edition, "test_banner_is_the_pack_edition")
			run_test (agent t.test_word_command, "test_word_command")
			run_test (agent t.test_english_command, "test_english_command")
			run_test (agent t.test_verse_command, "test_verse_command")
			run_test (agent t.test_strongs_command, "test_strongs_command")
			run_test (agent t.test_lookup_choices, "test_lookup_choices")
			run_test (agent t.test_lookup_reports_a_broken_pack, "test_lookup_reports_a_broken_pack")
			run_test (agent t.test_settings_round_trip, "test_settings_round_trip")
			run_test (agent t.test_corpus_names_and_headword_corpus, "test_corpus_names_and_headword_corpus")
		end

	run_reading_tests
		local
			t: TEST_READING
		do
			print ("TEST_READING%N")
			create t
			run_test (agent t.test_versions_and_a_chapter, "test_versions_and_a_chapter")
			run_test (agent t.test_cross_references_most_voted_first, "test_cross_references_most_voted_first")
			run_test (agent t.test_lexicon_entries_and_gloss, "test_lexicon_entries_and_gloss")
			run_test (agent t.test_a_clicked_word_finds_its_original, "test_a_clicked_word_finds_its_original")
			run_test (agent t.test_a_clicked_original_word_finds_its_headword, "test_a_clicked_original_word_finds_its_headword")
			run_test (agent t.test_an_empty_chapter_says_why, "test_an_empty_chapter_says_why")
			run_test (agent t.test_every_claim_wears_its_label, "test_every_claim_wears_its_label")
			run_test (agent t.test_references_become_links, "test_references_become_links")
			run_test (agent t.test_reference_box_reads_ranges_and_one_chapter_books, "test_reference_box_reads_ranges_and_one_chapter_books")
			run_test (agent t.test_the_reference_readers_agree, "test_the_reference_readers_agree")
			run_test (agent t.test_place_rows_know_their_verse, "test_place_rows_know_their_verse")
			run_test (agent t.test_a_failing_chapter_query_says_why, "test_a_failing_chapter_query_says_why")
		end

	run_content_builder_tests
		local
			t: TEST_CONTENT_BUILDER
		do
			print ("TEST_CONTENT_BUILDER%N")
			create t
			run_test (agent t.test_builds_a_content_db_the_engine_opens, "test_builds_a_content_db_the_engine_opens")
			run_test (agent t.test_rebuild_is_byte_identical, "test_rebuild_is_byte_identical")
			run_test (agent t.test_missing_bible_is_reported, "test_missing_bible_is_reported")
			run_test (agent t.test_failed_build_leaves_nothing_behind, "test_failed_build_leaves_nothing_behind")
			run_test (agent t.test_failed_move_leaves_no_temporary_file, "test_failed_move_leaves_no_temporary_file")
		end

	run_conc_timing_tests
			-- Timing on the real pack, only when SIMPLE_BIBLE_CONC names it (Task 8).
		local
			t: TEST_CONC_TIMING
		do
			print ("TEST_CONC_TIMING%N")
			create t
			if t.is_runnable then
				run_test (agent t.test_word_view_first_screen, "test_word_view_first_screen")
				run_test (agent t.test_deep_pages_offset_and_keyset, "test_deep_pages_offset_and_keyset")
				run_test (agent t.test_english_and_verse_lookups, "test_english_and_verse_lookups")
			else
				run_skeletal (agent t.test_word_view_first_screen, "test_word_view_first_screen", "set SIMPLE_BIBLE_CONC")
				run_skeletal (agent t.test_deep_pages_offset_and_keyset, "test_deep_pages_offset_and_keyset", "set SIMPLE_BIBLE_CONC")
				run_skeletal (agent t.test_english_and_verse_lookups, "test_english_and_verse_lookups", "set SIMPLE_BIBLE_CONC")
			end
		end

	run_facade_open_tests
		local
			t: TEST_FACADE_OPEN
		do
			print ("TEST_FACADE_OPEN%N")
			create t
			run_test (agent t.test_open_with_content_and_concordance, "test_open_with_content_and_concordance")
			run_test (agent t.test_open_without_a_concordance, "test_open_without_a_concordance")
			run_test (agent t.test_missing_concordance_keeps_the_bible_open, "test_missing_concordance_keeps_the_bible_open")
			run_test (agent t.test_refused_concordance_keeps_the_bible_open, "test_refused_concordance_keeps_the_bible_open")
			run_test (agent t.test_content_at_another_version_is_refused, "test_content_at_another_version_is_refused")
			run_test (agent t.test_content_without_provenance_is_refused, "test_content_without_provenance_is_refused")
			run_test (agent t.test_missing_content_is_refused, "test_missing_content_is_refused")
			run_test (agent t.test_pack_folder_scan_skips_the_concordance, "test_pack_folder_scan_skips_the_concordance")
			run_test (agent t.test_pack_folder_scan_compares_files_not_spellings, "test_pack_folder_scan_compares_files_not_spellings")
			run_test (agent t.test_commentary_pack_builds_attaches_and_answers, "test_commentary_pack_builds_attaches_and_answers")
			run_test (agent t.test_one_commentary_pack_holds_every_book, "test_one_commentary_pack_holds_every_book")
			run_test (agent t.test_a_pack_breaking_the_rules_is_refused_and_named, "test_a_pack_breaking_the_rules_is_refused_and_named")
			run_test (agent t.test_a_claim_without_an_id_is_refused, "test_a_claim_without_an_id_is_refused")
			run_test (agent t.test_book_catalog_reads_content_db, "test_book_catalog_reads_content_db")
			run_test (agent t.test_edition_swap_needs_no_code, "test_edition_swap_needs_no_code")
		end

	run_concordance_tests
		local
			t: TEST_CONCORDANCE
		do
			print ("TEST_CONCORDANCE%N")
			create t
			run_test (agent t.test_contracts_are_checked_in_this_build, "test_contracts_are_checked_in_this_build")
			run_test (agent t.test_pack_absent_until_attached, "test_pack_absent_until_attached")
			run_test (agent t.test_pack_rules, "test_pack_rules")
			run_test (agent t.test_word_view_in_pilot_order, "test_word_view_in_pilot_order")
			run_test (agent t.test_english_lookup_counts_per_bible, "test_english_lookup_counts_per_bible")
			run_test (agent t.test_verse_lookup_every_corpus, "test_verse_lookup_every_corpus")
			run_test (agent t.test_word_view_lists_every_fact, "test_word_view_lists_every_fact")
			run_test (agent t.test_word_view_failures_are_answers, "test_word_view_failures_are_answers")
			run_test (agent t.test_pack_not_valid_until_checked, "test_pack_not_valid_until_checked")
			run_test (agent t.test_fixture_has_the_reviewed_shapes, "test_fixture_has_the_reviewed_shapes")
			run_test (agent t.test_language_codes, "test_language_codes")
			run_test (agent t.test_pack_accepts_the_fixture, "test_pack_accepts_the_fixture")
			run_test (agent t.test_pack_refuses_an_old_version, "test_pack_refuses_an_old_version")
			run_test (agent t.test_pack_refuses_a_missing_table, "test_pack_refuses_a_missing_table")
			run_test (agent t.test_pack_refuses_a_file_that_is_not_a_database, "test_pack_refuses_a_file_that_is_not_a_database")
			run_test (agent t.test_reattached_pack_needs_a_new_check, "test_reattached_pack_needs_a_new_check")
			run_test (agent t.test_same_path_reattach_needs_a_new_check, "test_same_path_reattach_needs_a_new_check")
			run_test (agent t.test_pack_refuses_unreadable_facts, "test_pack_refuses_unreadable_facts")
			run_test (agent t.test_word_entry_reads_the_heading, "test_word_entry_reads_the_heading")
			run_test (agent t.test_headwords_for_strongs_go_through_xref, "test_headwords_for_strongs_go_through_xref")
			run_test (agent t.test_headwords_for_typed_text, "test_headwords_for_typed_text")
			run_test (agent t.test_typed_greek_folds_as_a_clicked_word, "test_typed_greek_folds_as_a_clicked_word")
			run_test (agent t.test_interlinear_joins_a_words_morphemes, "test_interlinear_joins_a_words_morphemes")
			run_test (agent t.test_morphology_in_words, "test_morphology_in_words")
			run_test (agent t.test_one_door_rule_for_every_face, "test_one_door_rule_for_every_face")
			run_test (agent t.test_english_glance_holds_back_function_words, "test_english_glance_holds_back_function_words")
			run_test (agent t.test_strongs_key_text, "test_strongs_key_text")
			run_test (agent t.test_places_page_by_offset_and_by_keyset, "test_places_page_by_offset_and_by_keyset")
			run_test (agent t.test_english_rows_bible_by_bible, "test_english_rows_bible_by_bible")
			run_test (agent t.test_verse_words_every_corpus, "test_verse_words_every_corpus")
			run_test (agent t.test_place_total_is_void_when_the_count_cannot_be_read, "test_place_total_is_void_when_the_count_cannot_be_read")
			run_test (agent t.test_english_rows_refuse_a_non_original_headword, "test_english_rows_refuse_a_non_original_headword")
			run_test (agent t.test_verse_word_takes_real_hebrew_rows, "test_verse_word_takes_real_hebrew_rows")
			run_test (agent t.test_verse_word_takes_english_computed_rows, "test_verse_word_takes_english_computed_rows")
			run_test (agent t.test_value_creators_pin_every_field, "test_value_creators_pin_every_field")
		end

	run_layering_tests
		local
			t: TEST_LAYERING
		do
			print ("TEST_LAYERING%N")
			create t
			run_test (agent t.test_engine_ecf_has_no_face_or_build_dependency, "test_engine_ecf_has_no_face_or_build_dependency")
			run_test (agent t.test_engine_names_no_build_or_face_class, "test_engine_names_no_build_or_face_class")
			run_test (agent t.test_command_line_cluster_is_a_face, "test_command_line_cluster_is_a_face")
			run_test (agent t.test_no_banned_accessor, "test_no_banned_accessor")
			run_test (agent t.test_only_the_map_creates_mapped_refs, "test_only_the_map_creates_mapped_refs")
			run_test (agent t.test_no_engine_cluster_names_user_types, "test_no_engine_cluster_names_user_types")
			run_test (agent t.test_no_ai_reachable_from_search, "test_no_ai_reachable_from_search")
			run_test (agent t.test_no_face_types_in_engine, "test_no_face_types_in_engine")
		end

	run_scoop_consumer
		local
			t: TEST_SCOOP_CONSUMER
		do
			print ("TEST_SCOOP_CONSUMER%N")
			create t
			run_test (agent t.test_scoop_compatibility, "test_scoop_compatibility")
		end

feature {NONE} -- Runner

	passed, failed, skipped: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
				-- Say why: the exception's class and description (assert tag, contract tag).
			print ("  FAIL: " + a_name)
			if attached (create {EXCEPTION_MANAGER}).last_exception as al_exception then
				print (" [" + al_exception.generating_type.name)
				if attached al_exception.description as al_description then
					print (": ")
					print (al_description)
				end
				print ("]")
			end
			print ("%N")
			failed := failed + 1
			l_retried := True
			retry
		end

	run_skeletal (a_test: PROCEDURE; a_name, a_criterion: STRING)
			-- Report a Phase 5 obligation without counting it as a pass.
		do
			print ("  SKIP: " + a_name + " (skeletal, " + a_criterion + ")%N")
			skipped := skipped + 1
		end

end
