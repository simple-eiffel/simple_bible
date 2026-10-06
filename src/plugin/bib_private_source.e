note
	description: "[
		A private database attached when present, with its voice (D-014). Seam
		only: effective descendants live in Larry's private repository (scholars,
		transcripts, primary evidence); the public build contains none
		(FR-NEW-010, AC-1a-57).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_PRIVATE_SOURCE

inherit
	BIB_DATA_SOURCE

feature -- Access

	voice: BIB_VOICE
			-- How results from this source are labeled.
		deferred
		end

	plugin_name: STRING_8
			-- Plug-in that contributes this source.
		deferred
		ensure
			not_empty: not Result.is_empty
		end

end
