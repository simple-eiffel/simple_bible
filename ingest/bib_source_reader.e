note
	description: "[
		The text of a source an ingest kit is made from (2026-10-30): the one
		place that knows which files are sources and how each kind reads, so a
		kit for one file and kits for a folder read alike. Plain text and
		Markdown read as they are.

		Not a source: a kit (".kit.md") or a prepared file (".prepared.md"),
		though both end in ".md".
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SOURCE_READER

feature -- Kinds

	is_source_name (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_name' name a source of a kind this reader reads, not a kit or a prepared file?
		local
			l_name: STRING_32
		do
			l_name := a_name.to_string_32.as_lower
			if not l_name.ends_with (Kit_extension) and not l_name.ends_with (Prepared_extension) then
				Result := across Extensions as ic some l_name.ends_with (ic) end
			end
		end

	Extensions: ARRAY [STRING_32]
			-- The endings of the sources it reads.
		once
			Result := <<{STRING_32} ".txt", {STRING_32} ".md">>
		end

	dialog_filter: STRING_32
			-- The file dialog's pattern for sources: "*.txt;*.md".
		do
			create Result.make (40)
			across Extensions as ic loop
				if not Result.is_empty then
					Result.append_character (';')
				end
				Result.append ({STRING_32} "*" + ic)
			end
		end

	Kit_extension: STRING_32 = ".kit.md"

	Prepared_extension: STRING_32 = ".prepared.md"

feature -- Reading

	text_of (a_path: READABLE_STRING_GENERAL): detachable STRING_32
			-- The text of the source at `a_path'; Void, with `last_error', when it cannot be read.
		local
			l_file: SIMPLE_FILE
		do
			last_error := Void
			create l_file.make (a_path)
			if not l_file.is_file then
				last_error := {STRING_32} "No file at " + a_path.to_string_32
			elseif not is_source_name (l_file.file_name) then
				last_error := {STRING_32} "Not a kind of file a kit is made from: " + l_file.file_name
			else
				Result := l_file.read_text_utf_8
			end
		ensure
			read_or_why: (Result = Void) = (last_error /= Void)
		end

	last_error: detachable STRING_32
			-- Why the last `text_of' read nothing.

end
