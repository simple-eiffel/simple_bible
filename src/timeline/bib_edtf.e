note
	description: "[
		A date as the timeline holds it (Plan 22, spike S5, 2026-10-30): the
		EDTF subset a claim is written in, read to the earliest and latest
		astronomical years it allows (EDTF years are astronomical: 0000 is
		1 BC, -0001 is 2 BC).
		  0030        a year (four digits)
		  -1445       a year BC
		  Y-200000    a long year ("Y" when more than four digits)
		  -14XX       unspecified digits at the end: -1499 .. -1400
		  -0596-03-16 a day; 0051-07 a month (the year is the unit kept)
		  -0700~      approximate; -0586? uncertain; -0586% both
		  -1445/-1259 an interval; ../0135 and -0063/.. open ends
		A text that is none of these is refused with its reason.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_EDTF

create
	make

feature {NONE} -- Initialization

	make (a_text: READABLE_STRING_GENERAL)
			-- Read `a_text'.
		local
			l_slash: INTEGER
			l_from, l_to: TUPLE [lo, hi: INTEGER; ok: BOOLEAN]
		do
			create text.make_from_string_general (a_text)
			text.left_adjust
			text.right_adjust
			create error.make_empty
			l_slash := text.index_of ('/', 1)
			if text.is_empty then
				error := {STRING_32} "empty"
			elseif l_slash = 0 then
				l_from := part (text)
				if l_from.ok then
					earliest := l_from.lo
					latest := l_from.hi
				end
			else
				is_interval := True
				if text.substring (1, l_slash - 1).same_string ({STRING_32} "..") then
					earliest := Open_start
					l_to := part (text.substring (l_slash + 1, text.count))
					if l_to.ok then
						latest := l_to.hi
					end
				elseif text.substring (l_slash + 1, text.count).same_string ({STRING_32} "..") then
					latest := Open_end
					l_from := part (text.substring (1, l_slash - 1))
					if l_from.ok then
						earliest := l_from.lo
					end
				else
					l_from := part (text.substring (1, l_slash - 1))
					l_to := part (text.substring (l_slash + 1, text.count))
					if l_from.ok and l_to.ok then
						earliest := l_from.lo
						latest := l_to.hi
						if l_from.lo > l_to.lo then
							error := {STRING_32} "the interval runs backward"
						end
					end
				end
			end
			if not error.is_empty then
				earliest := 0
				latest := 0
			end
		ensure
			ordered: is_valid implies earliest <= latest
			reason_when_invalid: not is_valid implies not error.is_empty
		end

feature -- Access

	text: STRING_32
			-- The date as written, trimmed.

	error: STRING_32
			-- Why `text' is not a date; empty when it is.

	earliest, latest: INTEGER
			-- The astronomical years the date allows.

	is_interval, is_approximate, is_uncertain: BOOLEAN

	has_month, has_day: BOOLEAN
			-- Does a part name its month, its day?

	precision: INTEGER
			-- 0 a year, 1 a decade, 2 a century, 3 a millennium (from trailing X digits).

	is_valid: BOOLEAN
		do
			Result := error.is_empty
		end

	Open_start: INTEGER = -1_000_000
	Open_end: INTEGER = 1_000_000
			-- The years an open end stands for.

feature {NONE} -- Reading

	part (a_part: STRING_32): TUPLE [lo, hi: INTEGER; ok: BOOLEAN]
			-- One year with its qualifier; sets `error' when it is not one.
		local
			s: STRING_32
			l_long, l_negative: BOOLEAN
			i, l_x: INTEGER
			l_lo, l_hi, l_scale, l_base: INTEGER_64
			c: CHARACTER_32
			l_dash, l_month, l_day: INTEGER
			l_md: STRING_32
		do
			s := a_part.twin
			Result := [0, 0, False]
			if not s.is_empty and then (s [s.count] = '?' or s [s.count] = '~' or s [s.count] = '%%') then
				inspect s [s.count]
				when '?' then
					is_uncertain := True
				when '~' then
					is_approximate := True
				else
					is_uncertain := True
					is_approximate := True
				end
				s.remove_tail (1)
			end
			if not s.is_empty and then s [1] = 'Y' then
				l_long := True
				s.remove_head (1)
			end
			if not s.is_empty and then s [1] = '-' then
				l_negative := True
				s.remove_head (1)
			end
				-- a month, or a month and day, after a four-digit year (2026-10-30: the seed's dates)
			l_dash := s.index_of ('-', 1)
			if l_dash > 0 and error.is_empty then
				l_md := s.substring (l_dash + 1, s.count)
				s := s.substring (1, l_dash - 1)
				if l_long or else s.has ('X') then
					error := {STRING_32} "a month or day after a long or unspecified year: %"" + a_part + {STRING_32} "%""
				elseif l_md.count = 2 and then l_md.is_integer then
					l_month := l_md.to_integer
				elseif l_md.count = 5 and then l_md [3] = '-' and then l_md.substring (1, 2).is_integer and then l_md.substring (4, 5).is_integer then
					l_month := l_md.substring (1, 2).to_integer
					l_day := l_md.substring (4, 5).to_integer
				else
					error := {STRING_32} "not a month or a day: %"" + a_part + {STRING_32} "%""
				end
				if error.is_empty and (l_month < 1 or l_month > 12) then
					error := {STRING_32} "no such month: %"" + a_part + {STRING_32} "%""
				elseif error.is_empty and l_day /= 0 and (l_day < 1 or l_day > 31) then
					error := {STRING_32} "no such day: %"" + a_part + {STRING_32} "%""
				end
				if error.is_empty then
					has_month := True
					has_day := has_day or l_day > 0
				end
			end
			if not error.is_empty then
				-- the month or day was refused
			elseif s.is_empty then
				error := {STRING_32} "no year in %"" + a_part + {STRING_32} "%""
			else
				from i := 1 until i > s.count or not error.is_empty loop
					c := s [i]
					if c.is_digit then
						if l_x > 0 then
							error := {STRING_32} "a digit after X in %"" + a_part + {STRING_32} "%""
						end
					elseif c = 'X' then
						l_x := l_x + 1
					else
						error := {STRING_32} "not a year: %"" + a_part + {STRING_32} "%""
					end
					i := i + 1
				end
				if error.is_empty then
					if l_long and s.count <= 4 then
						error := {STRING_32} "Y is for years of more than four digits: %"" + a_part + {STRING_32} "%""
					elseif not l_long and s.count /= 4 then
						error := {STRING_32} "a year has four digits (or Y and more): %"" + a_part + {STRING_32} "%""
					elseif l_x > 3 then
						error := {STRING_32} "too many X digits: %"" + a_part + {STRING_32} "%""
					elseif l_long and l_x > 0 then
						error := {STRING_32} "X digits in a long year: %"" + a_part + {STRING_32} "%""
					end
				end
				if error.is_empty then
					l_scale := 1
					from i := 1 until i > l_x loop
						l_scale := l_scale * 10
						i := i + 1
					end
					l_base := s.substring (1, s.count - l_x).to_integer_64 * l_scale
					if l_negative then
						l_lo := - (l_base + l_scale - 1)
						l_hi := - l_base
					else
						l_lo := l_base
						l_hi := l_base + l_scale - 1
					end
					precision := precision.max (l_x)
					Result := [l_lo.to_integer_32, l_hi.to_integer_32, True]
				end
			end
		end

end
