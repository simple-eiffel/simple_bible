note
	description: "[
		Plain text, Markdown and CSV from engine results with attribution
		(FR-119). Swete text carries the CC BY-SA notice; AI-made items keep their
		label in every export (AC-1a-51, AC-1a-54).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_EXPORTER

create
	make

feature {NONE} -- Initialization

	make
		do
			create attribution
		end

feature -- Access

	attribution: BIB_ATTRIBUTION

feature -- Export

	export_text (a_result: BIB_ENGINE_RESULT; a_format: INTEGER): STRING_32
			-- `a_result' in `a_format', attributed.
		require
			success: a_result.is_success
			format_valid: is_valid_format (a_format)
		do
			check implemented_in_phase_4: False then end
		ensure
			attributed: Result.has_substring (attribution.lines_for (a_result))
			share_alike_notice: a_result.has_share_alike_citation implies Result.has_substring (attribution.share_alike_notice)
			ai_labeled: a_result.has_ai_made_citation implies Result.has_substring ({BIB_TRUST_LABELS}.Ai_made_label)
		end

feature -- Status

	is_valid_format (a_format: INTEGER): BOOLEAN
		do
			Result := a_format >= Format_plain_text and a_format <= Format_csv
		end

feature -- Constants

	Format_plain_text: INTEGER = 1
	Format_markdown: INTEGER = 2
	Format_csv: INTEGER = 3

end
