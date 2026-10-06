note
	description: "[
		Versification systems as data (D-010): KJV (English), MT (Hebrew),
		Swete, Rahlfs (CCAT), Vulgate. References are not comparable across
		systems until the versification map pairs them.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_VERSIFICATION_SYSTEM

inherit
	BIB_ENUMERATION

create
	make, make_kjv, make_mt, make_swete, make_rahlfs_ccat, make_vulgate

feature {NONE} -- Initialization

	make (a_code: INTEGER)
			-- Create system `a_code'.
		require
			valid: is_valid_code (a_code)
		do
			code := a_code
		ensure
			code_set: code = a_code
		end

	make_kjv
		do
			code := Kjv
		ensure
			set: code = Kjv
		end

	make_mt
		do
			code := Mt
		ensure
			set: code = Mt
		end

	make_swete
		do
			code := Swete
		ensure
			set: code = Swete
		end

	make_rahlfs_ccat
		do
			code := Rahlfs_ccat
		ensure
			set: code = Rahlfs_ccat
		end

	make_vulgate
		do
			code := Vulgate
		ensure
			set: code = Vulgate
		end

feature -- Access

	label: STRING_32
			-- System name.
		do
			inspect code
			when Kjv then
				Result := {STRING_32} "kjv"
			when Mt then
				Result := {STRING_32} "mt"
			when Swete then
				Result := {STRING_32} "swete"
			when Rahlfs_ccat then
				Result := {STRING_32} "rahlfs_ccat"
			else
				Result := {STRING_32} "vulgate"
			end
		end

feature -- Status

	is_valid_code (a_code: INTEGER): BOOLEAN
			-- Is `a_code' a known system?
		do
			Result := a_code >= Kjv and a_code <= Vulgate
		end

	is_septuagint: BOOLEAN
			-- Is this a Septuagint numbering?
		do
			Result := code = Swete or code = Rahlfs_ccat
		end

feature -- Constants

	Kjv: INTEGER = 1
	Mt: INTEGER = 2
	Swete: INTEGER = 3
	Rahlfs_ccat: INTEGER = 4
	Vulgate: INTEGER = 5

end
