note
	description: "[
		bible: simple_bible from the command line (Phase 4, Task 9; FR-061).
			bible word <headword number> [--corpus CODE]
			bible english <word>
			bible verse <book> <chapter> <verse> [--corpus CODE]
			bible strongs <H1234 or G3056>
		--content names content.db (default %LOCALAPPDATA%\simple_bible\content.db);
		--conc names the concordance pack (default the SIMPLE_BIBLE_CONC variable).
		The first line printed is the pack's own edition label (FR-157).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CLI_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Parse the arguments, open the engine, run one command.
		local
			l_cli: SIMPLE_CLI
			l_config: BIB_CONFIG
			l_bible: SIMPLE_BIBLE
			l_commands: BIB_CLI_COMMANDS
			l_content: STRING
		do
			create l_cli.make
			l_cli.set_app_info ("bible", "simple_bible from the command line: word, english, verse, strongs.", {BIB_RELEASE}.Engine_version)
			l_cli.add_option_with_default ("d|content", "The content database", "path", default_content)
			l_cli.add_option_with_default ("c|conc", "The concordance pack (conc.db)", "path", default_conc)
			l_cli.add_option_with_default ("p|corpus", "Corpus code for word and verse (word: empty = where it occurs most)", "code", "")
			l_cli.parse
			if l_cli.has_errors or l_cli.positional_args.is_empty then
				across l_cli.errors as ic loop
					print (ic + "%N")
				end
				print (Usage)
				fail
			else
				l_content := l_cli.option_value_or_default ("content", default_content)
				if l_content.is_empty then
					print ("No content database named (--content).%N")
					fail
				else
					create l_config.make_with_core (l_content)
					l_config := l_config.set_conc_path (l_cli.option_value_or_default ("conc", default_conc))
					create l_bible.make (l_config)
					l_bible.open
					if attached l_bible.last_error as al_error then
						print ("bible: ")
						print (al_error.message)
						print ("%N")
						fail
					else
						create l_commands.make (l_bible)
						print (l_commands.banner)
						print ("%N")
						run (l_commands, l_cli.positional_args, l_cli.option_value_or_default ("corpus", ""))
						l_bible.close
					end
				end
			end
				-- One exit point, after the engine is closed (design scan 31).
			if failed then
				(create {EXCEPTIONS}).die (1)
			end
		end

feature {NONE} -- Commands

	run (a_commands: BIB_CLI_COMMANDS; a_args: LIST [STRING]; a_corpus: STRING)
			-- Run the command `a_args' names.
		require
			command_given: not a_args.is_empty
		local
			l_command: STRING
		do
			l_command := a_args.first.as_lower
			if not a_commands.bible.conc_pack.is_available then
				print ("The concordance is not available, so there is nothing to look up.%N")
				fail
			elseif l_command.same_string ("word") and a_args.count = 2 and then a_args.i_th (2).is_integer_64 and then a_args.i_th (2).to_integer_64 > 0 then
				print (a_commands.word (a_args.i_th (2).to_integer_64, a_corpus))
			elseif l_command.same_string ("english") and a_args.count >= 2 and then not joined (a_args).is_empty then
				print (a_commands.english (joined (a_args)))
			elseif l_command.same_string ("verse") and a_args.count = 4 and then is_positive (a_args.i_th (2)) and then is_positive (a_args.i_th (3)) and then is_positive (a_args.i_th (4)) then
				print (a_commands.verse (a_args.i_th (2).to_integer, a_args.i_th (3).to_integer, a_args.i_th (4).to_integer, if a_corpus.is_empty then "WLC-MACULA" else a_corpus end))
			elseif l_command.same_string ("strongs") and a_args.count = 2 then
				print (a_commands.strongs (a_args.i_th (2)))
			else
				print (Usage)
				fail
			end
			print ("%N")
		end

	joined (a_args: LIST [STRING]): STRING
			-- The arguments after the command, joined by spaces.
		local
			i: INTEGER
		do
			create Result.make (20)
			from i := 2 until i > a_args.count loop
				if not Result.is_empty then
					Result.append_character (' ')
				end
				Result.append (a_args.i_th (i))
				i := i + 1
			end
		end

	is_positive (a_text: STRING): BOOLEAN
			-- Is `a_text' a positive whole number?
		do
			Result := a_text.is_integer and then a_text.to_integer > 0
		end

	failed: BOOLEAN
			-- Did a step fail? `make' exits with code 1, once, at its end.

	fail
			-- Record a failure; the program closes what it opened and exits with code 1 at the end.
		do
			failed := True
		ensure
			recorded: failed
		end

feature {NONE} -- Defaults

	default_content: STRING
			-- %LOCALAPPDATA%\simple_bible\content.db, where bible_build writes it.
		do
			if attached (create {SIMPLE_ENV}).item ("LOCALAPPDATA") as al_folder then
				Result := al_folder.to_string_8 + "\simple_bible\content.db"
			else
				Result := "content.db"
			end
		end

	default_conc: STRING
			-- The SIMPLE_BIBLE_CONC variable, or nothing.
		do
			if attached (create {SIMPLE_ENV}).item ("SIMPLE_BIBLE_CONC") as al_path then
				Result := al_path.to_string_8
			else
				Result := ""
			end
		end

	Usage: STRING = "[
		Usage:
		  bible word <headword number> [--corpus CODE]
		  bible english <word>
		  bible verse <book> <chapter> <verse> [--corpus CODE]
		  bible strongs <H1234 or G3056>
		Options: --content <content.db>  --conc <conc.db>

		]"

end
