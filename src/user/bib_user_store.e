note
	description: "[
		user.db: the reader's own data (read-write; one writer processor; the
		only writable source). Append-only: an edit writes a new version, a
		delete is soft, and both can be restored (AC-1a-40); previous schemas
		migrate with every setting, layout and note preserved (AC-1a-41).
		A model of a database is not materialized: frames are integer counts per
		kind and hub id; settings (few) are the one materialized model (05).
		No engine cluster depends on this class (RQ-01).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_USER_STORE

inherit
	BIB_DATA_SOURCE
		redefine
			is_read_only,
			is_provenance_schema_valid
		end

create
	make

feature {NONE} -- Initialization

	make (a_path: READABLE_STRING_GENERAL)
		require
			path_not_empty: not a_path.is_empty
		do
			path := a_path.to_string_32
			create sqlite_version.make_empty
			create settings.make (32)
		ensure
			closed: not is_open
		end

feature -- Access

	alias_name: STRING_8
			-- user.db is the main database of the user-store processor's own connection.
		do
			Result := "main"
		end

	expected_schema_version: INTEGER
		do
			Result := User_schema_version
		end

	item_count (a_kind: INTEGER; a_hub_id: INTEGER_64): INTEGER
			-- Live (not deleted) items of `a_kind' on `a_hub_id'.
		require
			kind_valid: is_valid_kind (a_kind)
		do
			-- Phase 4
		ensure
			non_negative: Result >= 0
		end

	highlights_for (a_hub_id: INTEGER_64): ARRAYED_LIST [BIB_HIGHLIGHT]
			-- Live highlights on `a_hub_id', whatever version they were made in.
		require
			open: is_open
		do
			check implemented_in_phase_4: False then end
		ensure
			version_independent: across Result as h all h.hub_id = a_hub_id and not h.is_deleted end
			counted: Result.count = item_count (Kind_highlight, a_hub_id)
		end

	setting (a_key: STRING_8): STRING_32
		require
			known: has_setting (a_key)
		do
			if attached settings.item (a_key) as l_value then
				Result := l_value
			else
				check known: False then end
			end
		ensure
			model_agrees: Result ~ settings_model [a_key]
		end

	layout_count: INTEGER
		do
			-- Phase 4
		end

	total_note_versions: INTEGER
			-- All note versions ever written (notes are append-only).
		do
			-- Phase 4
		end

	census_run (a_run_id: INTEGER_64): detachable BIB_CENSUS_RUN
		do
			-- Phase 4
		end

feature -- Status

	is_read_only: BOOLEAN
			-- The user store is the one writable source.
		do
			Result := False
		end

	is_provenance_schema_valid: BOOLEAN
			-- User data is the reader's own: no source_provenance column applies.
		do
			Result := True
		end

	is_deleted (a_id: INTEGER_64): BOOLEAN
		do
			-- Phase 4
		end

	has_setting (a_key: STRING_8): BOOLEAN
		do
			Result := settings.has (a_key)
		ensure
			model_agrees: Result = settings_model.domain [a_key]
		end

	is_valid_kind (a_kind: INTEGER): BOOLEAN
		do
			Result := a_kind >= Kind_note and a_kind <= Kind_visit
		end

feature -- Commands: annotations

	add_highlight (a_highlight: BIB_HIGHLIGHT)
		require
			open: is_open
			not_stored: not a_highlight.is_stored
		do
			-- Phase 4
		ensure
			stored: last_error = Void implies a_highlight.is_stored
			count_grown: last_error = Void implies item_count (Kind_highlight, a_highlight.hub_id) = old item_count (Kind_highlight, a_highlight.hub_id) + 1
			others_unchanged: item_count (Kind_bookmark, a_highlight.hub_id) = old item_count (Kind_bookmark, a_highlight.hub_id)
				and item_count (Kind_tag, a_highlight.hub_id) = old item_count (Kind_tag, a_highlight.hub_id)
		end

	add_bookmark (a_bookmark: BIB_BOOKMARK)
		require
			open: is_open
			not_stored: not a_bookmark.is_stored
		do
			-- Phase 4
		ensure
			stored: last_error = Void implies a_bookmark.is_stored
			count_grown: last_error = Void implies item_count (Kind_bookmark, a_bookmark.hub_id) = old item_count (Kind_bookmark, a_bookmark.hub_id) + 1
			others_unchanged: item_count (Kind_highlight, a_bookmark.hub_id) = old item_count (Kind_highlight, a_bookmark.hub_id)
		end

	tag_verse (a_tag: BIB_TAG_ASSIGNMENT)
		require
			open: is_open
			not_stored: not a_tag.is_stored
		do
			-- Phase 4
		ensure
			stored: last_error = Void implies a_tag.is_stored
			count_grown: last_error = Void implies item_count (Kind_tag, a_tag.hub_id) = old item_count (Kind_tag, a_tag.hub_id) + 1
		end

	record_visit (a_visit: BIB_VISIT)
		require
			open: is_open
			not_stored: not a_visit.is_stored
		do
			-- Phase 4
		ensure
			stored: last_error = Void implies a_visit.is_stored
		end

	remove_item (a_kind: INTEGER; a_id: INTEGER_64)
			-- Soft-delete item `a_id' (every kind: restorable).
		require
			open: is_open
			kind_valid: is_valid_kind (a_kind) and a_kind /= Kind_note
			stored: a_id > 0
		do
			-- Phase 4
		ensure
			soft_deleted: last_error = Void implies is_deleted (a_id)
		end

	restore_item (a_kind: INTEGER; a_id: INTEGER_64)
		require
			open: is_open
			kind_valid: is_valid_kind (a_kind) and a_kind /= Kind_note
			deleted: is_deleted (a_id)
		do
			-- Phase 4
		ensure
			restored: last_error = Void implies not is_deleted (a_id)
		end

feature -- Commands: settings, layouts, census

	set_setting (a_key: STRING_8; a_value: READABLE_STRING_GENERAL)
		require
			key_not_empty: not a_key.is_empty
		do
			-- Phase 4: write through to user.db, then update `settings'.
		ensure
			set: last_error = Void implies settings_model |=| old settings_model.updated (a_key, a_value.to_string_32)
			unchanged_on_error: last_error /= Void implies settings_model |=| old settings_model
		end

	save_layout_snapshot (a_mode: STRING_8; a_snapshot: READABLE_STRING_GENERAL)
		require
			open: is_open
			mode_named: not a_mode.is_empty
		do
			-- Phase 4
		ensure
			saved: last_error = Void implies layout_count >= old layout_count
			settings_unchanged: settings_model |=| old settings_model
		end

	store_census_definition (a_definition: BIB_CENSUS_DEFINITION)
			-- Write a definition down before it runs (I-002).
		require
			open: is_open
			not_stored: not a_definition.is_stored
		do
			-- Phase 4: insert; a_definition.mark_stored (id, lineage)
		ensure
			stored: last_error = Void implies a_definition.is_stored
			unfrozen: a_definition.is_frozen = old a_definition.is_frozen
		end

	store_census_run (a_run: BIB_CENSUS_RUN)
		require
			open: is_open
			complete_run: not a_run.was_cancelled
		do
			-- Phase 4
		ensure
			retrievable: last_error = Void implies (attached census_run (a_run.id) as r and then r.id = a_run.id)
		end

feature -- Commands: schema

	migrate (a_from_version, a_to_version: INTEGER)
			-- Upgrade a previous-schema user.db, preserving everything.
		require
			open: is_open
			forward: a_to_version > a_from_version
		do
			-- Phase 4: simple_sql migration runner.
		ensure
			settings_preserved: last_error = Void implies settings_model |=| old settings_model
			layouts_preserved: last_error = Void implies layout_count = old layout_count
			notes_preserved: last_error = Void implies total_note_versions = old total_note_versions
			schema_upgraded: last_error = Void implies schema_version = a_to_version
		end

	open_on (a_set: BIB_SOURCE_SET)
			-- Open user.db read-write as the main database of the user-store processor's own set.
		do
			-- Phase 4
		end

	close
		do
			-- Phase 4: rotating backup is written by BIB_USER_BACKUP on exit.
		end

feature -- Model

	settings_model: MML_MAP [STRING_8, STRING_32]
		do
			create Result
			across settings as s loop
				Result := Result.updated (@s.key, s)
			end
		end

feature -- Constants

	User_schema_version: INTEGER = 1

	Kind_note: INTEGER = 1
	Kind_highlight: INTEGER = 2
	Kind_bookmark: INTEGER = 3
	Kind_tag: INTEGER = 4
	Kind_visit: INTEGER = 5

feature {NONE} -- Representation

	settings: HASH_TABLE [STRING_32, STRING_8]

invariant
	only_writer: not is_read_only

end
