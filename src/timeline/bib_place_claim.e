note
	description: "[
		One claim about where a place was (Plan 22 phase 3, 2026-10-31): a
		point, how wide the doubt around it is, who holds it, its basis, whether
		it is the view the program shows first, and its citation. Like BIB_CLAIM
		for dates: no grade; the claim and its holder speak for themselves.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_PLACE_CLAIM

create
	make

feature {NONE} -- Initialization

	make (a_lon, a_lat, a_radius_m: REAL_64; a_held_by, a_basis, a_citation, a_remark: READABLE_STRING_GENERAL; a_lean: BOOLEAN)
		require
			on_the_planet: is_on_the_planet (a_lon, a_lat)
			radius_sane: a_radius_m >= 0.0
			basis_known: is_basis (a_basis)
		do
			lon := a_lon
			lat := a_lat
			radius_m := a_radius_m
			create held_by.make_from_string_general (a_held_by)
			create basis.make_from_string_general (a_basis)
			create citation_id.make_from_string_general (a_citation)
			create remark.make_from_string_general (a_remark)
			is_lean := a_lean
		ensure
			kept: lon = a_lon and lat = a_lat and radius_m = a_radius_m and is_lean = a_lean
		end

feature -- Access

	lon, lat: REAL_64
			-- Where, in degrees.

	radius_m: REAL_64
			-- How wide the doubt around it is, in meters.

	held_by, basis, citation_id, remark: STRING_32
			-- Who holds it ("" when undisputed), its basis, its citation, its note.

	is_lean: BOOLEAN
			-- Is this the location the program shows first?

feature -- Rules

	is_on_the_planet (a_lon, a_lat: REAL_64): BOOLEAN
		do
			Result := a_lon >= -180.0 and a_lon <= 180.0 and a_lat >= -90.0 and a_lat <= 90.0
		end

	is_basis (a_basis: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := across (<<"evidence", "text", "reckoning", "tradition">>) as b some b.same_string_general (a_basis) end
		end

invariant
	on_the_planet: is_on_the_planet (lon, lat)
	radius_sane: radius_m >= 0.0

end
