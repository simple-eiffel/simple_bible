note
	description: "[
		Writes the empires pack (BIB_EMPIRES_SCHEMA) from Cliopatria's GeoJSON
		(Plan 22 phase 3, 2026-10-31; spike S3 measured the import at 38
		seconds for 14,945 features). The file is streamed one feature at a
		time (SIMPLE_JSON_STREAM), so its 186 megabytes never sit in memory.

		Kept: features of type POLITY that began by AD 135, each outer ring
		whose bounds touch the Atlas's region, simplified (Douglas-Peucker at
		0.02 degrees) and still a ring of three points or more. Holes are left
		out: the Atlas fills outlines, and Cliopatria's are outer borders.

		THE CHECKS: the file exists and streams as GeoJSON with "features";
		a stream error refuses the build; a build that keeps no outline is
		refused (a wrong file).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_EMPIRES_BUILDER

inherit
	BIB_PACK_WRITING

create
	make

feature {NONE} -- Initialization

	make
		do
			create schema
		ensure
			nothing_built: area_count = 0
		end

feature -- Access

	schema: BIB_EMPIRES_SCHEMA

	feature_count, polity_count, area_count, raw_points, kept_points: INTEGER
			-- What the last build read and wrote.

feature -- Commands

	build (a_geojson, a_pack: READABLE_STRING_GENERAL)
			-- Write the pack `a_pack' afresh from Cliopatria's GeoJSON `a_geojson'.
		require
			source_named: not a_geojson.is_empty
			pack_named: not a_pack.is_empty
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stream: SIMPLE_JSON_STREAM
			l_from, l_to: INTEGER
			l_ring: ARRAYED_LIST [REAL_64]
			l_box: TUPLE [w, e, s, n: REAL_64]
		do
			last_error := Void
			feature_count := 0
			polity_count := 0
			area_count := 0
			raw_points := 0
			kept_points := 0
			if not (create {SIMPLE_FILE}.make (a_geojson)).is_file then
				last_error := {STRING_32} "No such file: " + a_geojson.to_string_32
			else
				l_db := begin_private_pack (a_pack, schema, schema.Builder_command)
				put_pack_provenance (l_db, 1, schema.Source_name, "Cliopatria polity borders (Zenodo record 13363121)",
					"Outer borders as the source draws them, simplified to 0.02 degrees; years as Cliopatria gives them.", schema.pack_license)
				create l_stream.make_from_file_at (a_geojson.to_string_8, "features")
				across l_stream as ic until last_error /= Void loop
					feature_count := feature_count + 1
					if ic.value.is_object and then attached ic.value.as_object.object_item ({STRING_32} "properties") as al_p
						and then attached ic.value.as_object.object_item ({STRING_32} "geometry") as al_g
					then
						l_from := al_p.integer_item ({STRING_32} "FromYear").to_integer_32
						l_to := al_p.integer_item ({STRING_32} "ToYear").to_integer_32
						if l_from <= schema.Last_year and l_from <= l_to and text_of (al_p, "Type").same_string ({STRING_32} "POLITY") then
							polity_count := polity_count + 1
							across outer_rings (al_g) as r until last_error /= Void loop
								l_box := bounds (r)
								if r.count >= 6 and l_box.e >= schema.West and l_box.w <= schema.East and l_box.n >= schema.South and l_box.s <= schema.North then
									raw_points := raw_points + r.count // 2
									l_ring := simplified (r, schema.Tolerance)
									if l_ring.count >= 6 then
										kept_points := kept_points + l_ring.count // 2
										l_db.execute_with_args ("INSERT INTO empire_area (name, year_from, year_to, wikipedia, west, east, south, north, points, ring, voice, provenance_key) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'trusted', 1)",
											<<text_of (al_p, "Name"), l_from, l_to, text_of (al_p, "Wikipedia"), l_box.w, l_box.e, l_box.s, l_box.n, l_ring.count // 2, flat (l_ring)>>)
										check_db (l_db, {STRING_32} "An outline of " + text_of (al_p, "Name") + {STRING_32} " could not be written.")
										area_count := area_count + 1
									end
								end
							end
						end
					end
				end
				if last_error = Void and l_stream.has_errors then
					last_error := {STRING_32} "The GeoJSON did not stream cleanly (" + l_stream.last_errors.count.out + " errors): " + a_geojson.to_string_32
				elseif last_error = Void and area_count = 0 then
					last_error := {STRING_32} "No polity outline in the Atlas's region was found: is this Cliopatria's GeoJSON? " + a_geojson.to_string_32
				end
				finish_pack (l_db)
			end
		ensure
			something_kept_on_success: last_error = Void implies area_count > 0
		end

feature {NONE} -- Geometry

	outer_rings (a_geometry: SIMPLE_JSON_OBJECT): ARRAYED_LIST [ARRAYED_LIST [REAL_64]]
			-- Each polygon's outer ring as flat lon, lat.
		local
			l_type: STRING_32
			i: INTEGER
		do
			create Result.make (2)
			l_type := text_of (a_geometry, "type")
			if attached a_geometry.array_item ({STRING_32} "coordinates") as al_c then
				if l_type.same_string ({STRING_32} "Polygon") then
					if al_c.count > 0 and then al_c.item (1).is_array then
						Result.extend (ring_of (al_c.item (1).as_array))
					end
				elseif l_type.same_string ({STRING_32} "MultiPolygon") then
					from i := 1 until i > al_c.count loop
						if al_c.item (i).is_array and then al_c.item (i).as_array.count > 0 and then al_c.item (i).as_array.item (1).is_array then
							Result.extend (ring_of (al_c.item (i).as_array.item (1).as_array))
						end
						i := i + 1
					end
				end
			end
		end

	ring_of (a_points: SIMPLE_JSON_ARRAY): ARRAYED_LIST [REAL_64]
		local
			p: SIMPLE_JSON_ARRAY
			i: INTEGER
		do
			create Result.make (a_points.count * 2)
			from i := 1 until i > a_points.count loop
				if a_points.item (i).is_array then
					p := a_points.item (i).as_array
					if p.count >= 2 and then p.item (1).is_number and then p.item (2).is_number then
						Result.extend (p.item (1).as_real)
						Result.extend (p.item (2).as_real)
					end
				end
				i := i + 1
			end
		ensure
			pairs: Result.count \\ 2 = 0
		end

	bounds (a_ring: ARRAYED_LIST [REAL_64]): TUPLE [w, e, s, n: REAL_64]
		local
			i: INTEGER
		do
			Result := [1000.0, -1000.0, 1000.0, -1000.0]
			from i := 1 until i + 1 > a_ring.count loop
				Result.w := Result.w.min (a_ring [i])
				Result.e := Result.e.max (a_ring [i])
				Result.s := Result.s.min (a_ring [i + 1])
				Result.n := Result.n.max (a_ring [i + 1])
				i := i + 2
			end
		end

	simplified (a_ring: ARRAYED_LIST [REAL_64]; a_tolerance: REAL_64): ARRAYED_LIST [REAL_64]
			-- Douglas-Peucker on the flat ring.
		require
			pairs: a_ring.count \\ 2 = 0 and a_ring.count >= 4
		local
			l_keep: ARRAY [BOOLEAN]
			n, i: INTEGER
		do
			n := a_ring.count // 2
			create l_keep.make_filled (False, 1, n)
			l_keep [1] := True
			l_keep [n] := True
			mark (a_ring, 1, n, a_tolerance, l_keep)
			create Result.make (n)
			from i := 1 until i > n loop
				if l_keep [i] then
					Result.extend (a_ring [2 * i - 1])
					Result.extend (a_ring [2 * i])
				end
				i := i + 1
			end
		ensure
			pairs: Result.count \\ 2 = 0
			no_more: Result.count <= a_ring.count
		end

	mark (a_ring: ARRAYED_LIST [REAL_64]; a_first, a_last: INTEGER; a_tolerance: REAL_64; a_keep: ARRAY [BOOLEAN])
			-- Keep the point between `a_first' and `a_last' farthest from their chord when farther
			-- than `a_tolerance', and recurse on both halves.
		local
			i, l_best: INTEGER
			x1, y1, x2, y2, dx, dy, l_len, d, l_max: REAL_64
		do
			if a_last > a_first + 1 then
				x1 := a_ring [2 * a_first - 1]
				y1 := a_ring [2 * a_first]
				x2 := a_ring [2 * a_last - 1]
				y2 := a_ring [2 * a_last]
				dx := x2 - x1
				dy := y2 - y1
				l_len := (dx * dx + dy * dy) ^ 0.5
				from i := a_first + 1 until i >= a_last loop
					if l_len = 0.0 then
						d := ((a_ring [2 * i - 1] - x1) ^ 2 + (a_ring [2 * i] - y1) ^ 2) ^ 0.5
					else
						d := ((dy * a_ring [2 * i - 1] - dx * a_ring [2 * i] + x2 * y1 - y2 * x1).abs) / l_len
					end
					if d > l_max then
						l_max := d
						l_best := i
					end
					i := i + 1
				end
				if l_max > a_tolerance then
					a_keep [l_best] := True
					mark (a_ring, a_first, l_best, a_tolerance, a_keep)
					mark (a_ring, l_best, a_last, a_tolerance, a_keep)
				end
			end
		end

	flat (a_ring: ARRAYED_LIST [REAL_64]): STRING_32
			-- "lon lat lon lat ...", to a thousandth of a degree.
		do
			create Result.make (a_ring.count * 8)
			across a_ring as v loop
				if not Result.is_empty then
					Result.append_character (' ')
				end
				Result.append (((v * 1000.0).rounded / 1000.0).out)
			end
		end

end
