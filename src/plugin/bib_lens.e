note
	description: "A reading applied to a passage (seam only; effective lenses live in the private repository)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_LENS

feature -- Access

	name: STRING_8
		deferred
		end

	plugin_name: STRING_8
		deferred
		end

	voice: BIB_VOICE
		deferred
		end

feature -- Status

	applies_to (a_ref: BIB_MAPPED_REF): BOOLEAN
		deferred
		end

feature -- Reading

	read (a_ref: BIB_MAPPED_REF; a_bible: SIMPLE_BIBLE): BIB_LENS_RESULT
		require
			applies: applies_to (a_ref)
			open: a_bible.is_open
		deferred
		ensure
			labeled: Result.voice ~ voice and Result.plugin_name.same_string_general (plugin_name)
			fact_closure: Result.is_fact_closed
		end

end
