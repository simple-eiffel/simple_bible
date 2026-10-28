note
	description: "[
		Writes THE frameworks pack (BIB_FRAMEWORK_SCHEMA) from the frameworks' sidecar
		JSON files, one per framework, `<id>.framework.json', which the COMMENTARY
		session writes (research/18-FRAMEWORKS-PACK-SIDECAR.md). Every build starts
		from an empty file; nothing is merged.

		THE CHECKS, before a byte is written: every sidecar is a JSON object; ids
		are lowercase letters and digits and unique; every spelling (the name and
		each alias) is unique across the pack; the tier and status are known; the
		hover text is present and at most `Max_hover' characters; at least
		`Min_sections' sections, each with a heading and a body. A sidecar that
		breaks one refuses the build, and `last_error' names the file and the rule.
		A related id the pack does not (yet) hold is left out and listed in
		`warnings' (frameworks are written in batches: COMMENTARY, 2026-10-28).

		WHERE THE COMMENTARY USES IT: given the commentary pack, each section whose
		"Frameworks at work" list names a framework (BIB_FRAMEWORK_NAMES, the
		linker's own rule) is written as one of that framework's uses.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_FRAMEWORK_BUILDER

inherit
	BIB_PACK_WRITING

create
	make

feature {NONE} -- Initialization

	make
		do
			create schema
			create records.make (16)
		ensure
			nothing_built: framework_count = 0
		end

feature -- Access

	warnings: ARRAYED_LIST [STRING_32]
			-- What the last build left out without failing (a related id not in the pack).
		attribute
			create Result.make (4)
		end

	schema: BIB_FRAMEWORK_SCHEMA
			-- The tables written.

	framework_count, alias_count, section_count, related_count, use_count: INTEGER
			-- What the last build wrote.

	sidecars_in (a_folder: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- Every `*.framework.json' in the folder `a_folder'; or `a_folder' itself when it names a
			-- file.
		do
			Result := sidecars_with (a_folder, ".framework.json")
		end

feature -- Commands

	build (a_sidecars: ITERABLE [READABLE_STRING_GENERAL]; a_pack, a_commentary_pack: READABLE_STRING_GENERAL)
			-- Write the pack `a_pack' afresh from the sidecars `a_sidecars'; with the commentary pack
			-- `a_commentary_pack' (empty: none), each framework's uses too.
		require
			some_sidecar: across a_sidecars as ic some not ic.is_empty end
			pack_named: not a_pack.is_empty
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			last_error := Void
			framework_count := 0
			alias_count := 0
			section_count := 0
			related_count := 0
			use_count := 0
			records.wipe_out
			warnings.wipe_out
			across a_sidecars as ic until last_error /= Void loop
				read_sidecar (ic.to_string_32)
			end
			if last_error = Void then
				check_related
			end
			if last_error = Void then
				l_db := begin_private_pack (a_pack, schema, "bible_build --frameworks")
				put_private_provenance (l_db, 1, "frameworks sidecars", schema.Pack_title, "Plain-reader rewrites; a draft until Larry approves it.")
				if last_error = Void then
					across records as ic until last_error /= Void loop
						write_framework (l_db, ic)
					end
					if last_error = Void and then not a_commentary_pack.is_empty then
						write_uses (l_db, a_commentary_pack)
					end
				end
				finish_pack (l_db)
			end
		ensure
			counted_on_success: last_error = Void implies framework_count = records.count
		end

feature {NONE} -- Reading and checking

	records: ARRAYED_LIST [TUPLE [file, id, name: STRING_32; mark: BOOLEAN; title, tier, status, hover, source: STRING_32;
			aliases: ARRAYED_LIST [STRING_32]; sections: ARRAYED_LIST [TUPLE [heading, markdown: STRING_32]]; related: ARRAYED_LIST [STRING_32]]]
			-- The sidecars read, in the order given.

	read_sidecar (a_file: STRING_32)
			-- Read and check sidecar `a_file' into `records'; `last_error' says what is wrong.
		local
			l_json: SIMPLE_JSON
			l_object: SIMPLE_JSON_OBJECT
			l_aliases, l_related: ARRAYED_LIST [STRING_32]
			l_sections: ARRAYED_LIST [TUPLE [heading, markdown: STRING_32]]
			l_mark: BOOLEAN
			i: INTEGER
		do
			create l_json
			if attached l_json.parse_file (a_file) as al_value and then al_value.is_object then
				l_object := al_value.as_object
				l_mark := attached l_object.item ({STRING_32} "mark") as al_mark and then al_mark.is_boolean and then al_mark.as_boolean
				create l_aliases.make (2)
				l_aliases.extend (text_of (l_object, "name"))
				across strings_of (l_object, "aliases") as ic loop
					if not ic.is_empty and then not across l_aliases as al_seen some al_seen.same_string (ic) end then
						l_aliases.extend (ic)
					end
				end
				create l_sections.make (5)
				if attached l_object.array_item ({STRING_32} "sections") as al_sections then
					from i := 1 until i > al_sections.count loop
						if al_sections [i].is_object then
							l_sections.extend ([text_of (al_sections [i].as_object, "heading"), text_of (al_sections [i].as_object, "markdown")])
						end
						i := i + 1
					end
				end
				create l_related.make (3)
				across strings_of (l_object, "related") as ic loop
					l_related.extend (ic)
				end
				fail_unless (schema.is_framework_id (text_of (l_object, "id")), a_file, "its id is not lowercase letters and digits")
				fail_unless (not text_of (l_object, "name").is_empty, a_file, "it has no name")
				fail_unless (schema.tier_rank (text_of (l_object, "tier")) > 0, a_file, {STRING_32} "its tier is not one of " + schema.tier_list)
				fail_unless (schema.is_status (text_of (l_object, "status")), a_file, "its status is not draft or reviewed")
				fail_unless (not text_of (l_object, "hover").is_empty and text_of (l_object, "hover").count <= schema.Max_hover, a_file,
					{STRING_32} "its hover text is empty or longer than " + schema.Max_hover.out.to_string_32 + {STRING_32} " characters")
				fail_unless (l_sections.count >= schema.Min_sections and then across l_sections as al_s all not al_s.heading.is_empty and not al_s.markdown.is_empty end,
					a_file, {STRING_32} "it has fewer than " + schema.Min_sections.out.to_string_32 + {STRING_32} " sections with a heading and a body")
				fail_unless (not across records as al_r some al_r.id.same_string (text_of (l_object, "id")) end, a_file,
					{STRING_32} "its id " + text_of (l_object, "id") + {STRING_32} " is already another sidecar's")
				across l_aliases as ic loop
					fail_unless (not across records as al_r some across al_r.aliases as al_a some al_a.same_string (ic) end end, a_file,
						{STRING_32} "the spelling " + ic + {STRING_32} " already names another framework")
				end
				if last_error = Void then
					records.extend ([a_file, text_of (l_object, "id"), text_of (l_object, "name"), l_mark, text_of (l_object, "title"),
						text_of (l_object, "tier"), text_of (l_object, "status"), text_of (l_object, "hover"), text_of (l_object, "source"),
						l_aliases, l_sections, l_related])
				end
			else
				last_error := {STRING_32} "The sidecar is not a JSON object: " + a_file
			end
		end

	check_related
			-- A related id the pack does not hold is left out, with a warning.
		local
			l_kept: ARRAYED_LIST [STRING_32]
		do
			across records as ic loop
				create l_kept.make (ic.related.count)
				across ic.related as ic_id loop
					if across records as al_r some al_r.id.same_string (ic_id) end then
						l_kept.extend (ic_id)
					else
						warnings.extend (ic.file + {STRING_32} ": the related framework " + ic_id + {STRING_32} " is not in the pack yet; left out")
					end
				end
				ic.related.wipe_out
				ic.related.append (l_kept)
			end
		ensure
			every_related_held: across records as al_r all across al_r.related as al_id all
				across records as al_other some al_other.id.same_string (al_id) end end end
		end

feature {NONE} -- Writing

	write_framework (a_db: SIMPLE_SQL_DATABASE; a_record: like records.item)
			-- One framework: its row, spellings, sections and related ids.
		local
			i: INTEGER
		do
			a_db.execute_with_args ("INSERT INTO framework VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'author', 1)",
				<<a_record.id, a_record.name, (if a_record.mark then 1 else 0 end), a_record.title, a_record.tier,
				schema.tier_rank (a_record.tier), a_record.status, a_record.hover, a_record.source>>)
			check_db (a_db, {STRING_32} "The framework " + a_record.id + {STRING_32} " could not be written.")
			framework_count := framework_count + 1
			put_search_row (a_db, schema.Link_prefix + a_record.id, a_record.name + {STRING_32} ": " + a_record.title, a_record.hover, "author")
			from i := 1 until i > a_record.aliases.count or last_error /= Void loop
					-- The name of a marked framework links only with its mark; an alias as written.
				a_db.execute_with_args ("INSERT INTO framework_alias VALUES (?, ?, ?, 'author', 1)",
					<<a_record.aliases.i_th (i), a_record.id, (if needs_mark (a_record, a_record.aliases.i_th (i)) then 1 else 0 end)>>)
				check_db (a_db, {STRING_32} "A spelling of " + a_record.id + {STRING_32} " could not be written.")
				alias_count := alias_count + 1
				i := i + 1
			end
			from i := 1 until i > a_record.sections.count or last_error /= Void loop
				a_db.execute_with_args ("INSERT INTO framework_section VALUES (?, ?, ?, ?, 'author', 1)",
					<<a_record.id, i, a_record.sections.i_th (i).heading, a_record.sections.i_th (i).markdown>>)
				check_db (a_db, {STRING_32} "A section of " + a_record.id + {STRING_32} " could not be written.")
				section_count := section_count + 1
				put_search_row (a_db, schema.Link_prefix + a_record.id, a_record.name + {STRING_32} ": " + a_record.sections.i_th (i).heading,
					a_record.sections.i_th (i).markdown, "author")
				i := i + 1
			end
			from i := 1 until i > a_record.related.count or last_error /= Void loop
				a_db.execute_with_args ("INSERT INTO framework_related VALUES (?, ?, ?, 'author', 1)", <<a_record.id, i, a_record.related.i_th (i)>>)
				check_db (a_db, {STRING_32} "A related id of " + a_record.id + {STRING_32} " could not be written.")
				related_count := related_count + 1
				i := i + 1
			end
		end

	write_uses (a_db: SIMPLE_SQL_DATABASE; a_commentary_pack: READABLE_STRING_GENERAL)
			-- Each commentary section whose "Frameworks at work" names a framework, as one of its uses.
		local
			l_commentary: SIMPLE_SQL_DATABASE
			l_names: BIB_FRAMEWORK_NAMES
			l_spellings: ARRAYED_LIST [TUPLE [spelling, id: STRING_32; needs_mark: BOOLEAN]]
			l_seen: ARRAYED_LIST [STRING_32]
			l_ordinals: HASH_TABLE [INTEGER, STRING_32]
			l_key: STRING_32
		do
			if not (create {SIMPLE_FILE}.make (a_commentary_pack)).is_file then
				last_error := {STRING_32} "No commentary pack at " + a_commentary_pack.to_string_32
			else
				create l_spellings.make (32)
				across records as ic loop
					across ic.aliases as ic_alias loop
						l_spellings.extend ([ic_alias.twin, ic.id, needs_mark (ic, ic_alias)])
					end
				end
				create l_names.make (l_spellings)
				create l_seen.make (64)
				l_seen.compare_objects
				create l_ordinals.make (32)
				create l_commentary.make_read_only (a_commentary_pack)
				across l_commentary.query ("SELECT l.section_id, l.item_markdown, s.heading, s.start_book, s.start_chapter, s.start_verse, s.end_chapter, s.end_verse FROM commentary_list l JOIN commentary_section s ON s.section_id = l.section_id WHERE l.list_kind = 'framework' ORDER BY s.start_hub, s.ordinal, l.ordinal").rows as ic
				until last_error /= Void
				loop
					across l_names.ids_in (ic.string_value ("item_markdown")) as ic_id until last_error /= Void loop
						l_key := ic_id + {STRING_32} " " + ic.string_value ("section_id")
						if not l_seen.has (l_key) then
							l_seen.extend (l_key)
							l_ordinals.force (l_ordinals.item (ic_id) + 1, ic_id)
							a_db.execute_with_args ("INSERT INTO framework_use VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'author', 1)",
								<<ic_id, l_ordinals.item (ic_id), ic.string_value ("section_id"), ic.string_value ("heading"), ic.integer_value ("start_book"),
								ic.integer_value ("start_chapter"), ic.integer_value ("start_verse"), ic.integer_value ("end_chapter"), ic.integer_value ("end_verse")>>)
							check_db (a_db, {STRING_32} "A use of " + ic_id + {STRING_32} " could not be written.")
							use_count := use_count + 1
						end
					end
				end
				check_db (l_commentary, "The commentary pack could not be read.")
				l_commentary.close
			end
		end

feature {NONE} -- Implementation

	needs_mark (a_record: like records.item; a_spelling: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_spelling' of `a_record' link only with (TM): is it the name of a framework prose
			-- marks? (An alias links as written.)
		do
			Result := a_record.mark and then a_spelling.same_string (a_record.name)
		end

end
