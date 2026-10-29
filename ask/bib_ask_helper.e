note
	description: "[
		The Ask helper, run as a child process (0.7.31; Larry, 2026-10-29: Simple
		Bible ships only the Cactus Needle CPU engine, in a separate helper so the
		program itself never depends on its DLL). The helper (needle_helper.exe,
		with libneedle.dll, the fine-tuned model needle_bible.cact and the tool
		list bible_tools.json beside it) speaks JSON lines: one "ready" line when
		it starts, then one reply per request, {"id":..,"calls":[..],"ms":..}.

		OFF, NEVER BROKEN: a missing file, no ready line within `Wait_ms', a ready
		line saying false, a reply late past `Wait_ms' (the helper is then killed)
		or one that does not read leaves Ask off, `off_reason' saying why, and the
		rest of the program as it is. The files are checked before the helper is
		started: without libneedle.dll Windows would end it before it says a word.

		Telemetry: Cactus documents NEEDLE_TELEMETRY=0 and DO_NOT_TRACK=1 as the
		off switches; they are set in this process before the helper starts, so
		it inherits them (the helper sets them as well).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ASK_HELPER

create
	make

feature {NONE} -- Initialization

	make (a_folder: READABLE_STRING_GENERAL)
			-- A helper whose files are in the folder `a_folder'; not started.
		do
			folder := a_folder.to_string_32
			create off_reason.make_empty
			create engine.make_empty
			create calls.make (0)
		ensure
			not_ready: not is_ready
		end

feature -- Access

	folder: STRING_32
			-- Where the helper and its files are.

	is_ready: BOOLEAN
			-- Is the helper running and answering?

	off_reason: STRING_32
			-- Why Ask is off; empty while it is ready or not yet started.

	engine: STRING_32
			-- What the ready line names ("libneedle"); empty before.

	calls: ARRAYED_LIST [BIB_ASK_CALL]
			-- The last `ask''s calls; empty when no tool fits or it failed.

	last_ms: INTEGER
			-- How long the last answer took in the helper.

	Wait_ms: INTEGER = 10000
			-- The longest the ready line or a reply may take.

	Required_files: ARRAY [STRING_8]
			-- The files that must stand in `folder'.
		once
			Result := <<"needle_helper.exe", "libneedle.dll", "needle_bible.cact", "bible_tools.json">>
		end

	missing_file: detachable STRING_32
			-- The first of `Required_files' not in `folder'; Void when all are.
		do
			across Required_files as ic until Result /= Void loop
				if not (create {SIMPLE_FILE}.make (path_of (ic))).is_file then
					Result := ic.to_string_32
				end
			end
		end

feature -- Commands

	start
			-- Start the helper and read its ready line: `is_ready', or off with `off_reason'.
		require
			not_running: not is_ready
		local
			l_process: SIMPLE_PIPED_PROCESS
			l_env: SIMPLE_ENV
		do
			create off_reason.make_empty
			if attached missing_file as al_missing then
				off_reason := {STRING_32} "The Ask helper's file " + al_missing + {STRING_32} " is missing."
			else
				create l_env
				l_env.put ("0", "NEEDLE_TELEMETRY")
				l_env.put ("1", "DO_NOT_TRACK")
				create l_process.make
				l_process.set_show_window (False)
				l_process.set_ends_with_owner (True)
				l_process.start_in_directory ({STRING_32} "%"" + path_of ("needle_helper.exe") + {STRING_32} "%"", folder)
				if not l_process.is_started then
					off_reason := {STRING_32} "The Ask helper did not start."
				else
					process := l_process
					l_process.read_line (Wait_ms)
					if attached l_process.last_line as al_line and then attached object_of (al_line) as al_ready
						and then attached al_ready.item ({STRING_32} "ready") as al_flag and then al_flag.is_boolean and then al_flag.as_boolean
					then
						is_ready := True
						engine := text_in (al_ready, "engine")
					elseif attached l_process.last_line as al_line and then attached object_of (al_line) as al_refused then
						off_reason := {STRING_32} "The Ask helper could not load: " + text_in (al_refused, "error")
					else
						off_reason := {STRING_32} "The Ask helper did not say it was ready within " + (Wait_ms // 1000).out.to_string_32 + {STRING_32} " seconds."
					end
					if not is_ready then
						stop
					end
				end
			end
		ensure
			ready_or_said: is_ready = off_reason.is_empty
		end

	ask (a_query: READABLE_STRING_GENERAL)
			-- `calls': the tools the helper proposes for `a_query'. A late or unreadable reply turns
			-- Ask off.
		require
			ready: is_ready
			query_given: not a_query.is_empty
		local
			l_request: STRING_32
		do
			create calls.make (2)
			request_id := request_id + 1
			create l_request.make (a_query.count + 40)
			l_request.append ({STRING_32} "{%"id%":" + request_id.out.to_string_32 + {STRING_32} ",%"query%":")
			l_request.append (json_string (a_query))
			l_request.append_character ('}')
			if attached process as al_process then
				al_process.write_line (l_request)
				al_process.read_line (Wait_ms)
				if attached al_process.last_line as al_line and then attached object_of (al_line) as al_reply then
					if attached al_reply.item ({STRING_32} "error") as al_error and then al_error.is_string then
						off_reason := {STRING_32} "The Ask helper answered with an error: " + al_error.as_string_32
					else
						if attached al_reply.item ({STRING_32} "ms") as al_ms and then al_ms.is_integer then
							last_ms := al_ms.as_integer.to_integer_32
						end
						read_calls (al_reply)
					end
				else
					off_reason := {STRING_32} "The Ask helper did not answer within " + (Wait_ms // 1000).out.to_string_32 + {STRING_32} " seconds."
				end
			end
			if not off_reason.is_empty then
				stop
			end
		ensure
			calls_only_while_ready: not is_ready implies calls.is_empty
		end

	stop
			-- End the helper (killed when it does not end on its own).
		do
			if attached process as al_process then
				if al_process.is_started then
					al_process.close_input
					al_process.wait_for_exit (2000)
					if not al_process.has_exited then
						al_process.kill
					end
				end
				al_process.close
			end
			process := Void
			is_ready := False
			if off_reason.is_empty then
				off_reason := {STRING_32} "The Ask helper was stopped."
			end
			create calls.make (0)
		ensure
			stopped: not is_ready
		end

feature {NONE} -- Implementation

	process: detachable SIMPLE_PIPED_PROCESS
			-- The running helper.

	request_id: INTEGER
			-- The last request's id.

	path_of (a_name: READABLE_STRING_GENERAL): STRING_32
			-- File `a_name' in `folder'.
		do
			Result := folder + {STRING_32} "\" + a_name.to_string_32
		end

	object_of (a_line: READABLE_STRING_GENERAL): detachable SIMPLE_JSON_OBJECT
			-- `a_line' read as a JSON object; Void when it is not one.
		do
			if attached (create {SIMPLE_JSON}).parse (a_line.to_string_32) as al_value and then al_value.is_object then
				Result := al_value.as_object
			end
		end

	text_in (a_object: SIMPLE_JSON_OBJECT; a_key: READABLE_STRING_GENERAL): STRING_32
			-- The string under `a_key'; empty when absent or not a string.
		do
			if attached a_object.item (a_key.to_string_32) as al_value and then al_value.is_string then
				Result := al_value.as_string_32
			else
				create Result.make_empty
			end
		end

	read_calls (a_reply: SIMPLE_JSON_OBJECT)
			-- `calls' from the reply's "calls" array: each a name and its arguments, a text or a
			-- list of texts; anything else in it is passed over.
		local
			l_call: BIB_ASK_CALL
			l_list: ARRAYED_LIST [STRING_32]
			i, j: INTEGER
		do
			if attached a_reply.array_item ({STRING_32} "calls") as al_calls then
				from i := 1 until i > al_calls.count loop
					if al_calls [i].is_object and then not text_in (al_calls [i].as_object, "name").is_empty then
						create l_call.make (text_in (al_calls [i].as_object, "name"))
						if attached al_calls [i].as_object.object_item ({STRING_32} "arguments") as al_arguments then
							across al_arguments.keys as ic_key loop
								if attached al_arguments.item (ic_key) as al_value then
									if al_value.is_string then
										l_call.set_text (ic_key, al_value.as_string_32)
									elseif al_value.is_array then
										create l_list.make (3)
										from j := 1 until j > al_value.as_array.count loop
											if al_value.as_array [j].is_string then
												l_list.extend (al_value.as_array [j].as_string_32)
											end
											j := j + 1
										end
										l_call.set_texts (ic_key, l_list)
									elseif al_value.is_integer then
										l_call.set_text (ic_key, al_value.as_integer.out)
									end
								end
							end
						end
						calls.extend (l_call)
					end
					i := i + 1
				end
			end
		end

	json_string (a_text: READABLE_STRING_GENERAL): STRING_32
			-- `a_text' as a JSON string: quoted, with quote, backslash and control characters escaped.
		local
			l_code: NATURAL_32
		do
			create Result.make (a_text.count + 2)
			Result.append_character ('"')
			across a_text.to_string_32 as ic loop
				l_code := ic.natural_32_code
				if ic = '"' then
					Result.append ({STRING_32} "\%"")
				elseif ic = '\' then
					Result.append ({STRING_32} "\\")
				elseif ic = '%N' then
					Result.append ({STRING_32} "\n")
				elseif ic = '%R' then
					Result.append ({STRING_32} "\r")
				elseif ic = '%T' then
					Result.append ({STRING_32} "\t")
				elseif l_code < 32 then
					Result.append ({STRING_32} "\u00" + l_code.to_hex_string.substring (7, 8))
				else
					Result.append_character (ic)
				end
			end
			Result.append_character ('"')
		ensure
			quoted: Result.starts_with ({STRING_32} "%"") and Result.ends_with ({STRING_32} "%"")
		end

invariant
	off_or_ready: is_ready implies off_reason.is_empty

end
