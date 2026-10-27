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

	BIB_SQLITE_REPORTING
		export
			{BIB_NOTE_STORE} first_integer, first_text, failure_text
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
			if attached database as al_db then
				Result := first_integer (al_db.query_with_args ("SELECT count(*) AS n FROM user_item WHERE kind = ? AND hub_id = ? AND " + Live_item_filter, <<a_kind, a_hub_id>>))
			end
		ensure
			non_negative: Result >= 0
		end

	highlights_for (a_hub_id: INTEGER_64): ARRAYED_LIST [BIB_HIGHLIGHT]
			-- Live highlights on `a_hub_id', whatever version they were made in.
		require
			open: is_open
		do
			Result := highlights_between (a_hub_id, a_hub_id)
		ensure
			version_independent: across Result as h all h.hub_id = a_hub_id and not h.is_deleted end
			counted: Result.count = item_count (Kind_highlight, a_hub_id)
		end

	highlights_between (a_first_hub, a_last_hub: INTEGER_64): ARRAYED_LIST [BIB_HIGHLIGHT]
			-- Live highlights on the verses `a_first_hub' to `a_last_hub' (a chapter, or every verse),
			-- in verse order, then oldest first.
		require
			open: is_open
			ordered: a_first_hub <= a_last_hub
		local
			l_highlight: BIB_HIGHLIGHT
		do
			create Result.make (8)
			across connection.query_with_args ("SELECT item_id, hub_id, label, created_at FROM user_item WHERE kind = ? AND hub_id BETWEEN ? AND ? AND " + Live_item_filter + " ORDER BY hub_id, item_id",
				<<Kind_highlight, a_first_hub, a_last_hub>>).rows as ic loop
				create l_highlight.make (ic.integer_64_value ("hub_id"), ic.string_value ("label"))
				l_highlight.mark_stored (ic.integer_64_value ("item_id"), time_of (ic.string_value ("created_at")))
				Result.extend (l_highlight)
			end
		ensure
			in_range: across Result as ic all ic.hub_id >= a_first_hub and ic.hub_id <= a_last_hub and not ic.is_deleted end
		end

	bookmarks: ARRAYED_LIST [BIB_BOOKMARK]
			-- Every live bookmark, newest first.
		require
			open: is_open
		local
			l_bookmark: BIB_BOOKMARK
		do
			create Result.make (8)
			across connection.query_with_args ("SELECT item_id, hub_id, label, created_at FROM user_item WHERE kind = ? AND " + Live_item_filter + " ORDER BY item_id DESC", <<Kind_bookmark>>).rows as ic loop
				create l_bookmark.make (ic.integer_64_value ("hub_id"), ic.string_value ("label"))
				l_bookmark.mark_stored (ic.integer_64_value ("item_id"), time_of (ic.string_value ("created_at")))
				Result.extend (l_bookmark)
			end
		end

	recent_places (a_limit: INTEGER): ARRAYED_LIST [BIB_VISIT]
			-- History (2026-10-27): the newest visit of each chapter, newest first, at most `a_limit'.
			-- Visits are never pruned (DR-024: user data is never lost); a heavy reader adds some
			-- thousands a year, which SQLite groups in well under a millisecond (scan 46).
		require
			open: is_open
			limit_positive: a_limit > 0
			limit_capped: a_limit <= Max_recent_places
		local
			l_visit: BIB_VISIT
		do
			create Result.make (a_limit.min (64))
			across connection.query_with_args ("SELECT item_id, hub_id, label, created_at FROM user_item WHERE item_id IN (SELECT max(item_id) FROM user_item WHERE kind = ? AND " + Live_item_filter + " GROUP BY hub_id / " + {BIB_HUB_ID}.Chapter_unit.out + ") ORDER BY item_id DESC LIMIT ?", <<Kind_visit, a_limit>>).rows as ic loop
				create l_visit.make (ic.integer_64_value ("hub_id"), ic.string_value ("label"))
				l_visit.mark_stored (ic.integer_64_value ("item_id"), time_of (ic.string_value ("created_at")))
				Result.extend (l_visit)
			end
		ensure
			at_most_the_limit: Result.count <= a_limit
			one_per_chapter: across Result as ic all across Result as jc all ic.hub_id // {BIB_HUB_ID}.Chapter_unit = jc.hub_id // {BIB_HUB_ID}.Chapter_unit implies ic.id = jc.id end end
		end

	tag_counts: ARRAYED_LIST [TUPLE [tag: STRING_32; verses: INTEGER]]
			-- Every live tag and how many verses carry it, by tag (E05).
		require
			open: is_open
		do
			create Result.make (8)
			across connection.query_with_args ("SELECT label, count(*) AS n FROM user_item WHERE kind = ? AND " + Live_item_filter + " GROUP BY label ORDER BY label COLLATE NOCASE", <<Kind_tag>>).rows as ic loop
				Result.extend ([ic.string_value ("label"), ic.integer_value ("n")])
			end
		ensure
			counted: across Result as ic all ic.verses >= 1 and not ic.tag.is_empty end
		end

	assignments_tagged (a_tag: READABLE_STRING_GENERAL): ARRAYED_LIST [BIB_TAG_ASSIGNMENT]
			-- The live assignments of tag `a_tag', in verse order.
		require
			open: is_open
			tag_given: not a_tag.is_empty
		do
			Result := tag_rows ("SELECT item_id, hub_id, label, created_at FROM user_item WHERE kind = ? AND " + Live_item_filter + " AND label = ? ORDER BY hub_id, item_id", <<Kind_tag, a_tag.to_string_32>>)
		ensure
			that_tag: across Result as ic all ic.tag.same_string_general (a_tag) end
		end

	tags_for (a_hub_id: INTEGER_64): ARRAYED_LIST [BIB_TAG_ASSIGNMENT]
			-- The live tags on verse `a_hub_id', oldest first.
		require
			open: is_open
		do
			Result := tag_rows ("SELECT item_id, hub_id, label, created_at FROM user_item WHERE kind = ? AND hub_id = ? AND " + Live_item_filter + " ORDER BY item_id", <<Kind_tag, a_hub_id>>)
		ensure
			on_that_verse: across Result as ic all ic.hub_id = a_hub_id end
			counted: Result.count = item_count (Kind_tag, a_hub_id)
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

	last_backup_path: STRING_32
			-- The copy `open' made before upgrading user.db; empty when it made none.
		attribute
			create Result.make_empty
		end

	layout_count: INTEGER
		do
			-- Phase 4
		end

	total_note_versions: INTEGER
			-- All note versions ever written (notes are append-only).
		do
			if attached database as al_db then
				Result := first_integer (al_db.query ("SELECT count(*) AS n FROM note_version"))
			end
		ensure
			non_negative: Result >= 0
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
			-- Is user item `a_id' soft-deleted?
		do
			if attached database as al_db then
				Result := first_integer (al_db.query_with_args ("SELECT count(*) AS n FROM user_item WHERE item_id = ? AND deleted = 1", <<a_id>>)) = 1
			end
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
			-- Keep `a_highlight' (its reason in `label').
		require
			open: is_open
			not_stored: not a_highlight.is_stored
		do
			add_item (a_highlight, a_highlight.reason)
		ensure
			stored: write_error = Void implies a_highlight.is_stored
			count_grown: write_error = Void implies item_count (Kind_highlight, a_highlight.hub_id) = old item_count (Kind_highlight, a_highlight.hub_id) + 1
			others_unchanged: item_count (Kind_bookmark, a_highlight.hub_id) = old item_count (Kind_bookmark, a_highlight.hub_id)
				and item_count (Kind_tag, a_highlight.hub_id) = old item_count (Kind_tag, a_highlight.hub_id)
		end

	add_bookmark (a_bookmark: BIB_BOOKMARK)
		require
			open: is_open
			not_stored: not a_bookmark.is_stored
		do
			add_item (a_bookmark, a_bookmark.label)
		ensure
			stored: write_error = Void implies a_bookmark.is_stored
			count_grown: write_error = Void implies item_count (Kind_bookmark, a_bookmark.hub_id) = old item_count (Kind_bookmark, a_bookmark.hub_id) + 1
			others_unchanged: item_count (Kind_highlight, a_bookmark.hub_id) = old item_count (Kind_highlight, a_bookmark.hub_id)
		end

	tag_verse (a_tag: BIB_TAG_ASSIGNMENT)
		require
			open: is_open
			not_stored: not a_tag.is_stored
		do
			add_item (a_tag, a_tag.tag)
		ensure
			stored: write_error = Void implies a_tag.is_stored
			count_grown: write_error = Void implies item_count (Kind_tag, a_tag.hub_id) = old item_count (Kind_tag, a_tag.hub_id) + 1
		end

	record_visit (a_visit: BIB_VISIT)
		require
			open: is_open
			not_stored: not a_visit.is_stored
		do
			add_item (a_visit, a_visit.context)
		ensure
			stored: write_error = Void implies a_visit.is_stored
		end

	remove_item (a_kind: INTEGER; a_id: INTEGER_64)
			-- Soft-delete item `a_id' (every kind: restorable).
		require
			open: is_open
			kind_valid: is_valid_kind (a_kind) and a_kind /= Kind_note
			stored: a_id > 0
		do
			set_item_deleted (a_kind, a_id, True)
		ensure
			soft_deleted: write_error = Void implies is_deleted (a_id)
		end

	restore_item (a_kind: INTEGER; a_id: INTEGER_64)
		require
			open: is_open
			kind_valid: is_valid_kind (a_kind) and a_kind /= Kind_note
			deleted: is_deleted (a_id)
		do
			set_item_deleted (a_kind, a_id, False)
		ensure
			restored: write_error = Void implies not is_deleted (a_id)
		end

feature -- Prayer (E06, schema 2)

	add_prayer_item (a_prayer: BIB_PRAYER)
			-- Keep `a_prayer' on the list.
		require
			open: is_open
			not_stored: a_prayer.id = 0
		local
			l_at: STRING_8
		do
			write_error := Void
			l_at := now_text
			connection.execute_with_args ("INSERT INTO prayer(title, body, hub_id, created_at) VALUES (?, ?, ?, ?)", <<a_prayer.title, a_prayer.body, a_prayer.hub_id, l_at>>)
			if connection.has_error then
				create write_error.make ({BIB_ERROR}.Database_problem, failure_text (connection, "The prayer could not be saved."))
			else
				a_prayer.mark_stored (connection.last_insert_rowid, l_at)
			end
		ensure
			stored: write_error = Void implies a_prayer.id > 0
		end

	set_prayer_answered (a_id: INTEGER_64; a_answer: READABLE_STRING_GENERAL)
			-- Prayer `a_id' answered today, `a_answer' in the reader's words.
		require
			open: is_open
			stored: a_id > 0
		do
			write_error := Void
			connection.execute_with_args ("UPDATE prayer SET answered_at = ?, answer = ? WHERE prayer_id = ? AND deleted = 0", <<now_text, a_answer.to_string_32, a_id>>)
			if connection.has_error then
				create write_error.make ({BIB_ERROR}.Database_problem, failure_text (connection, "The prayer could not be changed."))
			elseif connection.changes_count /= 1 then
				create write_error.make ({BIB_ERROR}.Not_found, {STRING_32} "No such prayer: " + a_id.out)
			end
		end

	set_prayer_deleted (a_id: INTEGER_64; a_deleted: BOOLEAN)
			-- Prayer `a_id' removed (kept, restorable) or restored.
		require
			open: is_open
			stored: a_id > 0
		local
			l_flag: INTEGER
		do
			write_error := Void
			if a_deleted then
				l_flag := 1
			end
			connection.execute_with_args ("UPDATE prayer SET deleted = ? WHERE prayer_id = ?", <<l_flag, a_id>>)
			if connection.has_error then
				create write_error.make ({BIB_ERROR}.Database_problem, failure_text (connection, "The prayer could not be changed."))
			elseif connection.changes_count /= 1 then
				create write_error.make ({BIB_ERROR}.Not_found, {STRING_32} "No such prayer: " + a_id.out)
			end
		end

	prayers (a_answered: BOOLEAN): ARRAYED_LIST [BIB_PRAYER]
			-- The live prayers still open (newest first), or answered (latest answer first).
		require
			open: is_open
		local
			l_prayer: BIB_PRAYER
			l_sql: STRING_8
		do
			create Result.make (8)
			if a_answered then
				l_sql := "SELECT prayer_id, title, body, hub_id, created_at, answered_at, answer FROM prayer WHERE deleted = 0 AND answered_at <> '' AND title <> '' ORDER BY answered_at DESC, prayer_id DESC"
			else
				l_sql := "SELECT prayer_id, title, body, hub_id, created_at, answered_at, answer FROM prayer WHERE deleted = 0 AND answered_at = '' AND title <> '' ORDER BY prayer_id DESC"
			end
			across connection.query (l_sql).rows as ic loop
				if ic.integer_64_value ("hub_id") >= 0 then
					create l_prayer.make (ic.string_value ("title"), ic.string_value ("body"), ic.integer_64_value ("hub_id"))
					l_prayer.mark_stored (ic.integer_64_value ("prayer_id"), ic.string_value ("created_at"))
					if not ic.string_value ("answered_at").is_empty then
						l_prayer.mark_answered (ic.string_value ("answered_at"), ic.string_value ("answer"))
					end
					Result.extend (l_prayer)
				end
			end
		ensure
			that_kind: across Result as ic all ic.is_answered = a_answered end
		end

feature -- Memory cards (E07, schema 2)

	add_memory_card (a_card: BIB_MEMORY_CARD)
			-- Keep `a_card' (a verse to learn).
		require
			open: is_open
			not_stored: a_card.id = 0
			one_card_a_verse: not has_memory_card (a_card.hub_id)
		do
			write_error := Void
			connection.execute_with_args ("INSERT INTO memory_card(hub_id, created_at, due_on, interval_days, ease_percent, repetitions) VALUES (?, ?, ?, ?, ?, ?)",
				<<a_card.hub_id, now_text, a_card.due_on, a_card.interval_days, a_card.ease_percent, a_card.repetitions>>)
			if connection.has_error then
				create write_error.make ({BIB_ERROR}.Database_problem, failure_text (connection, "The card could not be saved."))
			else
				a_card.mark_stored (connection.last_insert_rowid)
			end
		ensure
			stored: write_error = Void implies a_card.id > 0
		end

	has_memory_card (a_hub_id: INTEGER_64): BOOLEAN
			-- Is verse `a_hub_id' already a live card?
		require
			open: is_open
		do
			Result := first_integer (connection.query_with_args ("SELECT count(*) AS n FROM memory_card WHERE hub_id = ? AND deleted = 0", <<a_hub_id>>)) > 0
		end

	memory_cards (a_due_by: READABLE_STRING_GENERAL): ARRAYED_LIST [BIB_MEMORY_CARD]
			-- The live cards due on or before `a_due_by' (ISO date), soonest first; every card when
			-- `a_due_by' is empty.
		require
			open: is_open
		local
			l_card: BIB_MEMORY_CARD
		do
			create Result.make (8)
			across connection.query_with_args ("SELECT card_id, hub_id, due_on, interval_days, ease_percent, repetitions FROM memory_card WHERE deleted = 0 AND hub_id > 0 AND (? = '' OR due_on <= ?) ORDER BY due_on, card_id",
					<<a_due_by.to_string_32, a_due_by.to_string_32>>).rows as ic loop
				if not ic.string_value ("due_on").is_empty and ic.integer_value ("ease_percent") >= {BIB_MEMORY_SCHEDULE}.Least_ease then
					create l_card.make (ic.integer_64_value ("hub_id"), ic.string_value ("due_on"))
					l_card.mark_stored (ic.integer_64_value ("card_id"))
					l_card.set_state (ic.string_value ("due_on"), ic.integer_value ("interval_days").max (0), ic.integer_value ("ease_percent"), ic.integer_value ("repetitions").max (0))
					Result.extend (l_card)
				end
			end
		ensure
			all_due: not a_due_by.is_empty implies across Result as ic all ic.is_due (a_due_by) end
		end

	record_review (a_card: BIB_MEMORY_CARD; a_grade: INTEGER; a_today: SIMPLE_DATE)
			-- `a_card' reviewed on `a_today' with grade `a_grade' (0 to 5): its next date by
			-- BIB_MEMORY_SCHEDULE, the review kept in memory_review.
		require
			open: is_open
			stored: a_card.id > 0
			grade_valid: a_grade >= 0 and a_grade <= 5
		local
			l_schedule: BIB_MEMORY_SCHEDULE
			l_interval, l_ease, l_repetitions: INTEGER
			l_due: STRING_8
		do
			write_error := Void
			create l_schedule
			l_interval := l_schedule.next_interval (a_card.repetitions, a_card.interval_days, a_card.ease_percent, a_grade)
			l_ease := l_schedule.next_ease (a_card.ease_percent, a_grade)
			l_repetitions := l_schedule.next_repetitions (a_card.repetitions, a_grade)
			l_due := a_today.plus_days (l_interval).to_iso8601
			connection.begin_transaction
			connection.execute_with_args ("UPDATE memory_card SET due_on = ?, interval_days = ?, ease_percent = ?, repetitions = ? WHERE card_id = ? AND deleted = 0",
				<<l_due, l_interval, l_ease, l_repetitions, a_card.id>>)
			if not connection.has_error and then connection.changes_count = 1 then
				connection.execute_with_args ("INSERT INTO memory_review(card_id, reviewed_on, grade, interval_days, ease_percent) VALUES (?, ?, ?, ?, ?)",
					<<a_card.id, a_today.to_iso8601, a_grade, l_interval, l_ease>>)
			end
			if connection.has_error then
				create write_error.make ({BIB_ERROR}.Database_problem, failure_text (connection, "The review could not be saved."))
				connection.rollback
			elseif connection.changes_count /= 1 then
				create write_error.make ({BIB_ERROR}.Not_found, {STRING_32} "No such card: " + a_card.id.out)
				connection.rollback
			else
				connection.commit
				a_card.set_state (l_due, l_interval, l_ease, l_repetitions)
			end
		ensure
			moved: write_error = Void implies a_card.repetitions = (create {BIB_MEMORY_SCHEDULE}).next_repetitions (old a_card.repetitions, a_grade)
		end

	set_memory_card_deleted (a_id: INTEGER_64; a_deleted: BOOLEAN)
			-- Card `a_id' removed (kept, restorable) or restored.
		require
			open: is_open
			stored: a_id > 0
		local
			l_flag: INTEGER
		do
			write_error := Void
			if a_deleted then
				l_flag := 1
			end
			connection.execute_with_args ("UPDATE memory_card SET deleted = ? WHERE card_id = ?", <<l_flag, a_id>>)
			if connection.has_error then
				create write_error.make ({BIB_ERROR}.Database_problem, failure_text (connection, "The card could not be changed."))
			elseif connection.changes_count /= 1 then
				create write_error.make ({BIB_ERROR}.Not_found, {STRING_32} "No such card: " + a_id.out)
			end
		end

feature -- Commands: settings, layouts, census

	set_setting (a_key: STRING_8; a_value: READABLE_STRING_GENERAL)
			-- Write through to user.db when open, then keep it in `settings'.
		require
			key_not_empty: not a_key.is_empty
		do
			write_error := Void
			if attached database as al_db then
				al_db.execute_with_args ("INSERT INTO setting(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value",
					<<a_key, a_value.to_string_32>>)
				if al_db.has_error then
					create write_error.make ({BIB_ERROR}.Database_problem, failure_text (al_db, "The setting could not be saved."))
				end
			end
				-- Kept for this run even when the write failed (`write_error' says so): `last_error'
				-- is only for a failed open (BIB_DATA_SOURCE's invariant).
			settings.force (a_value.to_string_32, a_key)
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
			-- Upgrade a previous-schema user.db, preserving everything (`open' does this itself for a
			-- version-1 file: a backup, then tables added, never a row changed).
		require
			open: is_open
			forward: a_to_version > a_from_version
		do
			if attached database as al_db and then a_from_version = 1 and then a_to_version = User_schema_version and then schema_version = 1 then
				upgrade_from_1 (al_db)
				if last_error = Void then
					schema_version := first_integer (al_db.query ("PRAGMA user_version"))
				end
			end
		ensure
			settings_preserved: last_error = Void implies settings_model |=| old settings_model
			layouts_preserved: last_error = Void implies layout_count = old layout_count
			notes_preserved: last_error = Void implies total_note_versions = old total_note_versions
			schema_upgraded: last_error = Void implies schema_version = a_to_version
		end

	open_on (a_set: BIB_SOURCE_SET)
			-- Open user.db read-write on the user-store processor's own connection (the one
			-- writable source never joins the read-only content connection of `a_set').
		do
			open
		end

	open
			-- Open user.db read-write, creating it (and its folder) with schema version
			-- `User_schema_version' when missing or empty; a user.db of another schema version is refused (its migration is
			-- not built yet) and left untouched.
		require
			not_open: not is_open
		local
			l_db: SIMPLE_SQL_DATABASE
			l_version: INTEGER
			l_folder: STRING_32
		do
			last_error := Void
			has_required_tables := False
			l_folder := (create {SIMPLE_FILE}.make (path)).parent_path
			if not ((create {SIMPLE_FILE}.make (l_folder)).is_directory or else (create {SIMPLE_FILE}.make (l_folder)).create_directory_recursive) then
				create last_error.make ({BIB_ERROR}.Source_unavailable, {STRING_32} "The folder for user.db could not be made: " + l_folder)
			else
				create l_db.make (path)
				if l_db.has_error then
					create last_error.make ({BIB_ERROR}.Database_problem, {STRING_32} "user.db could not be opened: " + path)
				else
					l_version := first_integer (l_db.query ("PRAGMA user_version"))
					if l_version = 0 then
						create_schema (l_db)
						l_version := first_integer (l_db.query ("PRAGMA user_version"))
					elseif l_version = 1 then
							-- Schema 2 (2026-10-27): prayer and memory cards. A backup first, then tables added.
						upgrade_from_1 (l_db)
						l_version := first_integer (l_db.query ("PRAGMA user_version"))
					end
					if last_error = Void and l_version /= User_schema_version then
						create last_error.make ({BIB_ERROR}.Schema_mismatch, {STRING_32} "user.db has schema version " + l_version.out
							+ {STRING_32} "; this program reads version " + User_schema_version.out + {STRING_32} ".")
					end
				end
				if last_error = Void then
					schema_version := l_version
					has_required_tables := True
					sqlite_version := first_text (l_db.query ("SELECT sqlite_version() AS n"))
					load_settings (l_db)
					database := l_db
					is_open := True
				else
					l_db.close
				end
			end
		ensure
			open_or_error: is_open xor (last_error /= Void)
			schema_checked: is_open implies schema_version = expected_schema_version
		end

	close
			-- Close user.db (a rotating backup is BIB_USER_BACKUP's, on exit).
		do
			if attached database as al_db then
				al_db.close
			end
			database := Void
			is_open := False
		end

feature -- Status

	write_error: detachable BIB_ERROR
			-- Why the last write into an open user.db failed - a setting, a highlight, a bookmark, a
			-- tag, a removal (`last_error' is only for a failed open). Scan 42: item writes had a
			-- second, hidden error and their postconditions tested `last_error', so a failed write
			-- broke a contract.

feature {BIB_NOTE_STORE} -- Connection

	connection: SIMPLE_SQL_DATABASE
			-- The open read-write connection to user.db.
		require
			open: is_open
		do
			check attached database as al_db then
				Result := al_db
			end
		end

	now_text: STRING_8
			-- The time now, as user.db stores times (ISO 8601).
		do
			Result := (create {SIMPLE_DATE_TIME}.make_now).to_iso8601
		end


feature {NONE} -- Items

	Live_item_filter: STRING_8 = "deleted = 0 AND hub_id > 0 AND label <> ''"
			-- What every query means by a live item: not deleted, on a verse, labelled. Scan 44: six
			-- spellings disagreed, so an unlabelled row was counted and not listed.

	add_item (a_item: BIB_USER_ITEM; a_label: READABLE_STRING_GENERAL)
			-- Keep `a_item' with `a_label' (a highlight's reason, a bookmark's label, a tag).
		require
			open: is_open
			not_stored: not a_item.is_stored
		local
			l_at: STRING_8
		do
			write_error := Void
			l_at := now_text
			connection.execute_with_args ("INSERT INTO user_item(kind, hub_id, label, created_at, changed_at) VALUES (?, ?, ?, ?, ?)",
				<<a_item.kind, a_item.hub_id, a_label.to_string_32, l_at, l_at>>)
			if connection.has_error then
				create write_error.make ({BIB_ERROR}.Database_problem, failure_text (connection, "The item could not be saved."))
			else
				a_item.mark_stored (connection.last_insert_rowid, time_of (l_at))
			end
		end

	set_item_deleted (a_kind: INTEGER; a_id: INTEGER_64; a_deleted: BOOLEAN)
			-- Mark item `a_id' of `a_kind' deleted or live.
		local
			l_flag: INTEGER
		do
			write_error := Void
			if a_deleted then
				l_flag := 1
			end
			connection.execute_with_args ("UPDATE user_item SET deleted = ?, changed_at = ? WHERE item_id = ? AND kind = ?", <<l_flag, now_text, a_id, a_kind>>)
			if connection.has_error then
				create write_error.make ({BIB_ERROR}.Database_problem, failure_text (connection, "The item could not be changed."))
			elseif connection.changes_count /= 1 then
					-- Scan 42: an id that names no item of this kind is no success.
				create write_error.make ({BIB_ERROR}.Not_found, {STRING_32} "No such item: " + a_id.out)
			end
		end

	tag_rows (a_sql: STRING_8; a_arguments: ARRAY [detachable ANY]): ARRAYED_LIST [BIB_TAG_ASSIGNMENT]
			-- The tag assignments `a_sql' selects (item_id, hub_id, label, created_at).
		local
			l_tag: BIB_TAG_ASSIGNMENT
		do
			create Result.make (8)
			across connection.query_with_args (a_sql, a_arguments).rows as ic loop
				if ic.integer_64_value ("hub_id") > 0 and not ic.string_value ("label").is_empty then
					create l_tag.make (ic.integer_64_value ("hub_id"), ic.string_value ("label"))
					l_tag.mark_stored (ic.integer_64_value ("item_id"), time_of (ic.string_value ("created_at")))
					Result.extend (l_tag)
				end
			end
		end

	time_of (a_text: READABLE_STRING_GENERAL): SIMPLE_DATE_TIME
			-- The time user.db stored as `a_text'.
		do
			create Result.make_from_iso8601 (a_text.to_string_8)
		end

feature {NONE} -- Schema

	database: detachable SIMPLE_SQL_DATABASE
			-- user.db while open.

	upgrade_from_1 (a_db: SIMPLE_SQL_DATABASE)
			-- Schema 1 to 2: copy the file first (SQLite's VACUUM INTO, a consistent copy beside it),
			-- then add the prayer and memory tables in one transaction; a failure leaves version 1 as
			-- it was. Nothing existing is changed (DR-024: user data is never lost by an upgrade).
		local
			l_backup: STRING_32
			n: INTEGER
		do
			l_backup := path + {STRING_32} ".schema-1-backup.db"
			from n := 2 until not (create {SIMPLE_FILE}.make (l_backup)).exists loop
				l_backup := path + {STRING_32} ".schema-1-backup-" + n.out + {STRING_32} ".db"
				n := n + 1
			end
			a_db.execute_with_args ("VACUUM INTO ?", {ARRAY [detachable ANY]} <<l_backup>>)
			if a_db.has_error or else not (create {SIMPLE_FILE}.make (l_backup)).is_file then
				create last_error.make ({BIB_ERROR}.Database_problem, failure_text (a_db, "user.db could not be backed up before its upgrade, so it was left as it is."))
			else
				last_backup_path := l_backup
				a_db.begin_transaction
				across Upgrade_2_statements as ic until last_error /= Void loop
					a_db.execute (ic)
					if a_db.has_error then
						create last_error.make ({BIB_ERROR}.Database_problem, failure_text (a_db, "user.db could not be upgraded; it is as it was."))
					end
				end
				if a_db.is_in_transaction then
					if last_error = Void then
						a_db.commit
						if a_db.has_error then
							create last_error.make ({BIB_ERROR}.Database_problem, failure_text (a_db, "user.db could not be upgraded; it is as it was."))
						end
					end
					if a_db.is_in_transaction then
						a_db.rollback
					end
				end
			end
		end

	Upgrade_2_statements: ARRAY [STRING_8]
			-- Schema 2's additions: a prayer list (answered or open) and memory cards with their reviews.
		once
			Result := <<
				"CREATE TABLE prayer(prayer_id INTEGER PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL, hub_id INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, answered_at TEXT NOT NULL DEFAULT '', answer TEXT NOT NULL DEFAULT '', deleted INTEGER NOT NULL DEFAULT 0)",
				"CREATE TABLE memory_card(card_id INTEGER PRIMARY KEY, hub_id INTEGER NOT NULL, created_at TEXT NOT NULL, due_on TEXT NOT NULL, interval_days INTEGER NOT NULL DEFAULT 0, ease_percent INTEGER NOT NULL DEFAULT 250, repetitions INTEGER NOT NULL DEFAULT 0, deleted INTEGER NOT NULL DEFAULT 0)",
				"CREATE TABLE memory_review(card_id INTEGER NOT NULL REFERENCES memory_card(card_id), reviewed_on TEXT NOT NULL, grade INTEGER NOT NULL, interval_days INTEGER NOT NULL, ease_percent INTEGER NOT NULL)",
				"CREATE INDEX ix_memory_due ON memory_card(deleted, due_on)",
				"PRAGMA user_version = 2">>
		end

	create_schema (a_db: SIMPLE_SQL_DATABASE)
			-- Schema version 1 (2026-10-27): notes with every version kept, the other user items,
			-- and settings. Every row keyed to a verse carries its hub id (BIB_HUB_ID). One
			-- transaction: a failure leaves an empty file that the next open sets up again (scan 39:
			-- a half-made user.db, its version still 0 but its first tables made, could never open).
		require
			still_closed: not is_open
		do
			a_db.begin_transaction
			across Schema_statements as ic until last_error /= Void loop
				a_db.execute (ic)
				if a_db.has_error then
					create last_error.make ({BIB_ERROR}.Database_problem, failure_text (a_db, "user.db could not be set up."))
				end
			end
				-- A new user.db is born at the current schema: version 1's tables, then 2's additions.
			across Upgrade_2_statements as ic until last_error /= Void loop
				a_db.execute (ic)
				if a_db.has_error then
					create last_error.make ({BIB_ERROR}.Database_problem, failure_text (a_db, "user.db could not be set up."))
				end
			end
			if a_db.is_in_transaction then
				if last_error = Void then
					a_db.commit
					if a_db.has_error then
						create last_error.make ({BIB_ERROR}.Database_problem, failure_text (a_db, "user.db could not be set up."))
					end
				end
				if a_db.is_in_transaction then
					a_db.rollback
				end
			end
		end

	Schema_statements: ARRAY [STRING_8]
		once
			Result := <<
				"CREATE TABLE note(note_id INTEGER PRIMARY KEY, hub_id INTEGER NOT NULL, title TEXT NOT NULL, created_at TEXT NOT NULL, changed_at TEXT NOT NULL, deleted INTEGER NOT NULL DEFAULT 0)",
				"CREATE TABLE note_version(note_id INTEGER NOT NULL REFERENCES note(note_id), version INTEGER NOT NULL, body TEXT NOT NULL, written_at TEXT NOT NULL, PRIMARY KEY (note_id, version)) WITHOUT ROWID",
				"CREATE INDEX ix_note_hub ON note(hub_id, deleted)",
				"CREATE TABLE user_item(item_id INTEGER PRIMARY KEY, kind INTEGER NOT NULL, hub_id INTEGER NOT NULL, label TEXT NOT NULL, created_at TEXT NOT NULL, changed_at TEXT NOT NULL, deleted INTEGER NOT NULL DEFAULT 0)",
				"CREATE INDEX ix_user_item_hub ON user_item(kind, hub_id, deleted)",
				"CREATE TABLE setting(key TEXT PRIMARY KEY, value TEXT NOT NULL)",
				"PRAGMA user_version = 1">>
		end

	load_settings (a_db: SIMPLE_SQL_DATABASE)
			-- `settings' as user.db holds them.
		do
			settings.wipe_out
			across a_db.query ("SELECT key, value FROM setting").rows as ic loop
				settings.force (ic.string_value ("value"), ic.string_value ("key").to_string_8)
			end
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

	User_schema_version: INTEGER = 2
			-- 1: notes, user items, settings (2026-10-27); 2: prayer and memory cards (2026-10-27).

	Kind_note: INTEGER = 1
	Kind_highlight: INTEGER = 2
	Kind_bookmark: INTEGER = 3
	Kind_tag: INTEGER = 4
	Kind_visit: INTEGER = 5

	Max_recent_places: INTEGER = 1000
			-- The most `recent_places' lists (its `one_per_chapter' check is quadratic: scan 46).

feature {NONE} -- Representation

	settings: HASH_TABLE [STRING_32, STRING_8]

invariant
	only_writer: not is_read_only

end
