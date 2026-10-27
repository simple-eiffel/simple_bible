note
	description: "[
		Morphology said in plain English words, for the Interlinear tab and
		the Verse Analysis (P03): "verb, qal qatal, third masculine
		singular", "noun, common, feminine singular absolute", "verb,
		imperfect active indicative, third singular". The pack's tags are
		spelled out (Greek "prep" is "preposition", "det" the article),
		"middlepassive" is "middle or passive", and the source's unknown
		values ("unknown: x") are left out. A mixin: the pack inherits it
		beside its other roles.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_MORPHOLOGY_NAMES

feature -- Morphology

	morphology_text (a_part_of_speech: READABLE_STRING_GENERAL; a_verbal, a_nominal: ARRAY [READABLE_STRING_GENERAL]): STRING_32
			-- The part of speech spelled out, then the verbal features `a_verbal' (stem, form, tense,
			-- voice, mood), then the nominal ones `a_nominal' (person, gender, number, case, state), each
			-- group after a comma; empty and unknown values left out.
		local
			l_group: STRING_32
		do
			Result := part_of_speech_name (a_part_of_speech)
			across <<a_verbal, a_nominal>> as ic_group loop
				l_group := joined_features (ic_group)
				if not l_group.is_empty then
					if not Result.is_empty then
						Result.append ({STRING_32} ", ")
					end
					Result.append (l_group)
				end
			end
		end

	part_of_speech_name (a_tag: READABLE_STRING_GENERAL): STRING_32
			-- `a_tag' spelled out ("prep" is "preposition"); a tag already a word stays as it is.
		do
			if attached Part_of_speech_names.item (a_tag.to_string_32) as al_name then
				Result := al_name.twin
			else
				Result := feature_name (a_tag)
			end
		ensure
			spelled_out: attached Part_of_speech_names.item (a_tag.to_string_32) as al_known implies Result.same_string (al_known)
		end

	feature_name (a_value: READABLE_STRING_GENERAL): STRING_32
			-- `a_value' as said: "middle or passive" for "middlepassive", "masculine or feminine" for the
			-- gender "both"; empty for an unknown value.
		do
			if a_value.to_string_32.starts_with ({STRING_32} "unknown") then
				create Result.make_empty
			elseif a_value.same_string ("middlepassive") then
				Result := {STRING_32} "middle or passive"
			elseif a_value.same_string ("both") then
					-- MACULA's gender of a noun used as either ("eretz", "the earth").
				Result := {STRING_32} "masculine or feminine"
			else
				Result := a_value.to_string_32
			end
		ensure
			unknown_left_out: a_value.to_string_32.starts_with ({STRING_32} "unknown") implies Result.is_empty
		end

	joined_features (a_values: ARRAY [READABLE_STRING_GENERAL]): STRING_32
			-- The named values of `a_values', a space between them.
		local
			l_name: STRING_32
		do
			create Result.make_empty
			across a_values as ic loop
				l_name := feature_name (ic)
				if not l_name.is_empty then
					if not Result.is_empty then
						Result.append_character (' ')
					end
					Result.append (l_name)
				end
			end
		end

	Part_of_speech_names: HASH_TABLE [STRING_32, STRING_32]
			-- The pack's short part-of-speech tags and the words for them.
		once
			create Result.make (10)
			Result.put ({STRING_32} "preposition", {STRING_32} "prep")
			Result.put ({STRING_32} "article", {STRING_32} "det")
			Result.put ({STRING_32} "conjunction", {STRING_32} "conj")
			Result.put ({STRING_32} "pronoun", {STRING_32} "pron")
			Result.put ({STRING_32} "adjective", {STRING_32} "adj")
			Result.put ({STRING_32} "adverb", {STRING_32} "adv")
			Result.put ({STRING_32} "particle", {STRING_32} "ptcl")
			Result.put ({STRING_32} "numeral", {STRING_32} "num")
			Result.put ({STRING_32} "interjection", {STRING_32} "intj")
		end

end
