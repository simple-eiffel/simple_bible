note
	description: "[
		bible_build: writes content.db v2 from the vault's bible.db (Phase 4,
		Task 10), or a commentary pack from a commentary's sidecar JSON
		(2026-10-27). Usage:
			bible_build --bible <bible.db> --out <content.db> [--tvtms <TVTMS file>] [--build-id <id>] [--built-at <ISO time>]
			bible_build --commentary <Commentaries folder, or one sidecar.json> --out <commentary.db>
			bible_build --frameworks <folder of *.framework.json, or one> --out <frameworks.db> [--uses <commentary.db>]
			bible_build --books <folder of *.book.json, or one> --out <books.db> [--content <content.db>] [--frameworks-pack <frameworks.db>]
		Exit code 0 on success, 1 on failure (the reason is printed).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_BUILD_APP

create
	make

feature {NONE} -- Implementation

	content_path (a_given: READABLE_STRING_GENERAL): STRING_32
			-- `a_given', or the installed content.db when it is empty.
		do
			if a_given.is_empty and then attached (create {EXECUTION_ENVIRONMENT}).item ("LOCALAPPDATA") as al_local then
				Result := al_local.to_string_32 + {STRING_32} "\simple_bible\content.db"
			else
				Result := a_given.to_string_32
			end
		end

feature {NONE} -- Initialization

	make
			-- Parse the arguments and build.
		local
			l_cli: SIMPLE_CLI
			l_builder: BIB_CONTENT_BUILDER
			l_commentary: BIB_COMMENTARY_BUILDER
			l_frameworks: BIB_FRAMEWORK_BUILDER
			l_books: BIB_BOOK_BUILDER
			l_reader: SIMPLE_BIBLE
			l_build_id: STRING
			l_failed: BOOLEAN
		do
			create l_cli.make
			l_cli.set_app_info ("bible_build", "Writes content.db v2 (books, versions, every verse) from the vault's bible.db.", {BIB_CONTENT_BUILDER}.Builder_name)
			l_cli.add_option_with_default ("b|bible", "The vault's bible.db", "path", "")
			l_cli.add_option_with_default ("c|commentary", "The Commentaries folder (every book's _build sidecar) or one sidecar JSON: write the commentary pack instead", "path", "")
			l_cli.add_option_with_default ("f|frameworks", "A folder of *.framework.json sidecars, or one: write the frameworks pack instead", "path", "")
			l_cli.add_option_with_default ("u|uses", "With --frameworks: the commentary pack whose Frameworks at work lists give each framework's uses (empty: none)", "path", "")
			l_cli.add_option_with_default ("k|books", "A folder of *.book.json manifests, or one: write the books pack instead", "path", "")
			l_cli.add_option_with_default ("n|content", "With --books: the content.db whose book names link references (empty: the installed one)", "path", "")
			l_cli.add_option_with_default ("p|frameworks-pack", "With --books: the frameworks pack whose names link and index (empty: none)", "path", "")
			l_cli.add_required_option ("o|out", "The content.db to write", "path")
			l_cli.add_option_with_default ("i|build-id", "The build id (the edition)", "id", "content-v2")
			l_cli.add_option_with_default ("t|built-at", "The build time, for a byte-identical rebuild (empty: now)", "ISO time", "")
			l_cli.add_option_with_default ("v|tvtms", "STEPBible's TVTMS file, for the versification map (empty: none)", "path", "")
			l_cli.parse
			if l_cli.has_errors then
				across l_cli.errors as ic loop
					print (ic + "%N")
				end
				l_failed := True
			elseif attached l_cli.value_of ("books") as al_manifests and then not al_manifests.is_empty
				and then attached l_cli.value_of ("out") as al_books_pack and then not al_books_pack.is_empty
			then
				create l_reader.make (create {BIB_CONFIG}.make_with_core (content_path (l_cli.option_value_or_default ("content", ""))))
				l_reader.open
				if not l_reader.is_open then
					print ("bible_build: content.db could not be opened, so references cannot be linked%N")
					l_failed := True
				else
					create l_books.make (l_reader.books)
					if l_books.sidecars_in (al_manifests).is_empty then
						print ("bible_build: no *.book.json in " + al_manifests + "%N")
						l_failed := True
					else
						l_books.build (l_books.sidecars_in (al_manifests), al_books_pack, l_cli.option_value_or_default ("frameworks-pack", ""))
						if attached l_books.last_error as al_error then
							print ("bible_build failed: ")
							print (al_error)
							print ("%N")
							l_failed := True
						else
							print ("bible_build: wrote " + al_books_pack + " (" + l_books.book_count.out + " books, " + l_books.chapter_count.out + " chapters, "
								+ l_books.block_count.out + " blocks, " + l_books.passage_count.out + " passages cited, " + l_books.framework_use_count.out + " framework uses)%N")
						end
					end
					l_reader.close
				end
			elseif attached l_cli.value_of ("frameworks") as al_folder and then not al_folder.is_empty
				and then attached l_cli.value_of ("out") as al_frameworks_pack and then not al_frameworks_pack.is_empty
			then
				create l_frameworks.make
				if l_frameworks.sidecars_in (al_folder).is_empty then
					print ("bible_build: no *.framework.json in " + al_folder + "%N")
					l_failed := True
				else
					l_frameworks.build (l_frameworks.sidecars_in (al_folder), al_frameworks_pack, l_cli.option_value_or_default ("uses", ""))
					if attached l_frameworks.last_error as al_error then
						print ("bible_build failed: ")
						print (al_error)
						print ("%N")
						l_failed := True
					else
						across l_frameworks.warnings as ic_warning loop
							print ("bible_build: warning: ")
							print (ic_warning)
							print ("%N")
						end
						print ("bible_build: wrote " + al_frameworks_pack + " (" + l_frameworks.framework_count.out + " frameworks, " + l_frameworks.alias_count.out + " spellings, "
							+ l_frameworks.section_count.out + " sections, " + l_frameworks.related_count.out + " related, " + l_frameworks.use_count.out + " commentary uses)%N")
					end
				end
			elseif attached l_cli.value_of ("commentary") as al_sidecar and then not al_sidecar.is_empty
				and then attached l_cli.value_of ("out") as al_pack and then not al_pack.is_empty
			then
				create l_commentary.make
				if l_commentary.sidecars_in (al_sidecar).is_empty then
					print ("bible_build: no <Book>/_build/*.sections.json under " + al_sidecar + "%N")
					l_failed := True
				else
					l_commentary.build (l_commentary.sidecars_in (al_sidecar), al_pack)
				end
				if l_failed then
						-- Said above.
				elseif attached l_commentary.last_error as al_error then
					print ("bible_build failed: ")
					print (al_error)
					print ("%N")
					l_failed := True
				else
					print ("bible_build: wrote " + al_pack + " (" + l_commentary.book_count.out + " books, " + l_commentary.section_count.out + " sections, " + l_commentary.claim_count.out + " claims, "
						+ l_commentary.term_count.out + " terms, " + l_commentary.list_count.out + " list items, " + l_commentary.restricted_count.out + " restricted quotations)%N")
				end
			elseif attached l_cli.value_of ("bible") as al_bible and then not al_bible.is_empty
				and then attached l_cli.value_of ("out") as al_out and then not al_out.is_empty
			then
				create l_builder.make
				l_build_id := l_cli.option_value_or_default ("build-id", "content-v2")
				if not l_build_id.is_empty then
					l_builder.set_build_id (l_build_id)
				end
				l_builder.set_built_at (l_cli.option_value_or_default ("built-at", ""))
				l_builder.set_tvtms_path (l_cli.option_value_or_default ("tvtms", ""))
				l_builder.build (al_bible, al_out)
				if attached l_builder.last_error as al_error then
					print ("bible_build failed: ")
					print (al_error)
					print ("%N")
					l_failed := True
				else
					print ("bible_build: wrote " + al_out + " (" + l_builder.books_written.out + " books, " + l_builder.versions_written.out + " versions, " + l_builder.verses_written.out + " verses (" + l_builder.verses_indexed.out + " indexed), " + l_builder.cross_references_written.out + " cross-references, " + l_builder.versification_rows_written.out + " versification rows (" + l_builder.versification_rows_repeated.out + " repeated, " + l_builder.versification_rows_unplaced.out + " unplaced), build " + l_builder.build_id.to_string_8 + ")%N")
				end
			else
				print ("bible_build: --out and either --bible or --commentary each need a path.%N")
				l_failed := True
			end
				-- One exit point, after everything is closed (design scan 31).
			if l_failed then
				(create {EXCEPTIONS}).die (1)
			end
		end

end
