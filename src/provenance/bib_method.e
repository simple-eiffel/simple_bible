note
	description: "[
		How a number or list was produced: engine feature, canonical query,
		corpus, scope label, versions, versification rules applied, counts,
		engine version, database edition and SQLite version. Re-running it on
		the same database yields the same counts (FR-032, AC-1a-31). Immutable.
		Every count states its scope (`scope_label', A-025, 13 S11).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_METHOD

create
	make

feature {NONE} -- Initialization

	make (a_engine_feature, a_canonical_query, a_corpus_label, a_scope_label: READABLE_STRING_GENERAL;
			a_versions, a_rule_notes: ITERABLE [READABLE_STRING_GENERAL]; a_counts: ITERABLE [INTEGER_64];
			a_engine_version, a_database_edition, a_sqlite_version: READABLE_STRING_GENERAL)
			-- Record one method.
		require
			engine_named: not a_engine_feature.is_empty
			query_recorded: not a_canonical_query.is_empty
			scope_stated: not a_scope_label.is_empty
			engine_version_recorded: not a_engine_version.is_empty
			edition_recorded: not a_database_edition.is_empty
			sqlite_recorded: not a_sqlite_version.is_empty
		do
			engine_feature := a_engine_feature.to_string_32
			canonical_query := a_canonical_query.to_string_32
			corpus_label := a_corpus_label.to_string_32
			scope_label := a_scope_label.to_string_32
			engine_version := a_engine_version.to_string_32
			database_edition := a_database_edition.to_string_32
			sqlite_version := a_sqlite_version.to_string_32
			create versions.make (4)
			across a_versions as v loop
				versions.extend (v.to_string_32)
			end
			create rule_notes.make (2)
			across a_rule_notes as r loop
				rule_notes.extend (r.to_string_32)
			end
			create counts.make (4)
			across a_counts as c loop
				counts.extend (c)
			end
		ensure
			engine_set: engine_feature.same_string_general (a_engine_feature)
			query_set: canonical_query.same_string_general (a_canonical_query)
			scope_set: scope_label.same_string_general (a_scope_label)
			edition_set: database_edition.same_string_general (a_database_edition)
			sqlite_set: sqlite_version.same_string_general (a_sqlite_version)
		end

feature -- Access

	engine_feature: STRING_32
			-- "verse", "census", "shape", "search", "concordance", ...

	canonical_query: STRING_32
			-- Parameters in canonical text form (clause tree, keys, references).

	corpus_label: STRING_32
			-- Corpus searched or counted.

	scope_label: STRING_32
			-- What a count counts: corpus, edition, unit ("NT, SBLGNT, word tokens").

	engine_version: STRING_32
			-- simple_bible engine version.

	database_edition: STRING_32
			-- Build id of core.db.

	sqlite_version: STRING_32
			-- SQLite library version (FR-NEW-008).

	version_count: INTEGER
			-- Number of versions consulted.
		do
			Result := versions.count
		end

	rules_count: INTEGER
			-- Number of versification rules applied.
		do
			Result := rule_notes.count
		end

	count_count: INTEGER
			-- Number of recorded counts.
		do
			Result := counts.count
		end

feature -- Status

	is_rerunnable: BOOLEAN
			-- Can this method be re-run?
		do
			Result := not canonical_query.is_empty
		end

	counts_equal (other: BIB_METHOD): BOOLEAN
			-- Element-wise equality of counts.
		do
			Result := counts_model |=| other.counts_model
		ensure
			definition: Result = (counts_model |=| other.counts_model)
		end

feature -- Model

	versions_model: MML_SEQUENCE [STRING_32]
			-- Versions consulted, in order.
		do
			create Result
			across versions as v loop
				Result := Result & v
			end
		end

	rule_notes_model: MML_SEQUENCE [STRING_32]
			-- Versification rules applied, in order.
		do
			create Result
			across rule_notes as r loop
				Result := Result & r
			end
		end

	counts_model: MML_SEQUENCE [INTEGER_64]
			-- Recorded counts, in order.
		do
			create Result
			across counts as c loop
				Result := Result & c
			end
		end

feature {NONE} -- Representation

	versions: ARRAYED_LIST [STRING_32]
	rule_notes: ARRAYED_LIST [STRING_32]
	counts: ARRAYED_LIST [INTEGER_64]

invariant
	query_recorded: not canonical_query.is_empty
	engine_named: not engine_feature.is_empty
	edition_recorded: not database_edition.is_empty
	sqlite_recorded: not sqlite_version.is_empty
	scope_stated: not scope_label.is_empty

end
