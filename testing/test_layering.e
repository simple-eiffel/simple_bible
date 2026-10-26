note
	description: "[
		Static layering checks over the engine's own sources and ECF (paths
		resolved by SOURCE_SCAN.root): no face or build dependency (AC-1a-36), no banned
		accessor (AC-1a-47), only the map creates mapped references (AC-1a-18),
		no engine cluster names a user-cluster type (RQ-01), no AI path from
		search (AC-1a-54), no GUI or console type in the engine.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_LAYERING

inherit
	TEST_SET_BASE

feature -- Tests

	test_engine_ecf_has_no_face_or_build_dependency
		local
			s: SOURCE_SCAN
			l_ecf: STRING_8
		do
			create s
			l_ecf := s.file_text ("simple_bible.ecf")
			assert ("ecf read", not l_ecf.is_empty)
				-- Only the engine target counts: the test target may name more (design scan 31).
			if l_ecf.has_substring ("<target name=%"simple_bible%">") then
				l_ecf := l_ecf.substring (l_ecf.substring_index ("<target name=%"simple_bible%">", 1), l_ecf.substring_index ("</target>", 1))
			end
			assert ("engine target found", l_ecf.has_substring ("<target name=%"simple_bible%">"))
			across Forbidden_libraries as l loop
				assert ("no " + l, not l_ecf.has_substring ("%"" + l + "%""))
			end
		end

	test_engine_names_no_build_or_face_class
			-- RQ-01: the engine never names the build pipeline's or a face's classes (the test target
			-- compiles them, so a slip would pass here and break only the face builds; scan 31).
		local
			s: SOURCE_SCAN
		do
			create s
			across s.source_files as f loop
				across Build_and_face_classes as c loop
					assert ("no " + c + " in " + f, not s.code_of (f).has_substring (c))
				end
			end
		end

	test_command_line_cluster_is_a_face
			-- The command-line commands read the engine only: no SQL and no GUI or console library (scan 31).
		local
			s: SOURCE_SCAN
		do
			create s
			assert ("cli sources found", not s.files_in ("cli").is_empty)
			across s.files_in ("cli") as f loop
				across <<"SIMPLE_SQL", ".query", ".execute", "SW_", "SIMPLE_CONSOLE", "SIMPLE_CLI">> as c loop
					assert ("no " + c + " in " + f, not s.code_of (f).has_substring (c))
				end
			end
		end

	test_no_banned_accessor
		local
			s: SOURCE_SCAN
		do
			create s
			assert ("sources found", s.source_files.count > 100)
			across s.source_files as f loop
				assert ("no string_value_or_void: " + f, not s.code_of (f).has_substring ("string_value_or_void"))
				assert ("no string_value_or_default: " + f, not s.code_of (f).has_substring ("string_value_or_default"))
			end
		end

	test_only_the_map_creates_mapped_refs
		local
			s: SOURCE_SCAN
		do
			create s
			across s.source_files as f loop
				if not f.has_substring ("bib_versification_map.e") then
					assert ("no mapped-ref creation: " + f, not s.code_of (f).has_substring ("{BIB_MAPPED_REF}.make"))
				end
			end
		end

	test_no_engine_cluster_names_user_types
		local
			s: SOURCE_SCAN
		do
			create s
			across s.source_files as f loop
				if not f.has_substring ("src/user/") then
					across User_types as u loop
						assert (u + " named in " + f, not s.code_of (f).has_substring (u))
					end
				end
			end
		end

	test_no_ai_reachable_from_search
		local
			s: SOURCE_SCAN
		do
			create s
			across s.source_files as f loop
				if f.has_substring ("src/search/") then
					assert ("no AI type in " + f, not s.code_of (f).has_substring ("BIB_AI_"))
				end
			end
		end

	test_no_face_types_in_engine
		local
			s: SOURCE_SCAN
		do
			create s
			across s.source_files as f loop
				assert ("no SW_ in " + f, not s.code_of (f).has_substring (" SW_"))
				assert ("no SHELL_ in " + f, not s.code_of (f).has_substring (" SHELL_"))
				assert ("no SIMPLE_CONSOLE in " + f, not s.code_of (f).has_substring ("SIMPLE_CONSOLE"))
			end
		end

feature {NONE} -- Constants

	Build_and_face_classes: ARRAY [STRING_8]
			-- Classes of the build pipeline and the faces, which the engine must never name.
		once
			Result := <<"BIB_CONTENT_BUILDER", "BIB_BUILD_APP", "BIB_CLI_COMMANDS", "BIB_CLI_APP">>
		end

	Forbidden_libraries: ARRAY [STRING_8]
		once
			Result := <<"simple_widgets", "simple_shaping", "simple_cairo", "simple_shell", "simple_onnx",
				"simple_xml", "simple_csv", "simple_graph", "simple_winhttp", "simple_http", "simple_console", "simple_cli">>
		end

	User_types: ARRAY [STRING_8]
		once
			Result := <<"BIB_USER_STORE", "BIB_USER_ITEM", "BIB_NOTE_STORE", "BIB_HIGHLIGHT", "BIB_BOOKMARK",
				"BIB_TAG_ASSIGNMENT", "BIB_VISIT", "BIB_USER_BACKUP", "BIB_MARKDOWN_NOTE_STORE", "BIB_DB_NOTE_STORE">>
		end

end
