note
	description: "Stop-word list for English ranking (harvest C-19); never used to drop words from a phrase search."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_STOP_WORDS

create
	make

feature {NONE} -- Initialization

	make (a_words: ITERABLE [READABLE_STRING_GENERAL])
			-- Create the list from `a_words'.
		do
			create words.make (128)
			words.compare_objects
			across a_words as w loop
				if not words.has (w.to_string_32) then
					words.extend (w.to_string_32)
				end
			end
		end

feature -- Status

	has (a_word: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_word' a stop word?
		do
			Result := words.has (a_word.to_string_32)
		ensure
			model_agrees: Result = words_model [a_word.to_string_32]
		end

	count: INTEGER
		do
			Result := words.count
		end

feature -- Model

	words_model: MML_SET [STRING_32]
			-- The stop words.
		do
			create Result
			across words as w loop
				Result := Result & w
			end
		end

feature {NONE} -- Representation

	words: ARRAYED_LIST [STRING_32]

end
