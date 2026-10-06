note
	description: "Why an engine answer or an open failed: code, message, details. Errors are results, never control flow."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ERROR

create
	make, make_with_details

feature {NONE} -- Initialization

	make (a_code: INTEGER; a_message: READABLE_STRING_GENERAL)
			-- Create error `a_code' with `a_message'.
		require
			code_valid: is_valid_code (a_code)
			message_not_empty: not a_message.is_empty
		do
			code := a_code
			message := a_message.to_string_32
			create details.make_empty
		ensure
			code_set: code = a_code
			message_set: message.same_string_general (a_message)
			no_details: details.is_empty
		end

	make_with_details (a_code: INTEGER; a_message, a_details: READABLE_STRING_GENERAL)
			-- Create error `a_code' with `a_message' and `a_details'.
		require
			code_valid: is_valid_code (a_code)
			message_not_empty: not a_message.is_empty
		do
			make (a_code, a_message)
			details := a_details.to_string_32
		ensure
			code_set: code = a_code
			details_set: details.same_string_general (a_details)
		end

feature -- Access

	code: INTEGER
	message: STRING_32
	details: STRING_32

feature -- Status

	is_valid_code (a_code: INTEGER): BOOLEAN
			-- Is `a_code' a known error code?
		do
			Result := a_code >= Not_found and a_code <= Not_shippable
		end

feature -- Constants

	Not_found: INTEGER = 1
	Ambiguous_reference: INTEGER = 2
	Invalid_reference: INTEGER = 3
	Invalid_query: INTEGER = 4
	Database_problem: INTEGER = 5
	Schema_mismatch: INTEGER = 6
	Source_unavailable: INTEGER = 7
	Cancelled: INTEGER = 8
	Not_shippable: INTEGER = 9

invariant
	code_valid: is_valid_code (code)
	message_not_empty: not message.is_empty

end
