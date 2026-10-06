note
	description: "Script of characters and runs (Hebrew, Greek, Latin) in text; used by the AI post-check and the CLI renderer."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SCRIPT_CLASSIFIER

feature -- Classification

	script_of (a_char: CHARACTER_32): INTEGER
			-- Script of `a_char'.
		local
			n: NATURAL_32
		do
			n := a_char.natural_32_code
			if (n >= 0x0590 and n <= 0x05FF) or (n >= 0xFB1D and n <= 0xFB4F) then
				Result := Script_hebrew
			elseif (n >= 0x0370 and n <= 0x03FF) or (n >= 0x1F00 and n <= 0x1FFF) then
				Result := Script_greek
			elseif (n >= 0x41 and n <= 0x5A) or (n >= 0x61 and n <= 0x7A) or (n >= 0xC0 and n <= 0x24F) then
				Result := Script_latin
			else
				Result := Script_other
			end
		ensure
			valid: Result >= Script_other and Result <= Script_greek
		end

	has_script (a_text: READABLE_STRING_32; a_script: INTEGER): BOOLEAN
			-- Does `a_text' contain a character of `a_script'?
		do
			Result := across a_text as c some script_of (c) = a_script end
		end

	runs (a_text: READABLE_STRING_32): ARRAYED_LIST [BIB_TEXT_SPAN]
			-- Maximal same-script runs of `a_text', tagged with their script.
		do
			check implemented_in_phase_4: False then end
		ensure
			covers_text: total_length (Result) = a_text.count
			tagged: across Result as r all r.tag >= Script_other and r.tag <= Script_greek end
		end

	total_length (a_spans: ARRAYED_LIST [BIB_TEXT_SPAN]): INTEGER
			-- Sum of the lengths of `a_spans'.
		do
			across a_spans as s loop
				Result := Result + s.length
			end
		end

feature -- Constants

	Script_other: INTEGER = 0
	Script_latin: INTEGER = 1
	Script_hebrew: INTEGER = 2
	Script_greek: INTEGER = 3

end
