note
	description: "[
		One verse in every requested version, with words and cross-references
		(FR-021). Each version answers with its text or a typed omission, never
		an empty string (AC-1a-19); every version reports its verse count and
		seal (AC-1a-31); no label is a bare "LXX" (AC-1a-35).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_VERSE_HUB

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET; a_versification: BIB_VERSIFICATION_MAP)
			-- Create the hub (version infos loaded from core.db in Phase 4).
		do
			sources := a_sources
			versification := a_versification
			create version_infos.make (16)
			create reducer
		ensure
			versification_set: versification = a_versification
		end

feature -- Access

	versification: BIB_VERSIFICATION_MAP

	reducer: BIB_POINTING_REDUCER
			-- Derived Hebrew forms (FR-113).

	version_count: INTEGER
		do
			Result := version_infos.count
		ensure
			model_agrees: Result = versions_model.count
		end

	version_info (a_code: READABLE_STRING_8): BIB_VERSION_INFO
			-- Metadata of version `a_code'.
		require
			known: has_version (a_code)
		do
			if attached version_infos.item (a_code.to_string_8) as l_info then
				Result := l_info
			else
				check known: False then end
			end
		ensure
			model_agrees: Result = versions_model [a_code.to_string_8]
		end

feature -- Status

	has_version (a_code: READABLE_STRING_8): BOOLEAN
			-- Is `a_code' a shipped version?
		do
			Result := version_infos.has (a_code.to_string_8)
		ensure
			model_agrees: Result = versions_model.domain [a_code.to_string_8]
		end

feature -- Lookup

	verse (a_mapped: BIB_MAPPED_REF; a_versions: ARRAY [STRING_8]): BIB_VERSE_RESULT
			-- `a_mapped' in each of `a_versions', with words and cross-references.
		require
			versions_given: not a_versions.is_empty
			versions_known: across a_versions as v all has_version (v) end
		do
			check implemented_in_phase_4: False then end
		ensure
			every_version_answered: Result.is_success implies Result.version_count = a_versions.count
			same_verse: Result.is_success implies Result.mapped = a_mapped
			method_recorded: Result.method.engine_feature.same_string_general ("verse")
			fact_closure: Result.is_fact_closed
		end

	chapter (a_mapped: BIB_MAPPED_REF; a_version: STRING_8): BIB_LIST_RESULT [BIB_VERSE_TEXT]
			-- The chapter containing `a_mapped' in `a_version', for reading.
		require
			version_known: has_version (a_version)
		do
			check implemented_in_phase_4: False then end
		ensure
			one_version: across 1 |..| Result.count as i all Result.item (i).version.code.same_string (a_version) end
			method_recorded: Result.method.engine_feature.same_string_general ("chapter")
			fact_closure: Result.is_fact_closed
		end

	word (a_id: BIB_WORD_ID): detachable BIB_WORD
			-- Word card for token `a_id' (Void when unknown).
		do
			-- Phase 4
		ensure
			same_token: attached Result implies Result.id ~ a_id
		end

	reduced_pointing (a_text: READABLE_STRING_32; a_level: INTEGER): STRING_32
			-- Derived Hebrew form; stored text unchanged (FR-113).
		require
			level_valid: reducer.is_valid_level (a_level)
		do
			Result := reducer.reduced (a_text, a_level)
		ensure
			full_is_identity: a_level = reducer.Level_full implies Result.same_string (a_text)
		end

feature -- Model

	versions_model: MML_MAP [STRING_8, BIB_VERSION_INFO]
			-- Shipped versions by code.
		do
			create Result
			across version_infos as v loop
				Result := Result.updated (@v.key, v)
			end
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET
	version_infos: HASH_TABLE [BIB_VERSION_INFO, STRING_8]

end
