note
	description: "[
		Where the personal edition's databases are, for every face (the command
		line and the window): the data folder beside the running program (where
		the installer puts both), then %LOCALAPPDATA%\simple_bible (where
		bible_build writes content.db); for the concordance pack also the
		SIMPLE_BIBLE_CONC variable.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_DATA_LOCATION

feature -- Access

	content_path: STRING
			-- content.db beside this program, else in %LOCALAPPDATA%\simple_bible (that path even when
			-- it does not exist yet, so `open' can say what is missing).
		do
			Result := first_file (<<installed_data ("content.db"), local_data ("content.db")>>)
			if Result.is_empty then
				Result := local_data ("content.db")
			end
		ensure
			named: not Result.is_empty
		end

	conc_path: STRING
			-- conc.db beside this program, else the SIMPLE_BIBLE_CONC variable, else conc.db in
			-- %LOCALAPPDATA%\simple_bible; empty when none exists.
		local
			l_variable: STRING
		do
			if attached (create {SIMPLE_ENV}).item ("SIMPLE_BIBLE_CONC") as al_path then
				l_variable := al_path.to_string_8
			else
				create l_variable.make_empty
			end
			Result := first_file (<<installed_data ("conc.db"), l_variable, local_data ("conc.db")>>)
		end

	settings_path: STRING
			-- The reader's settings file, always in %LOCALAPPDATA%\simple_bible (never beside the program,
			-- which an installer replaces).
		do
			Result := local_data ("settings.txt")
		ensure
			not_empty: not Result.is_empty
		end

	user_path: STRING
			-- The reader's own notes (user.db), always in %LOCALAPPDATA%\simple_bible, beside the
			-- settings: never beside the program, which an installer replaces.
		do
			Result := local_data ("user.db")
		ensure
			not_empty: not Result.is_empty
		end

feature {NONE} -- Implementation

	installed_data (a_name: STRING): STRING
			-- `a_name' in the data folder beside this program.
		do
			Result := (create {SIMPLE_ENV}).executable_folder.to_string_8 + "\data\" + a_name
		end

	local_data (a_name: STRING): STRING
			-- `a_name' in %LOCALAPPDATA%\simple_bible, or in the current folder when that is unset.
		do
			if attached (create {SIMPLE_ENV}).item ("LOCALAPPDATA") as al_folder then
				Result := al_folder.to_string_8 + "\simple_bible\" + a_name
			else
				Result := a_name.twin
			end
		end

	first_file (a_paths: ARRAY [STRING]): STRING
			-- The first of `a_paths' that names an existing file, or empty.
		do
			create Result.make_empty
			across a_paths as ic until not Result.is_empty loop
				if not ic.is_empty and then (create {SIMPLE_FILE}.make (ic)).is_file then
					Result := ic
				end
			end
		end

end
