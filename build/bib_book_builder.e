note
	description: "[
		Writes THE books pack (BIB_BOOK_SCHEMA) from one manifest per book,
		`<id>.book.json', which the COMMENTARY session writes (research/19): the
		book's facts and its chapter files in reading order. The builder reads the
		Markdown itself and splits each chapter into blocks (BIB_MARKDOWN_BLOCKS).

		THE INDEXES: each block is linked by the window's own linker
		(BIB_REFERENCE_LINKER, given the frameworks pack's spellings) and the
		`bible:' and `framework:' targets it wrote are read back as the block's
		passages and frameworks - so the indexes never disagree with what a reader
		sees linked.

		THE CHECKS, before a byte is written: ids lowercase letters and digits and
		unique; a title; a known status; at least one chapter, each of a known kind
		with its file present; aliases unique across the pack and never a
		framework's spelling. A manifest that breaks one refuses the build, and
		`last_error' names the manifest and the rule.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_BOOK_BUILDER

inherit
	BIB_PACK_WRITING

create
	make,
	make_essays,
	make_with_schema

feature {NONE} -- Initialization

	make (a_catalog: BIB_BOOK_CATALOG)
			-- A builder of the books pack, linking references by `a_catalog''s book names.
		do
			make_with_schema (a_catalog, create {BIB_BOOK_SCHEMA})
		ensure
			catalog_set: catalog = a_catalog
		end

	make_essays (a_catalog: BIB_BOOK_CATALOG)
			-- A builder of the essays pack (a series is a book, an essay a chapter).
		do
			make_with_schema (a_catalog, create {BIB_ESSAY_SCHEMA})
		ensure
			catalog_set: catalog = a_catalog
		end

	make_with_schema (a_catalog: BIB_BOOK_CATALOG; a_schema: BIB_TEXT_PACK_SCHEMA)
			-- A builder of the pack of `a_schema''s kind, linking references by `a_catalog''s book names.
		do
			catalog := a_catalog
			schema := a_schema
			create records.make (8)
			create framework_spellings.make (0)
		ensure
			catalog_set: catalog = a_catalog
			schema_set: schema = a_schema
		end

feature -- Access

	catalog: BIB_BOOK_CATALOG
	schema: BIB_TEXT_PACK_SCHEMA
			-- The pack built: the books' or the essays'.

	book_count, chapter_count, block_count, passage_count, framework_use_count: INTEGER
			-- What the last build wrote.

	sidecars_in (a_folder: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- Every manifest (`*.book.json', `*.essay.json') in the folder `a_folder'; or `a_folder'
			-- itself when it names a file.
		do
			Result := sidecars_with (a_folder, schema.Manifest_extension)
		end

feature -- Commands

	build (a_manifests: ITERABLE [READABLE_STRING_GENERAL]; a_pack, a_frameworks_pack: READABLE_STRING_GENERAL)
			-- Write the pack `a_pack' afresh from the manifests `a_manifests'; with the frameworks pack
			-- `a_frameworks_pack' (empty: none), framework names are linked and indexed too.
		require
			some_manifest: across a_manifests as ic some not ic.is_empty end
			pack_named: not a_pack.is_empty
		local
			l_db: SIMPLE_SQL_DATABASE
			l_linker: BIB_REFERENCE_LINKER
			i: INTEGER
		do
			last_error := Void
			book_count := 0
			chapter_count := 0
			block_count := 0
			passage_count := 0
			framework_use_count := 0
			records.wipe_out
			read_framework_spellings (a_frameworks_pack)
			across a_manifests as ic until last_error /= Void loop
				read_manifest (ic.to_string_32)
			end
			if last_error = Void then
				create l_linker.make (catalog)
				if not framework_spellings.is_empty then
					l_linker.set_framework_names (create {BIB_FRAMEWORK_NAMES}.make (framework_spellings))
				end
				l_db := begin_private_pack (a_pack, schema, schema.Builder_command)
				put_private_provenance (l_db, 1, schema.Pack_kind + " manifests", schema.Pack_title, "Larry's own text as his manuscripts hold it, corrections included.")
				if last_error = Void then
					from i := 1 until i > records.count or last_error /= Void loop
						write_book (l_db, records.i_th (i), i, l_linker)
						i := i + 1
					end
				end
				finish_pack (l_db)
			end
		ensure
			counted_on_success: last_error = Void implies book_count = records.count
		end

feature {NONE} -- Reading and checking

	records: ARRAYED_LIST [TUPLE [file, id, title, subtitle, author, status, edition: STRING_32; year: INTEGER; description, root, source: STRING_32;
			aliases, skip_headings: ARRAYED_LIST [STRING_32]; chapters: ARRAYED_LIST [TUPLE [title, file, kind: STRING_32; aliases: ARRAYED_LIST [STRING_32]]]]]
			-- The manifests read, in the order given.

	framework_spellings: ARRAYED_LIST [TUPLE [spelling, id: STRING_32; needs_mark: BOOLEAN]]
			-- The frameworks pack's spellings, for the linker; empty without one.

	read_framework_spellings (a_frameworks_pack: READABLE_STRING_GENERAL)
			-- `framework_spellings' from the frameworks pack `a_frameworks_pack' (empty: none).
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			create framework_spellings.make (32)
			if not a_frameworks_pack.is_empty then
				if not (create {SIMPLE_FILE}.make (a_frameworks_pack)).is_file then
					last_error := {STRING_32} "No frameworks pack at " + a_frameworks_pack.to_string_32
				else
					create l_db.make_read_only (a_frameworks_pack)
					across l_db.query ("SELECT alias, framework_id, needs_mark FROM framework_alias").rows as ic loop
						framework_spellings.extend ([ic.string_value ("alias"), ic.string_value ("framework_id"), ic.integer_value ("needs_mark") /= 0])
					end
					check_db (l_db, "The frameworks pack could not be read.")
					l_db.close
				end
			end
		end

	read_manifest (a_file: STRING_32)
			-- Read and check manifest `a_file' into `records'; `last_error' says what is wrong.
		local
			l_json: SIMPLE_JSON
			l_object: SIMPLE_JSON_OBJECT
			l_chapters: ARRAYED_LIST [TUPLE [title, file, kind: STRING_32; aliases: ARRAYED_LIST [STRING_32]]]
			l_root, l_folder: STRING_32
			l_year: INTEGER
			i: INTEGER
		do
			create l_json
			if attached l_json.parse_file (a_file) as al_value and then al_value.is_object then
				l_object := al_value.as_object
				l_folder := folder_of (a_file)
				l_root := l_folder + {STRING_32} "\" + text_of (l_object, "root")
				l_root.replace_substring_all ({STRING_32} "/", {STRING_32} "\")
				if attached l_object.item ({STRING_32} "year") as al_year and then al_year.is_integer then
					l_year := al_year.as_integer.to_integer_32
				end
				create l_chapters.make (16)
				if attached l_object.array_item ({STRING_32} "chapters") as al_chapters then
					from i := 1 until i > al_chapters.count loop
						if al_chapters [i].is_object then
							l_chapters.extend ([text_of (al_chapters [i].as_object, "title"), text_of (al_chapters [i].as_object, "file"),
								text_of (al_chapters [i].as_object, "kind"), strings_of (al_chapters [i].as_object, "aliases")])
						end
						i := i + 1
					end
				end
				fail_unless (schema.is_book_id (text_of (l_object, "id")), a_file, "its id is not lowercase letters and digits")
				fail_unless (not text_of (l_object, "title").is_empty, a_file, "it has no title")
				fail_unless (schema.is_one_of (text_of (l_object, "status"), schema.Statuses), a_file, "its status is not published, manuscript or draft")
				fail_unless (not l_chapters.is_empty, a_file, "it names no chapter")
				across l_chapters as ic loop
					fail_unless (schema.is_one_of (ic.kind, schema.Chapter_kinds), a_file, {STRING_32} "the chapter " + ic.title + {STRING_32} " is not front, chapter or back")
					fail_unless (not ic.title.is_empty, a_file, {STRING_32} "a chapter has no title: " + ic.file)
					fail_unless ((create {SIMPLE_FILE}.make (chapter_path (l_root, ic.file))).is_file, a_file, {STRING_32} "no chapter file at " + chapter_path (l_root, ic.file))
				end
				fail_unless (not across records as al_r some al_r.id.same_string (text_of (l_object, "id")) end, a_file,
					{STRING_32} "its id " + text_of (l_object, "id") + {STRING_32} " is already another manifest's")
				across l_chapters as ic_chapter loop
					across ic_chapter.aliases as ic loop
						fail_unless (not is_name_taken (ic, l_chapters, ic_chapter), a_file, {STRING_32} "the name " + ic + {STRING_32} " already names another chapter or book")
						fail_unless (not across framework_spellings as al_f some al_f.spelling.same_string (ic) end, a_file,
							{STRING_32} "the name " + ic + {STRING_32} " is a framework's spelling")
					end
				end
				across strings_of (l_object, "aliases") as ic loop
					fail_unless (not across records as al_r some across al_r.aliases as al_a some al_a.same_string (ic) end end, a_file,
						{STRING_32} "the alias " + ic + {STRING_32} " already names another book")
					fail_unless (not across framework_spellings as al_f some al_f.spelling.same_string (ic) end, a_file,
						{STRING_32} "the alias " + ic + {STRING_32} " is a framework's spelling")
				end
				if last_error = Void then
					records.extend ([a_file, text_of (l_object, "id"), text_of (l_object, "title"), text_of (l_object, "subtitle"), text_of (l_object, "author"),
						text_of (l_object, "status"), text_of (l_object, "edition"), l_year, text_of (l_object, "description"), l_root, text_of (l_object, "source"),
						strings_of (l_object, "aliases"), strings_of (l_object, "skip_headings"), l_chapters])
				end
			else
				last_error := {STRING_32} "The manifest is not a JSON object: " + a_file
			end
		end

feature {NONE} -- Names

	is_name_taken (a_name: STRING_32; a_chapters: ARRAYED_LIST [TUPLE [title, file, kind: STRING_32; aliases: ARRAYED_LIST [STRING_32]]];
			a_own: TUPLE [title, file, kind: STRING_32; aliases: ARRAYED_LIST [STRING_32]]): BOOLEAN
			-- Does `a_name' already name a book, a chapter of a book read before, or another chapter of
			-- this one (`a_chapters', `a_own' being the one naming it)?
		do
			Result := across records as al_r some
					across al_r.aliases as al_a some al_a.same_string (a_name) end
					or across al_r.chapters as al_c some across al_c.aliases as al_a some al_a.same_string (a_name) end end
				end
				or across a_chapters as al_c some al_c /= a_own and then across al_c.aliases as al_a some al_a.same_string (a_name) end end
		end

feature {NONE} -- Writing

	write_book (a_db: SIMPLE_SQL_DATABASE; a_record: like records.item; a_ordinal: INTEGER; a_linker: BIB_REFERENCE_LINKER)
			-- One book: its row, aliases, chapters, their blocks and the blocks' indexes.
		local
			l_blocks: BIB_MARKDOWN_BLOCKS
			l_chapter, l_block: INTEGER
		do
			a_db.execute_with_args ("INSERT INTO book VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'author', 1)",
				<<a_record.id, a_ordinal, a_record.title, a_record.subtitle, non_empty_or (a_record.author, "Larry Rix"), a_record.status,
				a_record.edition, a_record.year, a_record.description, a_record.source>>)
			check_db (a_db, {STRING_32} "The book " + a_record.id + {STRING_32} " could not be written.")
			book_count := book_count + 1
			across a_record.aliases as ic until last_error /= Void loop
				a_db.execute_with_args ("INSERT INTO book_alias VALUES (?, ?, 'author', 1)", <<ic, a_record.id>>)
				check_db (a_db, {STRING_32} "An alias of " + a_record.id + {STRING_32} " could not be written.")
			end
			from l_chapter := 1 until l_chapter > a_record.chapters.count or last_error /= Void loop
				across a_record.chapters.i_th (l_chapter).aliases as ic until last_error /= Void loop
					a_db.execute_with_args ("INSERT INTO chapter_alias VALUES (?, ?, ?, 'author', 1)", <<ic, a_record.id, l_chapter>>)
					check_db (a_db, {STRING_32} "A name of " + a_record.id + {STRING_32} "/" + l_chapter.out.to_string_32 + {STRING_32} " could not be written.")
				end
				l_chapter := l_chapter + 1
			end
			create l_blocks.make (a_record.skip_headings)
			if schema.Starts_at_title then
				l_blocks.start_at_title
			end
			fail_unless (a_record.chapters.count <= schema.Max_part, a_record.file, {STRING_32} "more chapters than a link can name")
			from l_chapter := 1 until l_chapter > a_record.chapters.count or last_error /= Void loop
				a_db.execute_with_args ("INSERT INTO book_chapter VALUES (?, ?, ?, ?, 'author', 1)",
					<<a_record.id, l_chapter, a_record.chapters.i_th (l_chapter).title, a_record.chapters.i_th (l_chapter).kind>>)
				check_db (a_db, {STRING_32} "A chapter of " + a_record.id + {STRING_32} " could not be written.")
				chapter_count := chapter_count + 1
				l_blocks.split ((create {SIMPLE_FILE}.make (chapter_path (a_record.root, a_record.chapters.i_th (l_chapter).file))).read_text_utf_8)
				fail_unless (l_blocks.blocks.count <= schema.Max_part, a_record.chapters.i_th (l_chapter).file, {STRING_32} "more blocks than a link can name")
				fail_unless (not schema.Starts_at_title or else (not l_blocks.blocks.is_empty and then l_blocks.blocks.first.kind.same_string ("heading") and then l_blocks.blocks.first.level = 1),
					a_record.chapters.i_th (l_chapter).file, {STRING_32} "no %"# %" title to begin at (scan 62: what stood above it would have been kept)")
				from l_block := 1 until l_block > l_blocks.blocks.count or last_error /= Void loop
					a_db.execute_with_args ("INSERT INTO book_block VALUES (?, ?, ?, ?, ?, ?, 'author', 1)",
						<<a_record.id, l_chapter, l_block, l_blocks.blocks.i_th (l_block).kind, l_blocks.blocks.i_th (l_block).level, l_blocks.blocks.i_th (l_block).markdown>>)
					check_db (a_db, {STRING_32} "A block of " + a_record.id + {STRING_32} " could not be written.")
					block_count := block_count + 1
					put_search_row (a_db, schema.link_text (a_record.id, l_chapter, l_block), a_record.title + {STRING_32} ", " + a_record.chapters.i_th (l_chapter).title,
						l_blocks.blocks.i_th (l_block).markdown, "author")
					write_indexes (a_db, a_record.id, l_chapter, l_block, a_linker.linked (l_blocks.blocks.i_th (l_block).markdown))
					l_block := l_block + 1
				end
				l_chapter := l_chapter + 1
			end
		end

	write_indexes (a_db: SIMPLE_SQL_DATABASE; a_book: STRING_32; a_chapter, a_block: INTEGER; a_linked: STRING_32)
			-- The block's passages and frameworks, read back from the links the linker wrote into it.
		local
			l_ordinal: INTEGER
			l_hub: BIB_HUB_ID
			l_start, l_end: INTEGER_64
			l_seen: ARRAYED_LIST [STRING_32]
			l_target: BIB_LINK_TARGET
		do
			create l_hub
			create l_seen.make (4)
			l_seen.compare_objects
			across link_targets (a_linked) as ic until last_error /= Void loop
				create l_target.make (ic, catalog)
				if l_target.is_bible then
					l_start := l_hub.hub_of_place (l_target.book, l_target.chapter, l_target.verse.max (1))
					l_end := l_hub.hub_of_place (l_target.book, l_target.end_chapter,
						(if l_target.end_verse = 0 then l_hub.Max_part else l_target.end_verse end))
					if l_start > 0 and l_end >= l_start then
						l_ordinal := l_ordinal + 1
						a_db.execute_with_args ("INSERT INTO book_passage VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'author', 1)",
							<<a_book, a_chapter, a_block, l_ordinal, l_target.book, l_target.chapter, l_target.verse, l_target.end_chapter, l_target.end_verse, l_start, l_end>>)
						check_db (a_db, "A passage could not be indexed.")
						passage_count := passage_count + 1
					end
				elseif l_target.is_framework and then not l_seen.has (l_target.id) then
					l_seen.extend (l_target.id)
					a_db.execute_with_args ("INSERT INTO book_framework VALUES (?, ?, ?, ?, 'author', 1)", <<a_book, a_chapter, a_block, l_target.id>>)
					check_db (a_db, "A framework could not be indexed.")
					framework_use_count := framework_use_count + 1
				end
			end
		end

feature {NONE} -- Implementation

	link_targets (a_linked: STRING_32): ARRAYED_LIST [STRING_32]
			-- Every Markdown link target in `a_linked' ("](target)"), in order.
		local
			i, j: INTEGER
		do
			create Result.make (4)
			from i := a_linked.substring_index ({STRING_32} "](", 1) until i = 0 loop
				j := a_linked.index_of (')', i + 2)
				if j > i + 2 then
					Result.extend (a_linked.substring (i + 2, j - 1))
					i := a_linked.substring_index ({STRING_32} "](", j)
				else
					i := 0
				end
			end
		end

	chapter_path (a_root, a_file: READABLE_STRING_GENERAL): STRING_32
			-- Chapter file `a_file' under the book's folder `a_root'.
		do
			Result := a_root.to_string_32 + {STRING_32} "\" + a_file.to_string_32
			Result.replace_substring_all ({STRING_32} "/", {STRING_32} "\")
		end

	folder_of (a_file: STRING_32): STRING_32
			-- The folder holding `a_file'.
		local
			l_slash: INTEGER
		do
			l_slash := a_file.last_index_of ('\', a_file.count).max (a_file.last_index_of ('/', a_file.count))
			if l_slash > 0 then
				Result := a_file.substring (1, l_slash - 1)
			else
				Result := {STRING_32} "."
			end
		end

	non_empty_or (a_text: STRING_32; a_default: READABLE_STRING_GENERAL): STRING_32
		do
			if a_text.is_empty then
				Result := a_default.to_string_32
			else
				Result := a_text
			end
		end

end
