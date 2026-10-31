note
	description: "[
		The River of Time pack, version 1 (Plan 22 phase 1, 2026-10-30): the
		timeline's lanes, events and claims, and the citations the claims name.
		The builder (BIB_TIMELINE_BUILDER) writes these tables and the reader
		(BIB_TIMELINE_PACK) reads them; this class is the one place they are
		named.

		THE PACK RULES IT KEEPS (BIB_PRIVATE_SOURCE checks them at attach):
		`user_version' 1; a `meta' table (pack_kind "timeline", title);
		`source_provenance' in the same file; every other table carries a NOT
		NULL `voice' and a NOT NULL `provenance_key'.

		WHAT IT HOLDS: each lane (its title, group and order); each event (its
		lane, title, kind, importance and summary); each event's claims in
		order (the date as written in EDTF, the earliest and latest
		astronomical years it allows, its precision and whether it is
		approximate or uncertain, the chronology, who holds it, its basis,
		whether it is the view shown first, the citation, a note); each
			citation's text; and the passages an event speaks to (phase 2 fills
		`timeline_event_verse'; it is made now so the version stays 1).

		THE ATLAS (phase 3, 2026-10-31; still version 1, the pack never
		shipped): each place (name, kind, the zoom its label shows from) and
		its location as claims in order (a point, the width of the doubt,
		who holds it, its basis, the lean, the citation); which places each
		event happened at; and routes (points, certain or debated, which
		route they are an alternative to, their date as EDTF and years).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_TIMELINE_SCHEMA

inherit
	BIB_PRIVATE_PACK_SCHEMA
		rename
			is_lowercase_id as is_timeline_id
		end

feature -- Constants

	Pack_kind: STRING_8 = "timeline"
			-- `meta.pack_kind' of a timeline pack.

	Pack_file_name: STRING_8 = "timeline.db"
			-- The timeline pack's file in the packs folder.

	Pack_title: STRING_8 = "River of Time"

	Builder_command: STRING_8 = "bible_build --timeline"

	Sidecar_extension: STRING_8 = ".timeline.json"

	Kinds: ARRAY [STRING_8]
			-- What an event is.
		once
			Result := <<"event", "period", "reign", "life", "artifact", "text">>
		end

	is_kind (a_kind: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := across Kinds as k some k.same_string_general (a_kind) end
		end

	Place_kinds: ARRAY [STRING_8]
			-- What a place is.
		once
			Result := <<"city", "site", "region", "mountain", "water", "cave", "battlefield">>
		end

	is_place_kind (a_kind: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := across Place_kinds as k some k.same_string_general (a_kind) end
		end

	pack_tables: ARRAY [STRING_8]
			-- The pack's own tables.
		once
			Result := <<
				"CREATE TABLE timeline_lane(lane_id TEXT PRIMARY KEY, title TEXT NOT NULL, lane_group TEXT NOT NULL, sort INTEGER NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE timeline_event(event_id TEXT PRIMARY KEY, lane_id TEXT NOT NULL REFERENCES timeline_lane(lane_id), title TEXT NOT NULL, kind TEXT NOT NULL, importance INTEGER NOT NULL CHECK (importance BETWEEN 0 AND 2), summary TEXT NOT NULL, status TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE timeline_claim(event_id TEXT NOT NULL REFERENCES timeline_event(event_id), ordinal INTEGER NOT NULL, edtf TEXT NOT NULL, earliest INTEGER NOT NULL, latest INTEGER NOT NULL, precision INTEGER NOT NULL, is_approximate INTEGER NOT NULL, is_uncertain INTEGER NOT NULL, chronology TEXT NOT NULL, held_by TEXT NOT NULL, basis TEXT NOT NULL CHECK (basis IN ('evidence', 'text', 'reckoning', 'tradition')), is_lean INTEGER NOT NULL, citation_id TEXT NOT NULL, note TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (event_id, ordinal))",
				"CREATE INDEX timeline_claim_span ON timeline_claim(earliest, latest)",
				"CREATE TABLE timeline_citation(citation_id TEXT PRIMARY KEY, text TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE timeline_event_verse(event_id TEXT NOT NULL REFERENCES timeline_event(event_id), ordinal INTEGER NOT NULL, start_hub INTEGER NOT NULL, end_hub INTEGER NOT NULL, relation TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (event_id, ordinal))",
				"CREATE TABLE timeline_place(place_id TEXT PRIMARY KEY, name TEXT NOT NULL, kind TEXT NOT NULL, min_zoom REAL NOT NULL CHECK (min_zoom >= 1), voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE timeline_place_claim(place_id TEXT NOT NULL REFERENCES timeline_place(place_id), ordinal INTEGER NOT NULL, lon REAL NOT NULL CHECK (lon BETWEEN -180 AND 180), lat REAL NOT NULL CHECK (lat BETWEEN -90 AND 90), radius_m REAL NOT NULL CHECK (radius_m >= 0), held_by TEXT NOT NULL, basis TEXT NOT NULL CHECK (basis IN ('evidence', 'text', 'reckoning', 'tradition')), is_lean INTEGER NOT NULL, citation_id TEXT NOT NULL, note TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (place_id, ordinal))",
				"CREATE TABLE timeline_event_place(event_id TEXT NOT NULL REFERENCES timeline_event(event_id), place_id TEXT NOT NULL REFERENCES timeline_place(place_id), voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (event_id, place_id))",
				"CREATE TABLE timeline_route(route_id TEXT PRIMARY KEY, name TEXT NOT NULL, points TEXT NOT NULL, is_certain INTEGER NOT NULL, alternative_of TEXT NOT NULL, edtf TEXT NOT NULL, earliest INTEGER NOT NULL, latest INTEGER NOT NULL, citation_id TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))">>
		end

end
