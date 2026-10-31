note
	description: "[
		Writes THE River of Time pack (BIB_TIMELINE_SCHEMA) from timeline
		sidecars, `*.timeline.json', each a JSON object of "lanes", "events"
		and "citations" (Plan 22 phase 1, 2026-10-30). Every build starts
		from an empty file; nothing is merged.

		THE CHECKS, before a byte is written: every sidecar is a JSON object;
		lane, event and citation ids are lowercase letters and digits and
		unique across the sidecars; every event names a known lane, a known
		kind and an importance of 0, 1 or 2, and has at least one claim;
		every claim's date is EDTF this program reads (BIB_EDTF), with a known
		basis and a citation the sidecars hold; at most one claim of an event
		is its lean. A sidecar that breaks one refuses the build, and
		`last_error' names the file and the rule.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_TIMELINE_BUILDER

inherit
	BIB_PACK_WRITING

create
	make

feature {NONE} -- Initialization

	make
		do
			create schema
			create lanes.make (8)
			create events.make (64)
			create citations.make (16)
		ensure
			nothing_built: event_count = 0
		end

feature -- Access

	schema: BIB_TIMELINE_SCHEMA
			-- The tables written.

	lane_count, event_count, claim_count, citation_count: INTEGER
			-- What the last build wrote.

	sidecars_in (a_folder: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- Every `*.timeline.json' in the folder `a_folder'; or `a_folder' itself when it names a file.
		do
			Result := sidecars_with (a_folder, schema.Sidecar_extension)
		end

feature -- Commands

	build (a_sidecars: ITERABLE [READABLE_STRING_GENERAL]; a_pack: READABLE_STRING_GENERAL)
			-- Write the pack `a_pack' afresh from the sidecars `a_sidecars'.
		require
			some_sidecar: across a_sidecars as ic some not ic.is_empty end
			pack_named: not a_pack.is_empty
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			last_error := Void
			lane_count := 0
			event_count := 0
			claim_count := 0
			citation_count := 0
			lanes.wipe_out
			events.wipe_out
			citations.wipe_out
			across a_sidecars as ic until last_error /= Void loop
				read_sidecar (ic.to_string_32)
			end
			if last_error = Void then
				check_references
			end
			if last_error = Void then
				l_db := begin_private_pack (a_pack, schema, schema.Builder_command)
				put_pack_provenance (l_db, 1, "timeline sidecars", schema.Pack_title,
					"Claims gathered from Larry's histories and the registers they cite; each claim names its source.", schema.pack_license)
				if last_error = Void then
					write_all (l_db)
				end
				finish_pack (l_db)
			end
		ensure
			counted_on_success: last_error = Void implies event_count = events.count
		end

feature {NONE} -- Reading and checking

	lanes: ARRAYED_LIST [TUPLE [file, id, title, group: STRING_32; sort: INTEGER]]
	events: ARRAYED_LIST [TUPLE [file: STRING_32; event: BIB_TIMELINE_EVENT; status: STRING_32]]
	citations: ARRAYED_LIST [TUPLE [file, id, text: STRING_32]]

	read_sidecar (a_file: STRING_32)
			-- Read and check sidecar `a_file' into `lanes', `events' and `citations'.
		local
			l_json: SIMPLE_JSON
			l_root, l_o: SIMPLE_JSON_OBJECT
			i: INTEGER
		do
			create l_json
			if attached l_json.parse_file (a_file) as al_value and then al_value.is_object then
				l_root := al_value.as_object
				if attached l_root.array_item ({STRING_32} "lanes") as al_lanes then
					from i := 1 until i > al_lanes.count or last_error /= Void loop
						if attached al_lanes.object_item (i) as al_l then
							l_o := al_l
							fail_unless (schema.is_timeline_id (text_of (l_o, "id")), a_file, {STRING_32} "a lane id is not lowercase letters and digits: " + text_of (l_o, "id"))
							fail_unless (not across lanes as al_seen some al_seen.id.same_string (text_of (l_o, "id")) end, a_file, {STRING_32} "lane " + text_of (l_o, "id") + {STRING_32} " is given twice")
							fail_unless (not text_of (l_o, "title").is_empty, a_file, {STRING_32} "lane " + text_of (l_o, "id") + {STRING_32} " has no title")
							if last_error = Void then
								lanes.extend ([a_file, text_of (l_o, "id"), text_of (l_o, "title"), text_of (l_o, "group"), l_o.integer_item ({STRING_32} "sort").to_integer_32])
							end
						end
						i := i + 1
					end
				end
				if attached l_root.array_item ({STRING_32} "citations") as al_cites then
					from i := 1 until i > al_cites.count or last_error /= Void loop
						if attached al_cites.object_item (i) as al_c then
							fail_unless (schema.is_timeline_id (text_of (al_c, "id")), a_file, {STRING_32} "a citation id is not lowercase letters and digits: " + text_of (al_c, "id"))
								-- the same citation repeated in another sidecar (same id, same text) is one citation
							fail_unless (not across citations as al_seen some al_seen.id.same_string (text_of (al_c, "id")) and not al_seen.text.same_string (text_of (al_c, "text")) end,
								a_file, {STRING_32} "citation " + text_of (al_c, "id") + {STRING_32} " is given twice with different text")
							if last_error = Void and then not across citations as al_seen some al_seen.id.same_string (text_of (al_c, "id")) end then
								citations.extend ([a_file, text_of (al_c, "id"), text_of (al_c, "text")])
							end
						end
						i := i + 1
					end
				end
				if attached l_root.array_item ({STRING_32} "events") as al_events then
					from i := 1 until i > al_events.count or last_error /= Void loop
						if attached al_events.object_item (i) as al_e then
							read_event (a_file, al_e)
						end
						i := i + 1
					end
				end
			else
				last_error := {STRING_32} "Not a JSON object: " + a_file
			end
		end

	read_event (a_file: STRING_32; a_o: SIMPLE_JSON_OBJECT)
		local
			l_event: BIB_TIMELINE_EVENT
			l_id: STRING_32
			l_importance, i, l_leans: INTEGER
			l_edtf: BIB_EDTF
			l_basis: STRING_32
		do
			l_id := text_of (a_o, "id")
			l_importance := a_o.integer_item ({STRING_32} "importance").to_integer_32
			fail_unless (schema.is_timeline_id (l_id), a_file, {STRING_32} "an event id is not lowercase letters and digits: " + l_id)
			fail_unless (not across events as al_seen some al_seen.event.id.same_string (l_id) end, a_file, {STRING_32} "event " + l_id + {STRING_32} " is given twice")
			fail_unless (not text_of (a_o, "title").is_empty, a_file, {STRING_32} "event " + l_id + {STRING_32} " has no title")
			fail_unless (schema.is_kind (text_of (a_o, "kind")), a_file, {STRING_32} "event " + l_id + {STRING_32} " has an unknown kind: " + text_of (a_o, "kind"))
			fail_unless (l_importance >= 0 and l_importance <= 2, a_file, {STRING_32} "event " + l_id + {STRING_32} " has an importance that is not 0, 1 or 2")
			if last_error = Void then
				create l_event.make (l_id, text_of (a_o, "lane"), text_of (a_o, "title"), text_of (a_o, "kind"), l_importance, text_of (a_o, "summary"))
				if attached a_o.array_item ({STRING_32} "claims") as al_claims then
					from i := 1 until i > al_claims.count or last_error /= Void loop
						if attached al_claims.object_item (i) as al_c then
							create l_edtf.make (text_of (al_c, "edtf"))
							l_basis := text_of (al_c, "basis")
							if l_basis.is_empty then
								l_basis := {STRING_32} "evidence"
							end
							fail_unless (l_edtf.is_valid, a_file, {STRING_32} "event " + l_id + {STRING_32} ": the date %"" + l_edtf.text + {STRING_32} "%" is not one this program reads (" + l_edtf.error + {STRING_32} ")")
							fail_unless (across (<<"evidence", "text", "reckoning", "tradition">>) as b some b.same_string_general (l_basis) end, a_file, {STRING_32} "event " + l_id + {STRING_32} " has a claim with an unknown basis: " + l_basis)
							if last_error = Void then
								if attached al_c.item ({STRING_32} "lean") as al_lean and then al_lean.is_boolean and then al_lean.as_boolean then
									l_leans := l_leans + 1
									l_event.add_claim (create {BIB_CLAIM}.make (l_edtf, text_of (al_c, "chronology"), text_of (al_c, "held_by"), l_basis, text_of (al_c, "citation"), text_of (al_c, "note"), True))
								else
									l_event.add_claim (create {BIB_CLAIM}.make (l_edtf, text_of (al_c, "chronology"), text_of (al_c, "held_by"), l_basis, text_of (al_c, "citation"), text_of (al_c, "note"), False))
								end
							end
						end
						i := i + 1
					end
				end
				fail_unless (not l_event.claims.is_empty, a_file, {STRING_32} "event " + l_id + {STRING_32} " has no claim")
				fail_unless (l_leans <= 1, a_file, {STRING_32} "event " + l_id + {STRING_32} " has more than one lean")
				if last_error = Void then
					events.extend ([a_file, l_event, (if text_of (a_o, "status").is_empty then {STRING_32} "draft" else text_of (a_o, "status") end)])
				end
			end
		end

	check_references
			-- Every event's lane and every claim's citation is one the sidecars hold.
		do
			across events as ev until last_error /= Void loop
				fail_unless (across lanes as l some l.id.same_string (ev.event.lane) end, ev.file, {STRING_32} "event " + ev.event.id + {STRING_32} " names an unknown lane: " + ev.event.lane)
				across ev.event.claims as c until last_error /= Void loop
					fail_unless (c.citation_id.is_empty or else across citations as ct some ct.id.same_string (c.citation_id) end, ev.file,
						{STRING_32} "event " + ev.event.id + {STRING_32} " cites an unknown source: " + c.citation_id)
				end
			end
		end

feature {NONE} -- Writing

	write_all (a_db: SIMPLE_SQL_DATABASE)
		local
			k: INTEGER
		do
			across lanes as l until last_error /= Void loop
				a_db.execute_with_args ("INSERT INTO timeline_lane VALUES (?, ?, ?, ?, 'author', 1)", <<l.id, l.title, l.group, l.sort>>)
				check_db (a_db, {STRING_32} "Lane " + l.id + {STRING_32} " could not be written.")
				lane_count := lane_count + 1
			end
			across citations as c until last_error /= Void loop
				a_db.execute_with_args ("INSERT INTO timeline_citation VALUES (?, ?, 'author', 1)", <<c.id, c.text>>)
				check_db (a_db, {STRING_32} "Citation " + c.id + {STRING_32} " could not be written.")
				citation_count := citation_count + 1
			end
			across events as ev until last_error /= Void loop
				a_db.execute_with_args ("INSERT INTO timeline_event VALUES (?, ?, ?, ?, ?, ?, ?, 'author', 1)",
					<<ev.event.id, ev.event.lane, ev.event.title, ev.event.kind, ev.event.importance, ev.event.summary, ev.status>>)
				check_db (a_db, {STRING_32} "Event " + ev.event.id + {STRING_32} " could not be written.")
				k := 0
				across ev.event.claims as c until last_error /= Void loop
					k := k + 1
					a_db.execute_with_args ("INSERT INTO timeline_claim VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'author', 1)",
						<<ev.event.id, k, c.edtf.text, c.earliest, c.latest, c.edtf.precision, c.edtf.is_approximate.to_integer, c.edtf.is_uncertain.to_integer,
						c.chronology, c.held_by, c.basis, c.is_lean.to_integer, c.citation_id, c.remark>>)
					check_db (a_db, {STRING_32} "A claim of " + ev.event.id + {STRING_32} " could not be written.")
					claim_count := claim_count + 1
				end
				put_search_row (a_db, {STRING_32} "timeline:" + ev.event.id, ev.event.title, ev.event.title + {STRING_32} " " + ev.event.summary, "author")
				event_count := event_count + 1
			end
		end

end
