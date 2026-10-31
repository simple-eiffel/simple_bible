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

	Program_version: STRING = "0.7.43"
			-- The version of the programs a release installs: the window's caption and Help >
			-- About show it, and the installer reads it from bible_gui.rc's version block, which
			-- `test_program_version_is_the_resource_version' holds equal to this (Larry, 2026-10-28:
			-- "so I can tell where I am at in the dev cycle").

end
