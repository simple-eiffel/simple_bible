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

		THE ATLAS (phase 3, 2026-10-31): "places" (each with a known kind, a
		min_zoom of 1 or more and at least one location claim, each claim a
		point on the planet, a doubt of 0 meters or more, a known basis and a
		citation; at most one lean), "event_places" (a known event and place,
		once), "routes" (an even list of at least two points, an EDTF date, a
		citation). A citation may name its "source" and "license": each such
		license gets its own provenance row, credited apart (OpenBible.info,
		CC BY 4.0; Wikidata, CC0), and the rows that cite it carry it.
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
			create places.make (32)
			create event_places.make (32)
			create routes.make (4)
			create licensed.make (2)
		ensure
			nothing_built: event_count = 0
		end

feature -- Access

	schema: BIB_TIMELINE_SCHEMA
			-- The tables written.

	lane_count, event_count, claim_count, citation_count: INTEGER
			-- What the last build wrote.

	place_count, place_claim_count, event_place_count, route_count: INTEGER
			-- What the last build wrote for the Atlas.

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
			place_count := 0
			place_claim_count := 0
			event_place_count := 0
			route_count := 0
			lanes.wipe_out
			events.wipe_out
			citations.wipe_out
			places.wipe_out
			event_places.wipe_out
			routes.wipe_out
			licensed.wipe_out
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
				across licensed as ic_l loop
					put_pack_provenance (l_db, ic_l.key, ic_l.source, ic_l.source, "Locations as the source gives them; each place names its record.",
						create {BIB_LICENSE}.make (ic_l.license, False, False, False, ic_l.source))
				end
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
	citations: ARRAYED_LIST [TUPLE [file, id, text, source, license: STRING_32]]
			-- Every citation; `source' and `license' given when a citation carries its own license.

	places: ARRAYED_LIST [TUPLE [file: STRING_32; place: BIB_PLACE]]

	event_places: ARRAYED_LIST [TUPLE [file, event_id, place_id: STRING_32]]

	routes: ARRAYED_LIST [TUPLE [file, id, name, points: STRING_32; is_certain: BOOLEAN; alternative_of: STRING_32; edtf: BIB_EDTF; citation: STRING_32]]

	licensed: ARRAYED_LIST [TUPLE [key: INTEGER; source, license: STRING_32]]
			-- A provenance row for each license a citation names, keys from 2.

	provenance_of (a_citation: READABLE_STRING_GENERAL): INTEGER
			-- The provenance row of what cites `a_citation': its license's row, else 1.
		do
			Result := 1
			across citations as ic_c loop
				if ic_c.id.same_string_general (a_citation) and not ic_c.license.is_empty then
					across licensed as ic_l loop
						if ic_l.license.same_string (ic_c.license) and ic_l.source.same_string (ic_c.source) then
							Result := ic_l.key
						end
					end
				end
			end
		ensure
			a_row: Result >= 1
		end

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
							fail_unless (text_of (al_c, "license").is_empty or else not text_of (al_c, "source").is_empty, a_file,
								{STRING_32} "citation " + text_of (al_c, "id") + {STRING_32} " names a license but no source")
							if last_error = Void and then not across citations as al_seen some al_seen.id.same_string (text_of (al_c, "id")) end then
								citations.extend ([a_file, text_of (al_c, "id"), text_of (al_c, "text"), text_of (al_c, "source"), text_of (al_c, "license")])
								if not text_of (al_c, "license").is_empty and then not across licensed as al_l some al_l.license.same_string (text_of (al_c, "license")) and al_l.source.same_string (text_of (al_c, "source")) end then
									licensed.extend ([licensed.count + 2, text_of (al_c, "source"), text_of (al_c, "license")])
								end
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
				if attached l_root.array_item ({STRING_32} "places") as al_places then
					from i := 1 until i > al_places.count or last_error /= Void loop
						if attached al_places.object_item (i) as al_p then
							read_place (a_file, al_p)
						end
						i := i + 1
					end
				end
				if attached l_root.array_item ({STRING_32} "event_places") as al_links then
					from i := 1 until i > al_links.count or last_error /= Void loop
						if attached al_links.object_item (i) as al_k then
							fail_unless (not across event_places as al_seen some al_seen.event_id.same_string (text_of (al_k, "event")) and al_seen.place_id.same_string (text_of (al_k, "place")) end,
								a_file, {STRING_32} "event " + text_of (al_k, "event") + {STRING_32} " is placed at " + text_of (al_k, "place") + {STRING_32} " twice")
							if last_error = Void then
								event_places.extend ([a_file, text_of (al_k, "event"), text_of (al_k, "place")])
							end
						end
						i := i + 1
					end
				end
				if attached l_root.array_item ({STRING_32} "routes") as al_routes then
					from i := 1 until i > al_routes.count or last_error /= Void loop
						if attached al_routes.object_item (i) as al_r then
							read_route (a_file, al_r)
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

	read_place (a_file: STRING_32; a_o: SIMPLE_JSON_OBJECT)
			-- A place and its location claims, checked.
		local
			l_place: BIB_PLACE
			l_id, l_basis: STRING_32
			l_zoom, l_lon, l_lat, l_radius: REAL_64
			i, l_leans: INTEGER
		do
			l_id := text_of (a_o, "id")
			l_zoom := a_o.real_item ({STRING_32} "min_zoom")
			fail_unless (schema.is_timeline_id (l_id), a_file, {STRING_32} "a place id is not lowercase letters and digits: " + l_id)
			fail_unless (not across places as al_seen some al_seen.place.id.same_string (l_id) end, a_file, {STRING_32} "place " + l_id + {STRING_32} " is given twice")
			fail_unless (not text_of (a_o, "name").is_empty, a_file, {STRING_32} "place " + l_id + {STRING_32} " has no name")
			fail_unless (schema.is_place_kind (text_of (a_o, "kind")), a_file, {STRING_32} "place " + l_id + {STRING_32} " has an unknown kind: " + text_of (a_o, "kind"))
			fail_unless (l_zoom >= 1.0, a_file, {STRING_32} "place " + l_id + {STRING_32} " has a min_zoom under 1")
			if last_error = Void then
				create l_place.make (l_id, text_of (a_o, "name"), text_of (a_o, "kind"), l_zoom)
				if attached a_o.array_item ({STRING_32} "claims") as al_claims then
					from i := 1 until i > al_claims.count or last_error /= Void loop
						if attached al_claims.object_item (i) as al_c then
							l_lon := al_c.real_item ({STRING_32} "lon")
							l_lat := al_c.real_item ({STRING_32} "lat")
							l_radius := al_c.real_item ({STRING_32} "radius_m")
							l_basis := text_of (al_c, "basis")
							if l_basis.is_empty then
								l_basis := {STRING_32} "evidence"
							end
							fail_unless (is_number (al_c, "lon") and is_number (al_c, "lat") and l_lon >= -180.0 and l_lon <= 180.0 and l_lat >= -90.0 and l_lat <= 90.0,
								a_file, {STRING_32} "place " + l_id + {STRING_32} " has a location off the planet or missing")
							fail_unless (l_radius >= 0.0, a_file, {STRING_32} "place " + l_id + {STRING_32} " has a negative radius")
							fail_unless (across (<<"evidence", "text", "reckoning", "tradition">>) as b some b.same_string_general (l_basis) end, a_file,
								{STRING_32} "place " + l_id + {STRING_32} " has a claim with an unknown basis: " + l_basis)
							if last_error = Void then
								if al_c.boolean_item ({STRING_32} "lean") then
									l_leans := l_leans + 1
								end
								l_place.add_claim (create {BIB_PLACE_CLAIM}.make (l_lon, l_lat, l_radius, text_of (al_c, "held_by"), l_basis,
									text_of (al_c, "citation"), text_of (al_c, "note"), al_c.boolean_item ({STRING_32} "lean")))
							end
						end
						i := i + 1
					end
				end
				fail_unless (not l_place.claims.is_empty, a_file, {STRING_32} "place " + l_id + {STRING_32} " has no location")
				fail_unless (l_leans <= 1, a_file, {STRING_32} "place " + l_id + {STRING_32} " has more than one lean")
				if last_error = Void then
					places.extend ([a_file, l_place])
				end
			end
		end

	read_route (a_file: STRING_32; a_o: SIMPLE_JSON_OBJECT)
			-- A route, checked: its points kept as text, "lon lat lon lat ...".
		local
			l_id, l_points: STRING_32
			l_edtf: BIB_EDTF
			i: INTEGER
		do
			l_id := text_of (a_o, "id")
			create l_edtf.make (text_of (a_o, "edtf"))
			create l_points.make (64)
			fail_unless (schema.is_timeline_id (l_id), a_file, {STRING_32} "a route id is not lowercase letters and digits: " + l_id)
			fail_unless (not across routes as al_seen some al_seen.id.same_string (l_id) end, a_file, {STRING_32} "route " + l_id + {STRING_32} " is given twice")
			fail_unless (l_edtf.is_valid, a_file, {STRING_32} "route " + l_id + {STRING_32} ": the date %"" + l_edtf.text + {STRING_32} "%" is not one this program reads")
			if attached a_o.array_item ({STRING_32} "points") as al_points then
				fail_unless (al_points.count >= 4 and al_points.count \\ 2 = 0, a_file, {STRING_32} "route " + l_id + {STRING_32} " needs an even list of two points or more")
				from i := 1 until i > al_points.count or last_error /= Void loop
					if i > 1 then
						l_points.append_character (' ')
					end
					l_points.append (al_points.real_item (i).out)
					i := i + 1
				end
			else
				fail_unless (False, a_file, {STRING_32} "route " + l_id + {STRING_32} " has no points")
			end
			if last_error = Void then
				routes.extend ([a_file, l_id, text_of (a_o, "name"), l_points, a_o.boolean_item ({STRING_32} "certain"), text_of (a_o, "alternative_of"), l_edtf, text_of (a_o, "citation")])
			end
		end

	is_number (a_o: SIMPLE_JSON_OBJECT; a_key: STRING_8): BOOLEAN
			-- Does `a_o' hold a number at `a_key'?
		do
			Result := attached a_o.item (a_key.to_string_32) as al_v and then al_v.is_number
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
			across places as pl until last_error /= Void loop
				across pl.place.claims as c until last_error /= Void loop
					fail_unless (c.citation_id.is_empty or else across citations as ct some ct.id.same_string (c.citation_id) end, pl.file,
						{STRING_32} "place " + pl.place.id + {STRING_32} " cites an unknown source: " + c.citation_id)
				end
			end
			across event_places as k until last_error /= Void loop
				fail_unless (across events as ev some ev.event.id.same_string (k.event_id) end, k.file, {STRING_32} "an unknown event is placed: " + k.event_id)
				fail_unless (across places as pl some pl.place.id.same_string (k.place_id) end, k.file, {STRING_32} "event " + k.event_id + {STRING_32} " is placed at an unknown place: " + k.place_id)
			end
			across routes as rt until last_error /= Void loop
				fail_unless (rt.citation.is_empty or else across citations as ct some ct.id.same_string (rt.citation) end, rt.file,
					{STRING_32} "route " + rt.id + {STRING_32} " cites an unknown source: " + rt.citation)
				fail_unless (rt.alternative_of.is_empty or else across routes as al_r some al_r.id.same_string (rt.alternative_of) end, rt.file,
					{STRING_32} "route " + rt.id + {STRING_32} " is an alternative to an unknown route: " + rt.alternative_of)
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
			across places as pl until last_error /= Void loop
				k := 0
				across pl.place.claims as c loop
					k := k + 1
					if k = 1 then
						a_db.execute_with_args ("INSERT INTO timeline_place VALUES (?, ?, ?, ?, 'trusted', ?)",
							<<pl.place.id, pl.place.name, pl.place.kind, pl.place.min_zoom, provenance_of (c.citation_id)>>)
						check_db (a_db, {STRING_32} "Place " + pl.place.id + {STRING_32} " could not be written.")
						place_count := place_count + 1
					end
					a_db.execute_with_args ("INSERT INTO timeline_place_claim VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'trusted', ?)",
						<<pl.place.id, k, c.lon, c.lat, c.radius_m, c.held_by, c.basis, c.is_lean.to_integer, c.citation_id, c.remark, provenance_of (c.citation_id)>>)
					check_db (a_db, {STRING_32} "A location of " + pl.place.id + {STRING_32} " could not be written.")
					place_claim_count := place_claim_count + 1
				end
			end
			across event_places as ep until last_error /= Void loop
				a_db.execute_with_args ("INSERT INTO timeline_event_place VALUES (?, ?, 'author', 1)", <<ep.event_id, ep.place_id>>)
				check_db (a_db, {STRING_32} "Event " + ep.event_id + {STRING_32} " could not be placed.")
				event_place_count := event_place_count + 1
			end
			across routes as rt until last_error /= Void loop
				a_db.execute_with_args ("INSERT INTO timeline_route VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'author', ?)",
					<<rt.id, rt.name, rt.points, rt.is_certain.to_integer, rt.alternative_of, rt.edtf.text, rt.edtf.earliest, rt.edtf.latest, rt.citation, provenance_of (rt.citation)>>)
				check_db (a_db, {STRING_32} "Route " + rt.id + {STRING_32} " could not be written.")
				route_count := route_count + 1
			end
		end

end
