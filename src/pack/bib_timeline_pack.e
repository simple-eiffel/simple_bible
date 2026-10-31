note
	description: "[
		A River of Time pack, read (BIB_TIMELINE_SCHEMA; Plan 22 phase 1,
		2026-10-30): its lanes in their order and every event with its claims,
		read whole when the timeline opens (spike S5: the widget holds tens of
		thousands of items, so SQL serves lookups, not every frame). The pack
		is attached read-only under `pack_alias' by BIB_PRIVATE_SOURCE, which
		checked its version, voice and provenance columns.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_TIMELINE_PACK

inherit
	BIB_PRIVATE_PACK_READER

create
	make

feature -- Access

	lanes: ARRAYED_LIST [TUPLE [id, title, group: STRING_32; sort: INTEGER]]
			-- Every lane, by its order.
		require
			available: is_available
		do
			create Result.make (8)
			run_query ("SELECT lane_id, title, lane_group, sort FROM " + pack_alias + ".timeline_lane ORDER BY sort, lane_id", {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					Result.extend ([ic.string_value ("lane_id"), ic.string_value ("title"), ic.string_value ("lane_group"), ic.integer_value ("sort")])
				end
			end
		end

	events: ARRAYED_LIST [BIB_TIMELINE_EVENT]
			-- Every event with its claims in order, by the earliest year its first claim allows.
		require
			available: is_available
		local
			l_by_id: HASH_TABLE [BIB_TIMELINE_EVENT, STRING_32]
			l_event: BIB_TIMELINE_EVENT
			l_edtf: BIB_EDTF
		do
			create Result.make (64)
			create l_by_id.make (64)
			run_query ("SELECT e.event_id, e.lane_id, e.title, e.kind, e.importance, e.summary FROM " + pack_alias + ".timeline_event e JOIN "
				+ pack_alias + ".timeline_claim c ON c.event_id = e.event_id AND c.ordinal = 1 ORDER BY c.earliest, e.event_id", {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					create l_event.make (ic.string_value ("event_id"), ic.string_value ("lane_id"), ic.string_value ("title"), ic.string_value ("kind"),
						ic.integer_value ("importance").max (0).min (2), ic.string_value ("summary"))
					Result.extend (l_event)
					l_by_id.put (l_event, l_event.id)
				end
			end
			run_query ("SELECT event_id, edtf, chronology, held_by, basis, is_lean, citation_id, note FROM " + pack_alias + ".timeline_claim ORDER BY event_id, ordinal", {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					create l_edtf.make (ic.string_value ("edtf"))
						-- the schema's CHECK keeps every basis one BIB_CLAIM knows
					if l_edtf.is_valid and then attached l_by_id.item (ic.string_value ("event_id")) as al_event then
						al_event.add_claim (create {BIB_CLAIM}.make (l_edtf, ic.string_value ("chronology"), ic.string_value ("held_by"), ic.string_value ("basis"),
							ic.string_value ("citation_id"), ic.string_value ("note"), ic.integer_value ("is_lean") /= 0))
					end
				end
			end
		ensure
			every_event_claimed: across Result as al_e all not al_e.claims.is_empty end
		end

	places: ARRAYED_LIST [BIB_PLACE]
			-- Every place with its location claims in order, by name (Plan 22 phase 3).
		require
			available: is_available
		local
			l_by_id: HASH_TABLE [BIB_PLACE, STRING_32]
			l_place: BIB_PLACE
		do
			create Result.make (64)
			create l_by_id.make (64)
			run_query ("SELECT place_id, name, kind, min_zoom FROM " + pack_alias + ".timeline_place ORDER BY name, place_id", {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					create l_place.make (ic.string_value ("place_id"), ic.string_value ("name"), ic.string_value ("kind"), ic.real_value ("min_zoom").max (1.0))
					Result.extend (l_place)
					l_by_id.put (l_place, l_place.id)
				end
			end
			run_query ("SELECT place_id, lon, lat, radius_m, held_by, basis, is_lean, citation_id, note FROM " + pack_alias + ".timeline_place_claim ORDER BY place_id, ordinal", {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
						-- the schema's CHECKs keep every point on the planet and every basis known
					if attached l_by_id.item (ic.string_value ("place_id")) as al_place then
						al_place.add_claim (create {BIB_PLACE_CLAIM}.make (ic.real_value ("lon"), ic.real_value ("lat"), ic.real_value ("radius_m"),
							ic.string_value ("held_by"), ic.string_value ("basis"), ic.string_value ("citation_id"), ic.string_value ("note"), ic.integer_value ("is_lean") /= 0))
					end
				end
			end
		end

	event_places: ARRAYED_LIST [TUPLE [event_id, place_id: STRING_32]]
			-- Which places each event happened at.
		require
			available: is_available
		do
			create Result.make (64)
			run_query ("SELECT event_id, place_id FROM " + pack_alias + ".timeline_event_place ORDER BY event_id, place_id", {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					Result.extend ([ic.string_value ("event_id"), ic.string_value ("place_id")])
				end
			end
		end

	routes: ARRAYED_LIST [TUPLE [id, name: STRING_32; points: ARRAY [REAL_64]; is_certain: BOOLEAN; earliest, latest: INTEGER]]
			-- Every route with an even list of points.
		require
			available: is_available
		local
			l_parts: LIST [STRING_32]
			l_points: ARRAY [REAL_64]
			i: INTEGER
		do
			create Result.make (4)
			run_query ("SELECT route_id, name, points, is_certain, earliest, latest FROM " + pack_alias + ".timeline_route ORDER BY route_id", {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					l_parts := ic.string_value ("points").split (' ')
					if l_parts.count >= 4 and l_parts.count \\ 2 = 0 and then across l_parts as p all p.is_double end then
						create l_points.make_filled (0.0, 1, l_parts.count)
						i := 0
						across l_parts as p loop
							i := i + 1
							l_points [i] := p.to_double
						end
						Result.extend ([ic.string_value ("route_id"), ic.string_value ("name"), l_points, ic.integer_value ("is_certain") /= 0,
							ic.integer_value ("earliest"), ic.integer_value ("latest")])
					end
				end
			end
		end

	citation_text (a_id: READABLE_STRING_GENERAL): STRING_32
			-- The text of citation `a_id', or empty.
		require
			available: is_available
		do
			create Result.make_empty
			run_query ("SELECT text FROM " + pack_alias + ".timeline_citation WHERE citation_id = ?", {ARRAY [detachable ANY]} <<a_id.to_string_32>>)
			if attached last_rows as al_rows and then not al_rows.rows.is_empty then
				Result := al_rows.rows.first.string_value ("text")
			end
		end

feature {NONE} -- The heir's part

	query_failed_message: STRING_8 = "A timeline query failed."
	not_open_message: STRING_8 = "The timeline pack is not attached."

	pack_noun: STRING_32
		once
			Result := {STRING_32} "timeline pack"
		end

end
