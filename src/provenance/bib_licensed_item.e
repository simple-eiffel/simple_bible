note
	description: "[
		Anything that may be shipped under a license: a key, its license and the
		manifest's ship flag. The build's BIB_PINNED_SOURCE (bible_build.ecf)
		and rix.db documents inherit it, so one gate rule serves the build and
		the engine.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LICENSED_ITEM

create
	make

feature {NONE} -- Initialization

	make (a_key: READABLE_STRING_GENERAL; a_license: BIB_LICENSE; a_ship: BOOLEAN)
			-- Create item `a_key' under `a_license', to be shipped when `a_ship'.
		require
			key_not_empty: not a_key.is_empty
		do
			key := a_key.to_string_32
			license := a_license
			ship := a_ship
		ensure
			key_set: key.same_string_general (a_key)
			license_set: license = a_license
			ship_set: ship = a_ship
		end

feature -- Access

	key: STRING_32
			-- Manifest key, e.g. "SWETE", "RAHLFS-CCAT".

	license: BIB_LICENSE
			-- Its license.

	ship: BOOLEAN
			-- Does the manifest ask to ship it?

invariant
	key_not_empty: not key.is_empty

end
