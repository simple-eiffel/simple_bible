note
	description: "[
		A verse's commentary as one Markdown page for S2/T5's Commentaries tab:
		the pack's banner (who, which voice, how claims are labelled), then each
		section covering the verse, narrowest first, with its fields, terms,
		lists, restricted quotations and claims.

		EVERY CLAIM WEARS ITS LABEL (2026-10-27; COMMENTARY and NEEDLE asked):
		an inline tag such as [D11.9] is shown as **[DEDUCED D11.9]**, and each
		section ends with its claims listed by label. A DEDUCED claim is reasoned
		from Larry's frameworks, not his words, and must never read as his.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_COMMENTARY_TEXT

feature -- Pages

	page (a_title: READABLE_STRING_GENERAL; a_sections: ITERABLE [BIB_COMMENTARY_SECTION]): STRING_32
			-- The Markdown page of `a_sections' from the pack titled `a_title'.
		do
			create Result.make (4096)
			Result.append ({STRING_32} "**" + a_title.to_string_32 + {STRING_32} "**%N%N")
			Result.append ({STRING_32} "*Larry Rix, author voice (provisional). Each claim is labelled: SOURCED claims cite his writings; DEDUCED claims are reasoned from his frameworks, not his words.*%N")
			across a_sections as ic loop
				Result.append (section_text (ic))
			end
		end

	section_text (a_section: BIB_COMMENTARY_SECTION): STRING_32
			-- One section as Markdown.
		do
			create Result.make (2048)
			Result.append ({STRING_32} "%N## " + a_section.heading + {STRING_32} "%N")
			append_field (Result, a_section, "teaser", "")
			append_field (Result, a_section, "text", "The text")
			append_field (Result, a_section, "common_reading", "The common reading")
			append_field (Result, a_section, "commentary", "Commentary")
			append_field (Result, a_section, "variants", "Variants")
			if not a_section.terms.is_empty then
				Result.append ({STRING_32} "%N### Original-language terms%N%N")
				across a_section.terms as ic loop
					Result.append ({STRING_32} "- **" + ic.script + {STRING_32} "** *" + ic.translit + {STRING_32} "*")
					if not ic.pron.is_empty then
						Result.append ({STRING_32} " (" + ic.pron + {STRING_32} ")")
					end
					Result.append ({STRING_32} ": " + ic.english + {STRING_32} "%N")
				end
			end
			append_list (Result, a_section, "framework", "Frameworks at work")
			append_list (Result, a_section, "question", "Questions this section answers")
			append_list (Result, a_section, "further_reading", "Further reading")
			across a_section.restricted_quotes as ic loop
				Result.append ({STRING_32} "%N### Quoted for reference only%N%N*" + ic.source + {STRING_32} " (" + ic.ship_class + {STRING_32} "). " + ic.remark + {STRING_32} "*%N%N" + ic.markdown + {STRING_32} "%N")
			end
			if not a_section.claims.is_empty then
				Result.append ({STRING_32} "%N### Claims%N%N")
				across a_section.claims as ic loop
					Result.append ({STRING_32} "- **[" + claim_label (ic) + {STRING_32} "]** " + ic.summary)
					if not ic.source_ref.is_empty then
						Result.append ({STRING_32} " *(" + ic.source_ref + {STRING_32} ")*")
					end
					Result.append_character ('%N')
				end
			end
		end

	labelled (a_text: READABLE_STRING_GENERAL; a_section: BIB_COMMENTARY_SECTION): STRING_32
			-- `a_text' with each claim tag of `a_section' ("[S14.1]") shown with its label
			-- ("**[SOURCED S14.1]**").
		do
			Result := a_text.to_string_32
			across a_section.claims as ic loop
				Result.replace_substring_all ({STRING_32} "[" + ic.claim_id + {STRING_32} "]", {STRING_32} "**[" + claim_label (ic) + {STRING_32} "]**")
			end
		ensure
			no_bare_tag: across a_section.claims as ic all not Result.has_substring ({STRING_32} "[" + ic.claim_id + {STRING_32} "]") end
		end

	claim_label (a_claim: BIB_COMMENTARY_CLAIM): STRING_32
			-- "SOURCED S14.1" or "DEDUCED D11.9".
		do
			Result := a_claim.label.to_string_32 + {STRING_32} " " + a_claim.claim_id
		end

feature {NONE} -- Implementation

	append_field (a_page: STRING_32; a_section: BIB_COMMENTARY_SECTION; a_kind: READABLE_STRING_8; a_heading: READABLE_STRING_GENERAL)
			-- Field `a_kind' under `a_heading' (none: no heading), its claim tags labelled.
		do
			if not a_section.field (a_kind).is_empty then
				if not a_heading.is_empty then
					a_page.append ({STRING_32} "%N### " + a_heading.to_string_32 + {STRING_32} "%N")
				end
				a_page.append ({STRING_32} "%N" + labelled (a_section.field (a_kind), a_section) + {STRING_32} "%N")
			end
		end

	append_list (a_page: STRING_32; a_section: BIB_COMMENTARY_SECTION; a_kind: READABLE_STRING_8; a_heading: READABLE_STRING_GENERAL)
			-- The items of list `a_kind' under `a_heading', when there are any.
		local
			l_first: BOOLEAN
		do
			l_first := True
			across a_section.lists as ic loop
				if ic.kind.same_string (a_kind) then
					if l_first then
						a_page.append ({STRING_32} "%N### " + a_heading.to_string_32 + {STRING_32} "%N%N")
						l_first := False
					end
					a_page.append ({STRING_32} "- " + ic.markdown + {STRING_32} "%N")
				end
			end
		end

end
