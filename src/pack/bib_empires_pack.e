note
	description: "[
		An empires pack, read (BIB_EMPIRES_SCHEMA; Plan 22 phase 3, 2026-10-31):
		every polity outline with its years, read whole when the Atlas first
		opens (spike S3: 5,656 outlines in under half a second, then filtered
		by year each frame). Attached read-only under `pack_alias' by
		BIB_PRIVATE_SOURCE.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_EMPIRES_PACK

inherit
	BIB_PRIVATE_PACK_READER

create
	make

feature -- Access

	areas: ARRAYED_LIST [TUPLE [name: STRING_32; ring: ARRAY [REAL_64]; year_from, year_to: INTEGER; wikipedia: STRING_32]]
			-- Every outline whose points read as an even list of three points or more, the largest
			-- polities' first only by the order kept.
		require
			available: is_available
		local
			l_parts: LIST [STRING_32]
			l_ring: ARRAY [REAL_64]
			i: INTEGER
			l_ok: BOOLEAN
		do
			create Result.make (1024)
			run_query ("SELECT name, year_from, year_to, wikipedia, ring FROM " + pack_alias + ".empire_area ORDER BY area_id", {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					l_parts := ic.string_value ("ring").split (' ')
					if l_parts.count >= 6 and l_parts.count \\ 2 = 0 then
						create l_ring.make_filled (0.0, 1, l_parts.count)
						l_ok := True
						i := 0
						across l_parts as p until not l_ok loop
							i := i + 1
							if p.is_double then
								l_ring [i] := p.to_double
							else
								l_ok := False
							end
						end
						if l_ok and ic.integer_value ("year_from") <= ic.integer_value ("year_to") then
							Result.extend ([ic.string_value ("name"), l_ring, ic.integer_value ("year_from"), ic.integer_value ("year_to"), ic.string_value ("wikipedia")])
						end
					end
				end
			end
		ensure
			rings: across Result as al_a all al_a.ring.count >= 6 and al_a.ring.count \\ 2 = 0 and al_a.year_from <= al_a.year_to end
		end

feature {NONE} -- The heir's part

	query_failed_message: STRING_8 = "An empires query failed."
	not_open_message: STRING_8 = "The empires pack is not attached."

	pack_noun: STRING_32
		once
			Result := {STRING_32} "empires pack"
		end

end
