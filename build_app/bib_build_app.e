note
	description: "[
		bible_build: writes content.db v2 from the vault's bible.db (Phase 4,
		Task 10). Usage:
			bible_build --bible <bible.db> --out <content.db> [--build-id <id>] [--built-at <ISO time>]
		Exit code 0 on success, 1 on failure (the reason is printed).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_BUILD_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Parse the arguments and build.
		local
			l_cli: SIMPLE_CLI
			l_builder: BIB_CONTENT_BUILDER
			l_build_id: STRING
			l_failed: BOOLEAN
		do
			create l_cli.make
			l_cli.set_app_info ("bible_build", "Writes content.db v2 (books, versions, every verse) from the vault's bible.db.", {BIB_CONTENT_BUILDER}.Builder_name)
			l_cli.add_required_option ("b|bible", "The vault's bible.db", "path")
			l_cli.add_required_option ("o|out", "The content.db to write", "path")
			l_cli.add_option_with_default ("i|build-id", "The build id (the edition)", "id", "content-v2")
			l_cli.add_option_with_default ("t|built-at", "The build time, for a byte-identical rebuild (empty: now)", "ISO time", "")
			l_cli.parse
			if l_cli.has_errors then
				across l_cli.errors as ic loop
					print (ic + "%N")
				end
				l_failed := True
			elseif attached l_cli.value_of ("bible") as al_bible and then not al_bible.is_empty
				and then attached l_cli.value_of ("out") as al_out and then not al_out.is_empty
			then
				create l_builder.make
				l_build_id := l_cli.option_value_or_default ("build-id", "content-v2")
				if not l_build_id.is_empty then
					l_builder.set_build_id (l_build_id)
				end
				l_builder.set_built_at (l_cli.option_value_or_default ("built-at", ""))
				l_builder.build (al_bible, al_out)
				if attached l_builder.last_error as al_error then
					print ("bible_build failed: ")
					print (al_error)
					print ("%N")
					l_failed := True
				else
					print ("bible_build: wrote " + al_out + " (" + l_builder.books_written.out + " books, " + l_builder.versions_written.out + " versions, " + l_builder.verses_written.out + " verses, " + l_builder.cross_references_written.out + " cross-references, build " + l_builder.build_id.to_string_8 + ")%N")
				end
			else
				print ("bible_build: --bible and --out each need a path.%N")
				l_failed := True
			end
				-- One exit point, after everything is closed (design scan 31).
			if l_failed then
				(create {EXCEPTIONS}).die (1)
			end
		end

end
