note
	description: "[
		Reads the engine's own source files for the static layering and purity
		tests. Paths are resolved against `root', so the suite runs from any folder.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SOURCE_SCAN

feature -- Access

	source_files: ARRAYED_LIST [STRING_8]
			-- Every .e file of the engine clusters, as "src/<cluster>/<file>".
		local
			d: DIRECTORY
		do
			create Result.make (200)
			across Clusters as c loop
				create d.make (root + "/" + c)
				if d.exists then
					across d.entries as n loop
						if n.has_extension ("e") then
							Result.extend (c + "/" + n.name.to_string_8)
						end
					end
				end
			end
		end

	files_in (a_folder: STRING_8): ARRAYED_LIST [STRING_8]
			-- Every .e file directly in `a_folder' (relative to `root'), as "<folder>/<file>".
		local
			d: DIRECTORY
		do
			create Result.make (10)
			create d.make (root + "/" + a_folder)
			if d.exists then
				across d.entries as n loop
					if n.has_extension ("e") then
						Result.extend (a_folder + "/" + n.name.to_string_8)
					end
				end
			end
		end

	root: STRING_8
			-- Project folder: the current folder when it holds the engine ECF,
			-- otherwise $SIMPLE_EIFFEL/simple_bible.
		local
			f: RAW_FILE
		once
			create f.make_with_name ("simple_bible.ecf")
			if f.exists then
				Result := "."
			elseif attached (create {EXECUTION_ENVIRONMENT}).item ("SIMPLE_EIFFEL") as l_fleet then
				Result := l_fleet.to_string_8 + "/simple_bible"
			else
				Result := "."
			end
		end

	file_text (a_path: STRING_8): STRING_8
			-- Contents of `a_path', relative to `root' (empty when unreadable).
		local
			f: PLAIN_TEXT_FILE
		do
			create Result.make_empty
			create f.make_with_name (root + "/" + a_path)
			if f.exists and then f.is_readable then
				f.open_read
				if f.count > 0 then
					f.read_stream (f.count)
					Result := f.last_string.twin
				end
				f.close
			end
		end

	code_of (a_path: STRING_8): STRING_8
			-- `a_path' without comments (text from "--" to the end of each line).
		local
			l_text: STRING_8
			i: INTEGER
		do
			l_text := file_text (a_path)
			create Result.make (l_text.count)
			across l_text.split ('%N') as l loop
				i := l.substring_index ("--", 1)
				if i > 0 then
					Result.append (l.substring (1, i - 1))
				else
					Result.append (l)
				end
				Result.append_character ('%N')
			end
		end

	inherits (a_path: STRING_8; a_class: STRING_8): BOOLEAN
			-- Does the class in `a_path' list `a_class' as a parent?
		local
			l_code: STRING_8
			i, j: INTEGER
		do
			l_code := code_of (a_path)
			i := l_code.substring_index ("%Ninherit", 1)
			if i > 0 then
				j := l_code.substring_index ("%Nfeature", i)
				if j = 0 then
					j := l_code.count
				end
				Result := across l_code.substring (i, j).split ('%N') as l some is_parent_line (l, a_class) end
			end
		end

	is_parent_line (a_line, a_class: STRING_8): BOOLEAN
			-- Is `a_line' exactly a parent clause naming `a_class'?
		local
			l: STRING_8
		do
			l := a_line.twin
			l.left_adjust
			l.right_adjust
			Result := l.same_string (a_class)
		end

feature -- Constants

	Clusters: ARRAYED_LIST [STRING_8]
			-- "src" and every folder directly under it, found when the scan runs
			-- (scan 23: a fixed list went stale when src/plugin became src/pack and
			-- src/concordance arrived, so the purity tests never read them).
		local
			d, l_sub: DIRECTORY
		once
			create Result.make (25)
			Result.extend ("src")
			create d.make (root + "/src")
			if d.exists then
				across d.entries as n loop
					if not n.name.same_string (".") and not n.name.same_string ("..") then
						create l_sub.make (root + "/src/" + n.name.to_string_8)
						if l_sub.exists then
							Result.extend ("src/" + n.name.to_string_8)
						end
					end
				end
			end
		end

end
