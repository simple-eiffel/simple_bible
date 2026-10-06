note
	description: "A lens reading, labeled by voice and plug-in (DR-018); its reading is a fact of the private source it came from."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LENS_RESULT

inherit
	BIB_ENGINE_RESULT

create
	make_success, make_failure

feature {NONE} -- Initialization

	make_success (a_lens_name, a_plugin_name: READABLE_STRING_GENERAL; a_voice: BIB_VOICE; a_reading: BIB_FACT [STRING_32]; a_method: BIB_METHOD; a_citations: ITERABLE [BIB_PROVENANCE])
		require
			lens_named: not a_lens_name.is_empty
			plugin_named: not a_plugin_name.is_empty
			cited: across a_citations as c some True end
		do
			lens_name := a_lens_name.to_string_32
			plugin_name := a_plugin_name.to_string_32
			voice := a_voice
			reading := a_reading
			set_success (a_method, a_citations)
		end

	make_failure (a_lens_name, a_plugin_name: READABLE_STRING_GENERAL; a_voice: BIB_VOICE; a_method: BIB_METHOD; a_error: BIB_ERROR)
		require
			lens_named: not a_lens_name.is_empty
			plugin_named: not a_plugin_name.is_empty
		do
			lens_name := a_lens_name.to_string_32
			plugin_name := a_plugin_name.to_string_32
			voice := a_voice
			set_failure (a_method, a_error)
		end

feature -- Access

	lens_name: STRING_32
	plugin_name: STRING_32
	voice: BIB_VOICE
	reading: detachable BIB_FACT [STRING_32]

feature -- Model

	facts_model: MML_SEQUENCE [BIB_SOURCED]
		do
			create Result
			if attached reading as r then
				Result := Result & r
			end
		end

invariant
	plugin_named: not plugin_name.is_empty
	lens_named: not lens_name.is_empty
	success_has_reading: is_success = (reading /= Void)

end
