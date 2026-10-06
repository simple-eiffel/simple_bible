note
	description: "[
		The rix.db publication-scope exclusion RULE (RQ-08, AC-1a-14): Larry's
		own work ships in full (D-019); documents matching an APPROVED exclusion
		list (material centered on private individuals, raw AI chats) do not.

		The list is DATA fed in by the caller; this class assumes no list
		content. A pattern ending in "/" excludes a folder (relative-path
		prefix); any other pattern excludes one exact relative path. The rule
		answers only after the list is approved, and an approved list is sealed.
		The build pipeline's rix.db builder applies it with its own
		differential fixture; the list itself needs Larry's approval before the
		first public build.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_PUBLICATION_SCOPE_RULE

create
	make

feature {NONE} -- Initialization

	make (a_list_name: READABLE_STRING_GENERAL)
			-- An empty, unapproved list named `a_list_name'.
		require
			name_not_empty: not a_list_name.is_empty
		do
			list_name := a_list_name.to_string_32
			create approved_by.make_empty
			create approval_date.make_empty
			create exclusions.make (8)
		ensure
			named: list_name.same_string_general (a_list_name)
			empty: exclusion_count = 0
			not_approved: not is_approved
		end

feature -- Access

	list_name: STRING_32
	approved_by: STRING_32
	approval_date: STRING_8
			-- ISO 8601 date of approval.

	exclusion_count: INTEGER
		do
			Result := exclusions.count
		ensure
			model_agrees: Result = exclusions_model.count
		end

feature -- Status

	is_approved: BOOLEAN
			-- Has the list been approved (and so sealed)?

	is_folder_pattern (a_pattern: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := a_pattern.to_string_32.ends_with ({STRING_32} "/")
		end

	is_excluded (a_relpath: READABLE_STRING_GENERAL): BOOLEAN
			-- Does the approved list exclude the document at `a_relpath'?
		require
			approved: is_approved
			relpath_not_empty: not a_relpath.is_empty
		do
			-- Phase 4: exact match, or prefix match for folder patterns.
		ensure
			exact_match_excluded: exclusions_model [a_relpath.to_string_32] implies Result
		end

feature -- Element change

	add_exclusion (a_pattern: READABLE_STRING_GENERAL)
			-- Add a relative-path pattern (folder "x/y/" or exact "x/y.md").
		require
			not_approved: not is_approved
			pattern_not_empty: not a_pattern.is_empty
			relative: not a_pattern.to_string_32.starts_with ({STRING_32} "/")
			new_pattern: not exclusions_model [a_pattern.to_string_32]
		do
			exclusions.extend (a_pattern.to_string_32)
		ensure
			added: exclusions_model |=| (old exclusions_model & a_pattern.to_string_32)
			still_unapproved: not is_approved
		end

	approve (a_approver: READABLE_STRING_GENERAL; a_date: READABLE_STRING_8)
			-- Record the approval; the list is sealed from now on.
		require
			not_approved: not is_approved
			approver_named: not a_approver.is_empty
			date_given: a_date.count = 10
		do
			approved_by := a_approver.to_string_32
			approval_date := a_date.to_string_8
			is_approved := True
		ensure
			approved: is_approved
			list_unchanged: exclusions_model |=| old exclusions_model
		end

feature -- Model

	exclusions_model: MML_SET [STRING_32]
		do
			create Result
			across exclusions as e loop
				Result := Result & e
			end
		end

feature {NONE} -- Representation

	exclusions: ARRAYED_LIST [STRING_32]

invariant
	named: not list_name.is_empty
	approval_recorded: is_approved implies (not approved_by.is_empty and approval_date.count = 10)

end
