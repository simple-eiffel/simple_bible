note
	description: "[
		How a source speaks: trusted, hold-loosely (datum only), cite-exactly,
		or author (Larry's own library). Private and lens results are labeled
		by voice (D-014, DR-018).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_VOICE

inherit
	BIB_ENUMERATION

create
	make, make_author

feature {NONE} -- Initialization

	make (a_code: INTEGER)
			-- Create voice `a_code'.
		require
			valid: is_valid_code (a_code)
		do
			code := a_code
		ensure
			code_set: code = a_code
		end

	make_author
			-- Create the author voice.
		do
			code := Author
		ensure
			author: is_author
		end

feature -- Access

	label: STRING_32
			-- Display label.
		do
			inspect code
			when Trusted then
				Result := {STRING_32} "trusted"
			when Hold_loosely then
				Result := {STRING_32} "hold loosely (datum only)"
			when Cite_exactly then
				Result := {STRING_32} "cite exactly"
			else
				Result := {STRING_32} "author"
			end
		end

feature -- Status

	is_author: BOOLEAN
			-- Is this the author voice?
		do
			Result := code = Author
		end

	is_valid_code (a_code: INTEGER): BOOLEAN
			-- Is `a_code' a voice?
		do
			Result := a_code >= Trusted and a_code <= Author
		end

feature -- Constants

	Trusted: INTEGER = 1
	Hold_loosely: INTEGER = 2
	Cite_exactly: INTEGER = 3
	Author: INTEGER = 4

end
