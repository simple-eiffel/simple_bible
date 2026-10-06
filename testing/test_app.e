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
			run_plugin_purity_tests
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
			run_skeletal (agent t.test_strongs_padding_is_one_key, "test_strongs_padding_is_one_key", "AC-1a-22")
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
			run_test (agent t.test_notes_keyed_by_hub_id, "test_notes_keyed_by_hub_id")
			run_test (agent t.test_user_items_carry_no_version, "test_user_items_carry_no_version")
			run_test (agent t.test_user_store_is_the_only_writer, "test_user_store_is_the_only_writer")
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

	run_plugin_purity_tests
		local
			t: TEST_PLUGIN_PURITY
		do
			print ("TEST_PLUGIN_PURITY%N")
			create t
			run_test (agent t.test_public_registry_is_empty, "test_public_registry_is_empty")
			run_test (agent t.test_registry_seals, "test_registry_seals")
			run_test (agent t.test_no_effective_lens_or_private_source, "test_no_effective_lens_or_private_source")
			run_test (agent t.test_no_private_names_in_sources, "test_no_private_names_in_sources")
			run_skeletal (agent t.test_public_executable_has_no_private_strings, "test_public_executable_has_no_private_strings", "AC-1a-57")
		end

	run_layering_tests
		local
			t: TEST_LAYERING
		do
			print ("TEST_LAYERING%N")
			create t
			run_test (agent t.test_engine_ecf_has_no_face_or_build_dependency, "test_engine_ecf_has_no_face_or_build_dependency")
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
			print ("  FAIL: " + a_name + "%N")
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
