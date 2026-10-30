note
	description: "[
		File > Make ingest kits for a folder (2026-10-30, Larry): a kit beside
		every source in a folder (BIB_SOURCE_READER says which files are
		sources), as File > Make ingest kit writes one: "ch01.md" gets
		"ch01.kit.md".

		NEVER NEEDLESSLY: a source whose kit is there already and newer than it
		is passed over; a source changed since its kit was made gets a fresh
		one. Kits and prepared files are never sources.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_KIT_FOLDER

create
	make

feature {NONE} -- Initialization

	make (a_bible: SIMPLE_BIBLE)
			-- Kits listing what `a_bible' holds.
		require
			open: a_bible.is_open
		do
			bible := a_bible
			create reader
			create written.make (0)
			create remade.make (0)
			create skipped.make (0)
			create failed.make (0)
		end

feature -- Access

	bible: SIMPLE_BIBLE

	reader: BIB_SOURCE_READER

	written: ARRAYED_LIST [STRING_32]
			-- The kits the last `run' wrote for sources that had none.

	remade: ARRAYED_LIST [STRING_32]
			-- The kits it wrote again: their sources had changed since.

	skipped: ARRAYED_LIST [STRING_32]
			-- The sources it passed over: their kits are there and up to date.

	failed: ARRAYED_LIST [TUPLE [file, why: STRING_32]]
			-- The sources it could not read or write a kit for, with why.

	sources (a_folder: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- The sources in `a_folder', in name order.
		local
			l_sorted: SORTED_TWO_WAY_LIST [STRING_32]
		do
			create l_sorted.make
			if (create {SIMPLE_FILE}.make (a_folder)).is_directory then
				across (create {SIMPLE_FILE}.make (a_folder)).files as ic loop
					if reader.is_source_name (ic) then
						l_sorted.extend (ic)
					end
				end
			end
			create Result.make_from_iterable (l_sorted)
		end

	kit_path_for (a_source: READABLE_STRING_GENERAL): STRING_32
			-- "notes.txt" "notes.kit.md": where the kit of `a_source' goes.
		local
			l_source: STRING_32
			l_dot, l_slash: INTEGER
		do
			create l_source.make_from_string_general (a_source)
			l_dot := l_source.last_index_of ('.', l_source.count)
			l_slash := l_source.last_index_of ('\', l_source.count)
			if l_dot > l_slash + 1 then
				Result := l_source.substring (1, l_dot - 1) + reader.Kit_extension
			else
				Result := l_source + reader.Kit_extension
			end
		ensure
			a_kit: Result.ends_with (reader.Kit_extension)
		end

	is_kit_current (a_source: READABLE_STRING_GENERAL): BOOLEAN
			-- Is the kit of `a_source' there and no older than it?
		local
			l_kit: SIMPLE_FILE
		do
			create l_kit.make (kit_path_for (a_source))
			Result := l_kit.is_file and then l_kit.modified_time_100ns >= (create {SIMPLE_FILE}.make (a_source)).modified_time_100ns
		end

feature -- Making

	run (a_folder: READABLE_STRING_GENERAL)
			-- A kit beside every source in `a_folder' that has none, or an older one.
		local
			l_folder, l_path, l_kit: STRING_32
			l_had_kit: BOOLEAN
		do
			written.wipe_out
			remade.wipe_out
			skipped.wipe_out
			failed.wipe_out
			create l_folder.make_from_string_general (a_folder)
			across sources (l_folder) as ic loop
				l_path := l_folder + {STRING_32} "\" + ic
				l_kit := kit_path_for (l_path)
				if is_kit_current (l_path) then
					skipped.extend (ic)
				elseif attached reader.text_of (l_path) as al_text then
					l_had_kit := (create {SIMPLE_FILE}.make (l_kit)).is_file
					if (create {SIMPLE_FILE}.make (l_kit)).write_text_utf_8 ((create {BIB_INGEST_KIT}.make (bible)).kit_text (ic, al_text)) then
						if l_had_kit then
							remade.extend ((create {SIMPLE_FILE}.make (l_kit)).file_name)
						else
							written.extend ((create {SIMPLE_FILE}.make (l_kit)).file_name)
						end
					else
						failed.extend ([ic, {STRING_32} "the kit could not be written at " + l_kit])
					end
				else
					failed.extend ([ic, if attached reader.last_error as al_why then al_why else {STRING_32} "it could not be read" end])
				end
			end
		ensure
			every_source_accounted: written.count + remade.count + skipped.count + failed.count = sources (a_folder).count
		end

end
