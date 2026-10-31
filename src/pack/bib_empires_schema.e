note
	description: "[
		The empires pack, version 1 (Plan 22 phase 3, 2026-10-31): polity
		outlines by year for the Atlas, imported from Cliopatria (the Seshat
		Global History Databank's polity borders, CC BY 4.0) by
		BIB_EMPIRES_BUILDER and read by BIB_EMPIRES_PACK.

		Kept in a pack of its own because its license is not Larry's: the
		pack credits Seshat (`pack_license'), and Help > About shows it.

		WHAT IT HOLDS: one row per outer ring of a polity's outline in the
		Atlas's region (lon 5 to 65, lat 10 to 50), for polities that began by
		AD 135: the polity's name, the years the outline holds (as Cliopatria
		gives them), its Wikipedia title, the ring's bounds, its point count
		and its points ("lon lat lon lat ...", simplified to 0.02 degrees).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_EMPIRES_SCHEMA

inherit
	BIB_PRIVATE_PACK_SCHEMA
		redefine
			pack_license
		end

feature -- Constants

	Pack_kind: STRING_8 = "empires"
			-- `meta.pack_kind' of an empires pack.

	Pack_file_name: STRING_8 = "empires.db"
			-- The empires pack's file in the packs folder.

	Pack_title: STRING_8 = "Empires by Year"

	Builder_command: STRING_8 = "bible_build --empires"

	Source_name: STRING_8 = "Cliopatria (Seshat Global History Databank)"

	pack_license: BIB_LICENSE
			-- Cliopatria's own license, read in its LICENSE.md: CC BY 4.0, credited to Seshat.
		do
			create Result.make ("CC BY 4.0", False, False, False, Source_name)
		ensure then
			not_restricted: not Result.is_restricted
		end

	West: REAL_64 = 5.0
	East: REAL_64 = 65.0
	South: REAL_64 = 10.0
	North: REAL_64 = 50.0
			-- The Atlas's region: an outline is kept when its bounds touch it.

	Last_year: INTEGER = 135
			-- Polities that began after AD 135 are left out.

	Tolerance: REAL_64 = 0.02
			-- Douglas-Peucker tolerance in degrees (spike S3: the source is already coarse).

	pack_tables: ARRAY [STRING_8]
			-- The pack's own tables.
		once
			Result := <<
				"CREATE TABLE empire_area(area_id INTEGER PRIMARY KEY, name TEXT NOT NULL, year_from INTEGER NOT NULL, year_to INTEGER NOT NULL, wikipedia TEXT NOT NULL, west REAL NOT NULL, east REAL NOT NULL, south REAL NOT NULL, north REAL NOT NULL, points INTEGER NOT NULL CHECK (points >= 3), ring TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE INDEX empire_area_years ON empire_area(year_from, year_to)">>
		end

end
