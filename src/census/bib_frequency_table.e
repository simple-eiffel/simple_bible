note
	description: "Corpus frequencies by key text (lemma frequency precompute), used to draw frequency-matched controls."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_FREQUENCY_TABLE

create
	make

feature {NONE} -- Initialization

	make (a_scope_label: READABLE_STRING_GENERAL)
			-- Empty table for the corpus named `a_scope_label'.
		require
			label_not_empty: not a_scope_label.is_empty
		do
			scope_label := a_scope_label.to_string_32
			create frequencies.make (1024)
		ensure
			empty: key_count = 0
		end

feature -- Access

	scope_label: STRING_32

	key_count: INTEGER
		do
			Result := frequencies.count
		end

	frequency (a_key: BIB_KEY): INTEGER_64
			-- Occurrences of `a_key' in the corpus.
		require
			known: has_key (a_key)
		do
			Result := frequencies.item (a_key.text)
		ensure
			model_agrees: Result = frequencies_model [a_key.text]
		end

feature -- Status

	has_key (a_key: BIB_KEY): BOOLEAN
		do
			Result := frequencies.has (a_key.text)
		ensure
			model_agrees: Result = frequencies_model.domain [a_key.text]
		end

	within_band (a_candidate, a_target: BIB_KEY; a_band_percent: INTEGER): BOOLEAN
			-- Is the frequency of `a_candidate' within `a_band_percent' percent of `a_target''s?
		require
			candidate_known: has_key (a_candidate)
			target_known: has_key (a_target)
			band_sane: a_band_percent > 0 and a_band_percent <= 50
		do
			Result := (frequency (a_candidate) - frequency (a_target)).abs * 100 <= frequency (a_target) * a_band_percent
		end

feature {BIB_CENSUS_ENGINE} -- Filling

	put (a_key: BIB_KEY; a_frequency: INTEGER_64)
		require
			new_key: not has_key (a_key)
			non_negative: a_frequency >= 0
		do
			frequencies.put (a_frequency, a_key.text)
		ensure
			added: frequencies_model |=| old frequencies_model.updated (a_key.text, a_frequency)
		end

feature -- Model

	frequencies_model: MML_MAP [STRING_32, INTEGER_64]
		do
			create Result
			across frequencies as f loop
				Result := Result.updated (@f.key, f)
			end
		end

feature {NONE} -- Representation

	frequencies: HASH_TABLE [INTEGER_64, STRING_32]

end
