note
	description: "[
		The names a version's own verse numbering goes by in content.db's
		version_info.versification: the Hebrew Bible's, the Septuagint's, the
		Vulgate's, and the English (KJV family, TVTMS's Standard). One owner
		(design scan 53: the strings were written in the builder's SQL, the
		search and the window). BIB_READING_VERSION answers by them.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_NUMBERING

feature -- Constants

	Hebrew: STRING_8 = "hebrew"
	Septuagint: STRING_8 = "lxx"
	Vulgate: STRING_8 = "vulgate"
	English: STRING_8 = "kjv"

end
