note
	description: "[
		Which morpheme of a word opens it. MACULA splits a Hebrew word into
		its prefix, the word and its suffix at one position (l + ragli + y,
		"to my foot", Psalm 119:105), and every face that joins them - the
		Interlinear cell, a click in the Parallel tab, the verse's words in
		the lookup list - must open the same headword. The rule, stated once
		(scan 38, 2026-10-27; before it the lookup list opened the suffix's
		"he"): the morpheme with the most letters that has a headword, the
		first of equals. Letters are counted in the search form (Hebrew
		without points, Greek without accents). A mixin.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_WORD_DOOR

feature -- Rule

	takes_door (a_lemma: INTEGER_64; a_letters: INTEGER; a_door: INTEGER_64; a_door_letters: INTEGER): BOOLEAN
			-- Does a morpheme with headword `a_lemma' (0: none) and `a_letters' letters open the word
			-- instead of the door found so far, `a_door' (0: none) with `a_door_letters' letters?
		require
			letters_not_negative: a_letters >= 0 and a_door_letters >= 0
		do
			Result := a_lemma > 0 and (a_door <= 0 or a_letters > a_door_letters)
		ensure
			needs_a_headword: Result implies a_lemma > 0
			first_door_taken: (a_lemma > 0 and a_door <= 0) implies Result
			first_of_equals_kept: (a_door > 0 and a_letters <= a_door_letters) implies not Result
		end

end
