note
	description: "[
		Writes THE commentary pack (BIB_COMMENTARY_SCHEMA, one file for every
		book) from the books' sidecar JSON files, the machine-readable twins of
		the Markdown the COMMENTARY session writes, one per book at
		Commentaries/<Book>/_build/<book>.sections.json (`sidecars_in' finds
		them under the Commentaries folder). Every build starts from an empty
		file, so a rebuilt sidecar (after Larry's edits) or a new book is a
		rebuilt pack; nothing is merged.

		THE SIDECAR: `meta' (book, book_id, versification, status) and
		`sections', each with section_id, heading, start and end (book, chapter,
		verse), voice (null until Larry picks one), fields (teaser, text,
		common_reading, commentary, variants), frameworks, questions,
		further_reading, terms, claims (id, field, label SOURCED or DEDUCED,
		text, summary, source) and restricted_quotes.

		THE VOICE: a null voice is written "author" (Larry's own material; the
		author voice of BIB_VOICE) and the pack's meta says voice_status
		PROVISIONAL until Larry chooses (2026-10-27).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_COMMENTARY_BUILDER

inherit
	BIB_PACK_WRITING

create
	make

feature {NONE} -- Initialization

	make
		do
			create title.make_empty
			create schema
		ensure
			nothing_built: section_count = 0
		end

feature -- Access

	title: STRING_32
			-- The pack's title, as the last build wrote it.

	schema: BIB_COMMENTARY_SCHEMA
			-- The tables written.

	book_count, section_count, claim_count, term_count, list_count, restricted_count: INTEGER
			-- What the last build wrote.

	sidecars_in (a_folder: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- Every `<Book>/_build/*.sections.json' under the Commentaries folder `a_folder'; or
			-- `a_folder' itself when it names a file.
		local
			l_root, l_build: SIMPLE_FILE
			l_path: STRING_32
		do
			create Result.make (4)
			create l_root.make (a_folder)
			if l_root.is_directory then
				across l_root.directories as ic loop
					l_path := a_folder.to_string_32 + {STRING_32} "\" + ic + {STRING_32} "\_build"
					create l_build.make (l_path)
					if l_build.is_directory then
						across l_build.files_with_extension (".sections.json") as ic_file loop
							Result.extend (l_path + {STRING_32} "\" + ic_file)
						end
					end
				end
			elseif l_root.is_file then
				Result.extend (a_folder.to_string_32)
			end
		end

feature -- Commands

	build (a_sidecars: ITERABLE [READABLE_STRING_GENERAL]; a_pack: READABLE_STRING_GENERAL)
			-- Write the pack `a_pack' afresh from the books' sidecars `a_sidecars'.
		require
			some_sidecar: across a_sidecars as ic some not ic.is_empty end
			pack_named: not a_pack.is_empty
		local
			l_json: SIMPLE_JSON
			l_db: SIMPLE_SQL_DATABASE
		do
			last_error := Void
			book_count := 0
			section_count := 0
			claim_count := 0
			term_count := 0
			list_count := 0
			restricted_count := 0
			title := {BIB_COMMENTARY_SCHEMA}.Pack_title.to_string_32
			l_db := begin_private_pack (a_pack, schema, "bible_build --commentary")
			put_meta (l_db, "voice_status", {STRING_32} "PROVISIONAL")
			if last_error = Void then
				create l_json
				across a_sidecars as ic until last_error /= Void loop
					if attached l_json.parse_file (ic.to_string_32) as al_value and then al_value.is_object then
						book_count := book_count + 1
						write_book (l_db, al_value.as_object, book_count)
					else
						last_error := {STRING_32} "The sidecar is not a JSON object: " + ic.to_string_32
					end
				end
			end
			finish_pack (l_db)
		end

feature {NONE} -- Writing

	write_book (a_db: SIMPLE_SQL_DATABASE; a_root: SIMPLE_JSON_OBJECT; a_number: INTEGER)
			-- Book `a_number' of the build: its row, its provenance and every section of `a_root'.
			-- Its provenance keys are 2 * `a_number' - 1 (the commentary) and 2 * `a_number' (its
			-- restricted quotations).
		local
			l_meta: detachable SIMPLE_JSON_OBJECT
			l_book, l_status, l_book_title: STRING_32
			l_key: INTEGER
			i: INTEGER
		do
			l_key := 2 * a_number - 1
			l_meta := a_root.object_item ("meta")
			if l_meta = Void or else not attached a_root.array_item ("sections") then
				last_error := {STRING_32} "A sidecar has no meta or no sections."
			else
				l_book := text_of (l_meta, "book")
				l_status := text_of (l_meta, "status")
				l_book_title := l_book + {STRING_32} ": A Commentary"
				if last_error = Void then
					a_db.execute_with_args ("INSERT INTO source_provenance VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
						<<l_key, {STRING_32} "Larry Rix: " + l_book_title, l_status, schema.pack_license.identifier, schema.pack_license.is_non_commercial.to_integer,
						schema.pack_license.is_share_alike.to_integer, schema.pack_license.is_restricted.to_integer, schema.pack_license.credit_line,
						{STRING_32} "Tentatively approved by Larry Rix (2026-10-27). SOURCED claims cite his writings; DEDUCED claims reason from his frameworks and are not his words. Quotations: BSB (CC0) and WH (public domain).">>)
					check_db (a_db, "The provenance could not be written.")
				end
				if last_error = Void then
					a_db.execute_with_args ("INSERT INTO source_provenance VALUES (?, ?, ?, ?, 1, 0, 1, ?, ?)",
						<<l_key + 1, {STRING_32} "Restricted quotations in " + l_book_title, l_status, {STRING_32} "research only", {STRING_32} "",
						{STRING_32} "Quoted for reference only; each names its own source and ship class.">>)
					check_db (a_db, "The provenance could not be written.")
				end
				if last_error = Void then
					a_db.execute_with_args ("INSERT INTO commentary_book VALUES (?, ?, ?, ?, ?)",
						<<l_meta.integer_item ("book_id"), l_book_title, l_status, {STRING_32} "author", l_key>>)
					check_db (a_db, {STRING_32} "Book " + l_book + {STRING_32} " could not be written (is it in the pack twice?).")
				end
				if attached a_root.array_item ("sections") as al_sections then
					from i := 1 until i > al_sections.count or last_error /= Void loop
						if attached al_sections.object_item (i) as al_section then
							write_section (a_db, al_section, i, l_key)
						else
							last_error := {STRING_32} "Section " + i.out + " is not a JSON object."
						end
						i := i + 1
					end
				end
			end
		end

	write_section (a_db: SIMPLE_SQL_DATABASE; a_section: SIMPLE_JSON_OBJECT; a_ordinal, a_key: INTEGER)
			-- One section and everything in it, cited by provenance `a_key' (its restricted
			-- quotations by `a_key' + 1).
		local
			l_id, l_voice: STRING_32
			l_start, l_end: detachable SIMPLE_JSON_OBJECT
			l_book, l_start_chapter, l_start_verse, l_end_chapter, l_end_verse: INTEGER
			l_hub: BIB_HUB_ID
			l_kinds: ARRAY [STRING_8]
			i: INTEGER
		do
			l_id := text_of (a_section, "section_id")
			l_start := a_section.object_item ("start")
			l_end := a_section.object_item ("end")
			if l_id.is_empty or l_start = Void or l_end = Void then
				last_error := {STRING_32} "Section " + a_ordinal.out + " lacks its id, start or end."
			else
				l_book := l_start.integer_item ("book").to_integer_32
				l_start_chapter := l_start.integer_item ("chapter").to_integer_32
				l_start_verse := l_start.integer_item ("verse").to_integer_32
				l_end_chapter := l_end.integer_item ("chapter").to_integer_32
				l_end_verse := l_end.integer_item ("verse").to_integer_32
				create l_hub
				if not (is_part (l_book) and is_part (l_start_chapter) and is_part (l_start_verse) and is_part (l_end_chapter) and is_part (l_end_verse))
					or else l_hub.hub_id (l_book, l_end_chapter, l_end_verse) < l_hub.hub_id (l_book, l_start_chapter, l_start_verse)
				then
					last_error := {STRING_32} "Section " + l_id + " names no verse range."
				else
					l_voice := text_of (a_section, "voice")
					if l_voice.is_empty then
						l_voice := {STRING_32} "author"
					end
					a_db.execute_with_args ("INSERT INTO commentary_section VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
						<<l_id, a_ordinal, text_of (a_section, "heading"), l_book, l_start_chapter, l_start_verse, l_book, l_end_chapter, l_end_verse,
						l_hub.hub_id (l_book, l_start_chapter, l_start_verse), l_hub.hub_id (l_book, l_end_chapter, l_end_verse),
						non_empty (text_of (a_section, "versification"), "kjv"), l_voice, a_key>>)
					check_db (a_db, {STRING_32} "Section " + l_id + " could not be written.")
					section_count := section_count + 1
					if attached a_section.object_item ("fields") as al_fields then
						l_kinds := schema.Field_kinds
						from i := l_kinds.lower until i > l_kinds.upper or last_error /= Void loop
							if not text_of (al_fields, l_kinds [i]).is_empty then
								a_db.execute_with_args ("INSERT INTO commentary_field VALUES (?, ?, ?, ?, ?, ?)", <<l_id, l_kinds [i], i, text_of (al_fields, l_kinds [i]), l_voice, a_key>>)
								check_db (a_db, {STRING_32} "A field of " + l_id + " could not be written.")
								if not l_kinds [i].same_string ("text") then
										-- the quoted Bible text is the Bible search's, not the writings'
									put_search_row (a_db, (create {BIB_BIBLE_LINK}).range_target_text (l_book, l_start_chapter, l_start_verse, l_end_chapter, l_end_verse),
										text_of (a_section, "heading"), text_of (al_fields, l_kinds [i]), l_voice)
								end
							end
							i := i + 1
						end
					end
					write_claims (a_db, a_section, l_id, l_voice, a_key)
					write_terms (a_db, a_section, l_id, l_voice, a_key)
					write_list (a_db, a_section, "frameworks", "framework", l_id, l_voice, a_key)
					write_list (a_db, a_section, "questions", "question", l_id, l_voice, a_key)
					write_list (a_db, a_section, "further_reading", "further_reading", l_id, l_voice, a_key)
					write_restricted (a_db, a_section, l_id, l_voice, a_key + 1)
				end
			end
		end

	write_claims (a_db: SIMPLE_SQL_DATABASE; a_section: SIMPLE_JSON_OBJECT; a_id, a_voice: STRING_32; a_key: INTEGER)
		local
			i: INTEGER
		do
			if attached a_section.array_item ("claims") as al_claims then
				from i := 1 until i > al_claims.count or last_error /= Void loop
					if attached al_claims.object_item (i) as al_claim and then text_of (al_claim, "id").is_empty then
							-- Scan 39: a claim without an id was written, then dropped unseen by the reader.
						last_error := {STRING_32} "Claim " + i.out + " of " + a_id + " has no id."
					elseif attached al_claims.object_item (i) as al_claim then
						a_db.execute_with_args ("INSERT INTO commentary_claim VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
							<<text_of (al_claim, "id"), a_id, text_of (al_claim, "field"), i, text_of (al_claim, "label"), text_of (al_claim, "text"),
							text_of (al_claim, "summary"), text_of (al_claim, "source"), a_voice, a_key>>)
						check_db (a_db, {STRING_32} "Claim " + text_of (al_claim, "id") + " of " + a_id + " could not be written (its label must be SOURCED or DEDUCED).")
						claim_count := claim_count + 1
					end
					i := i + 1
				end
			end
		end

	write_terms (a_db: SIMPLE_SQL_DATABASE; a_section: SIMPLE_JSON_OBJECT; a_id, a_voice: STRING_32; a_key: INTEGER)
		local
			i: INTEGER
		do
			if attached a_section.array_item ("terms") as al_terms then
				from i := 1 until i > al_terms.count or last_error /= Void loop
					if attached al_terms.object_item (i) as al_term then
						a_db.execute_with_args ("INSERT INTO commentary_term VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
							<<a_id, i, text_of (al_term, "script"), text_of (al_term, "translit"), text_of (al_term, "pron"), text_of (al_term, "english"),
							text_of (al_term, "language"), text_of (al_term, "lemma_key"), text_of (al_term, "strongs"), a_voice, a_key>>)
						check_db (a_db, {STRING_32} "A term of " + a_id + " could not be written.")
						term_count := term_count + 1
					end
					i := i + 1
				end
			end
		end

	write_list (a_db: SIMPLE_SQL_DATABASE; a_section: SIMPLE_JSON_OBJECT; a_name, a_kind: STRING_8; a_id, a_voice: STRING_32; a_key: INTEGER)
		local
			i: INTEGER
		do
			if attached a_section.array_item (a_name.to_string_32) as al_items then
				from i := 1 until i > al_items.count or last_error /= Void loop
					if attached al_items.string_item (i) as al_item and then not al_item.is_empty then
						a_db.execute_with_args ("INSERT INTO commentary_list VALUES (?, ?, ?, ?, ?, ?)", <<a_id, a_kind, i, al_item, a_voice, a_key>>)
						check_db (a_db, {STRING_32} "A list item of " + a_id + " could not be written.")
						list_count := list_count + 1
					end
					i := i + 1
				end
			end
		end

	write_restricted (a_db: SIMPLE_SQL_DATABASE; a_section: SIMPLE_JSON_OBJECT; a_id, a_voice: STRING_32; a_key: INTEGER)
		local
			i: INTEGER
		do
			if attached a_section.array_item ("restricted_quotes") as al_quotes then
				from i := 1 until i > al_quotes.count or last_error /= Void loop
					if attached al_quotes.object_item (i) as al_quote then
						a_db.execute_with_args ("INSERT INTO commentary_restricted_quote VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
							<<a_id, i, text_of (al_quote, "source"), non_empty (text_of (al_quote, "ship_class"), "research_only"), text_of (al_quote, "note"),
							text_of (al_quote, "markdown"), a_voice, a_key>>)
						check_db (a_db, {STRING_32} "A restricted quotation of " + a_id + " could not be written.")
						restricted_count := restricted_count + 1
					end
					i := i + 1
				end
			end
		end

feature {NONE} -- Implementation

	non_empty (a_text: STRING_32; a_default: READABLE_STRING_GENERAL): STRING_32
		do
			if a_text.is_empty then
				Result := a_default.to_string_32
			else
				Result := a_text
			end
		end

	is_part (a_number: INTEGER): BOOLEAN
			-- Can `a_number' be a book, chapter or verse of a hub id?
		do
			Result := a_number >= 1 and a_number <= {BIB_HUB_ID}.Max_part
		end

end
