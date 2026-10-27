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

	make (a_root: BIB_KEY; a_code: BIB_MORPH_CODE)
			-- Root `a_root' (a Strong's number or a lemma) in form `a_code'.
		require
			a_root: attached {BIB_STRONGS_KEY} a_root or attached {BIB_LEMMA_KEY} a_root
		do
			root := a_root
			code := a_code
			text := a_root.text + {STRING_32} "@" + a_code.code
		ensure
			root_set: root = a_root
			code_set: code = a_code
		end

feature -- Access

	root: BIB_KEY
			-- The root: a Strong's number or a lemma.

	code: BIB_MORPH_CODE
			-- The form the root takes on the same word.

	kind_label: STRING_32
		do
			Result := {STRING_32} "form"
		end

invariant
	root_is_a_root: attached {BIB_STRONGS_KEY} root or attached {BIB_LEMMA_KEY} root

end
