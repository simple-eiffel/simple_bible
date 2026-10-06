note
	description: "Porter stemmer with an exception table (harvest C-18). Used for optional English stem search only."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_STEMMER

create
	make

feature {NONE} -- Initialization

	make
			-- Create a stemmer with an empty exception table (loaded in Phase 4).
		do
			create exceptions.make (64)
		end

feature -- Stemming

	stem (a_word: READABLE_STRING_GENERAL): STRING_32
			-- Porter stem of lowercase `a_word'.
		require
			word_not_empty: not a_word.is_empty
		do
			check implemented_in_phase_4: False then end
		ensure
			not_empty: not Result.is_empty
			not_longer: Result.count <= a_word.count
			exception_respected: exceptions_model.domain [a_word.to_string_32] implies Result.same_string (exceptions_model [a_word.to_string_32])
		end

feature -- Model

	exceptions_model: MML_MAP [STRING_32, STRING_32]
			-- Word to fixed stem.
		do
			create Result
			across exceptions as e loop
				Result := Result.updated (@e.key, e)
			end
		end

feature {NONE} -- Representation

	exceptions: HASH_TABLE [STRING_32, STRING_32]

end
