note
	description: "[
		A root in a grammatical form, on the same word (2026-10-27): G3056@N-NSM
		is logos as a nominative singular masculine noun, H1254@Vq* bara in the
		Qal. Where AND joins verses, a form key joins the two conditions on one
		word of the original text.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_FORM_KEY

inherit
	BIB_KEY

create
	make

feature {NONE} -- Initialization

	make (a_root: BIB_ROOT_KEY; a_code: BIB_MORPH_CODE)
			-- Root `a_root' (a Strong's number or a lemma) in form `a_code'.
		require
			code_text: a_code.is_code_text (a_code.code)
		do
			root := a_root
			code := a_code
			text := a_root.text + {STRING_32} "@" + a_code.code
		ensure
			root_set: root = a_root
			code_set: code = a_code
		end

feature -- Access

	root: BIB_ROOT_KEY
			-- The root: a Strong's number or a lemma.

	code: BIB_MORPH_CODE
			-- The form the root takes on the same word.

	kind_label: STRING_32
		do
			Result := {STRING_32} "form"
		end

invariant
	code_text: code.is_code_text (code.code)
			-- Design scan 52: only the parser guarded the code that reaches a GLOB.

end
