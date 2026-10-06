note
	description: "[
		Deterministic frequency-matched controls (FR-112, A-016): keys whose
		corpus frequency lies within a band of the target's, drawn with a stored
		seed, never including the target. The same inputs always give the same
		selection.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CONTROL_SET

create
	make_frequency_matched

feature {NONE} -- Initialization

	make_frequency_matched (a_target: BIB_KEY; a_corpus: BIB_SEARCH_SCOPE; a_band_percent, a_size: INTEGER; a_seed: INTEGER_64; a_frequencies: BIB_FREQUENCY_TABLE)
			-- Draw up to `a_size' controls for `a_target'.
		require
			band_sane: a_band_percent > 0 and a_band_percent <= 50
			size_positive: a_size >= 1
			seed_given: a_seed /= 0
			target_known: a_frequencies.has_key (a_target)
		do
			check implemented_in_phase_4: False then end
		ensure
			deterministic: same_selection_as (create {BIB_CONTROL_SET}.make_frequency_matched (a_target, a_corpus, a_band_percent, a_size, a_seed, a_frequencies))
			target_excluded: not keys_model.has (a_target)
			within_band: across keys as k all a_frequencies.has_key (k) and then a_frequencies.within_band (k, a_target, a_band_percent) end
			at_most_size: count <= a_size
			seed_kept: seed = a_seed
		end

feature -- Access

	seed: INTEGER_64
	band_percent: INTEGER

	count: INTEGER
		do
			Result := keys.count
		ensure
			model_agrees: Result = keys_model.count
		end

	key (i: INTEGER): BIB_KEY
		require
			in_range: i >= 1 and i <= count
		do
			Result := keys [i]
		end

feature -- Comparison

	same_selection_as (other: BIB_CONTROL_SET): BOOLEAN
			-- Same keys in the same order?
		do
			Result := keys_model |=| other.keys_model
		end

feature -- Model

	keys_model: MML_SEQUENCE [BIB_KEY]
		do
			create Result
			across keys as k loop
				Result := Result & k
			end
		end

feature {NONE} -- Representation

	keys: ARRAYED_LIST [BIB_KEY]

invariant
	seed_given: seed /= 0

end
