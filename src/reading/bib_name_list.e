note
	description: "[
		Every name a reader may write for Larry's writings, with the link it opens
		(0.7.31 `bible names', moved here in 0.7.32 so the ingest kit lists the same
		names): each book's, essay series' and note's title, each chapter's, essay's
		or note chapter's title, every alias, every framework spelling.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_NAME_LIST

create
	make

feature {NONE} -- Initialization

	make (a_bible: SIMPLE_BIBLE)
			-- The names of `a_bible''s attached text and framework packs.
		do
			bible := a_bible
		end

feature -- Access

	bible: SIMPLE_BIBLE

	names (a_kind: READABLE_STRING_GENERAL): ARRAYED_LIST [TUPLE [kind, name, link: STRING_32]]
			-- Every name of the packs of kind `a_kind' (empty: every pack but those kept apart, the
			-- scholar guides, which a kit never names: 2026-10-30), in the packs' order.
		local
			i: INTEGER
		do
			create Result.make (2000)
			across bible.text_packs as ic loop
				if ic.is_available and then ((a_kind.is_empty and not ic.schema.Is_kept_apart) or else ic.schema.Pack_kind.same_string_general (a_kind)) and then attached ic.books as al_books
					and then al_books.is_success
				then
					from i := 1 until i > al_books.count loop
						add (Result, ic.schema.Pack_kind, al_books.item (i).title, ic.schema.link_text (al_books.item (i).id, 0, 0))
						if attached ic.book (al_books.item (i).id) as al_book and then al_book.is_success and then al_book.count = 1 then
							across al_book.item (1).chapters as ic_chapter loop
								if ic_chapter.chapter <= ic.schema.Max_part then
									add (Result, ic.schema.Pack_kind, ic_chapter.title, ic.schema.link_text (al_books.item (i).id, ic_chapter.chapter, 0))
								end
							end
						end
						i := i + 1
					end
					across ic.name_links as al_name loop
						add (Result, ic.schema.Pack_kind, al_name.spelling, al_name.id)
					end
				end
			end
			if a_kind.is_empty or else a_kind.same_string ({BIB_FRAMEWORK_SCHEMA}.Pack_kind) then
				across bible.framework_packs as ic loop
					if ic.is_available and then attached ic.aliases as al_spellings and then al_spellings.is_success then
						from i := 1 until i > al_spellings.count loop
							add (Result, {BIB_FRAMEWORK_SCHEMA}.Pack_kind, al_spellings.item (i).spelling, {BIB_FRAMEWORK_SCHEMA}.Link_prefix + al_spellings.item (i).id)
							i := i + 1
						end
					end
				end
			end
		ensure
			named: across Result as al_n all not al_n.name.is_empty and not al_n.link.is_empty end
		end

	links (a_names: like names): HASH_TABLE [BOOLEAN, STRING_32]
			-- Every link of `a_names', for checking a link against them.
		do
			create Result.make (a_names.count)
			across a_names as ic loop
				Result.force (True, ic.link)
			end
		end

	line_of (a_name: TUPLE [kind, name, link: STRING_32]): STRING_32
			-- "essays<TAB>JESUS 06<TAB>essay:jesus/6" and a new line.
		do
			Result := a_name.kind + {STRING_32} "%T" + a_name.name + {STRING_32} "%T" + a_name.link + {STRING_32} "%N"
		end

feature {NONE} -- Implementation

	add (a_list: like names; a_kind: READABLE_STRING_GENERAL; a_name, a_link: READABLE_STRING_GENERAL)
			-- One name, a tab or new line inside it read as a space.
		local
			l_name: STRING_32
		do
			create l_name.make_from_string_general (a_name)
			l_name.replace_substring_all ({STRING_32} "%T", {STRING_32} " ")
			l_name.replace_substring_all ({STRING_32} "%N", {STRING_32} " ")
			l_name.left_adjust
			l_name.right_adjust
			if not l_name.is_empty and then not a_link.is_empty then
				a_list.extend ([a_kind.to_string_32, l_name, a_link.to_string_32])
			end
		end

end
