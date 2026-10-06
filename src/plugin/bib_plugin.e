note
	description: "[
		The private plug-in seam (D-014, A-012): a name, a version, the private
		sources it attaches and the lenses it offers. Larry's private repository
		implements it at compile time and registers it before SIMPLE_BIBLE.open.
		Private CLI commands belong to an app-level extension of this seam in
		simple_bible_app.ecf (the engine library names no CLI type).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_PLUGIN

feature -- Identity

	name: STRING_8
		deferred
		ensure
			not_empty: not Result.is_empty
		end

	version: STRING_8
		deferred
		ensure
			not_empty: not Result.is_empty
		end

feature -- Contributions

	sources: ITERABLE [BIB_PRIVATE_SOURCE]
		deferred
		end

	lenses: ITERABLE [BIB_LENS]
		deferred
		end

feature -- Lifecycle

	on_open (a_bible: SIMPLE_BIBLE)
			-- Attach this plug-in's sources that are present.
		require
			open: a_bible.is_open
		deferred
		end

end
