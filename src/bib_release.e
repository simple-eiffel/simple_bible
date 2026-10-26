note
	description: "[
		The engine's release facts, recorded in every method (BIB_METHOD) so an
		answer can be re-run against the same engine (NFR-006).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_RELEASE

feature -- Constants

	Engine_version: STRING = "0.1.0"
			-- The engine's version; raised with each release.

end
