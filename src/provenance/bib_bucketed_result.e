note
	description: "[
		FITS, PARTIAL, FAILS and NO_DATA together (FR-026, AC-1a-25). A bucketed
		answer with fewer than four buckets cannot exist: the four lists are
		attached attributes created together. No feature returns one bucket as
		the whole answer; clients reach a bucket only through this object, and
		the count of every bucket is always defined, including zero. Only the
		census and shape engines may fill and seal it.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_BUCKETED_RESULT [G -> BIB_FINDING]

create
	make

feature {NONE} -- Initialization

	make (a_definition_id: INTEGER_64)
			-- Four empty buckets bound to definition (or shape) `a_definition_id'.
		require
			definition_bound: a_definition_id > 0
		do
			definition_id := a_definition_id
			create fits.make (0)
			create partial.make (0)
			create fails.make (0)
			create no_data.make (0)
		ensure
			definition_set: definition_id = a_definition_id
			all_empty: total = 0
			open_for_filling: not is_sealed
		end

feature -- Access

	definition_id: INTEGER_64
			-- Census definition or shape the findings answer.

	count (a_verdict: BIB_VERDICT): INTEGER
			-- Findings in the bucket of `a_verdict' (defined for all four, zero included).
		do
			Result := list_for (a_verdict).count
		ensure
			model_agrees: Result = bucket_model (a_verdict).count
		end

	item (a_verdict: BIB_VERDICT; i: INTEGER): G
			-- The `i'-th finding in the bucket of `a_verdict'.
		require
			in_range: i >= 1 and i <= count (a_verdict)
		do
			Result := list_for (a_verdict) [i]
		end

	total: INTEGER
			-- All findings across the four buckets.
		do
			Result := fits.count + partial.count + fails.count + no_data.count
		end

	near_miss_count: INTEGER
			-- Findings flagged as near-misses, across buckets.
		local
			l_all: like findings_model
			i: INTEGER
		do
			l_all := findings_model
			from
				i := 1
			until
				i > l_all.count
			loop
				if l_all [i].is_near_miss then
					Result := Result + 1
				end
				i := i + 1
			end
		ensure
			bounded: Result >= 0 and Result <= total
		end

	distinct_hub_count: INTEGER
			-- Number of distinct canonical hub ids across all findings (RQ-12).
		local
			l_ids: MML_SET [INTEGER_64]
			l_all: like findings_model
			i: INTEGER
		do
			create l_ids
			l_all := findings_model
			from
				i := 1
			until
				i > l_all.count
			loop
				l_ids := l_ids & l_all [i].hub_id
				i := i + 1
			end
			Result := l_ids.count
		end

feature -- Status

	is_sealed: BOOLEAN
			-- Is filling finished (read-only for clients)?

	all_verdicts: ARRAY [BIB_VERDICT]
			-- The four verdicts in reporting order.
		do
			Result := <<create {BIB_VERDICT}.make_fits, create {BIB_VERDICT}.make_partial,
				create {BIB_VERDICT}.make_fails, create {BIB_VERDICT}.make_no_data>>
		ensure
			four: Result.count = 4
		end

feature -- Model

	bucket_model (a_verdict: BIB_VERDICT): MML_SEQUENCE [G]
			-- Findings of one bucket, in order.
		do
			create Result
			across list_for (a_verdict) as f loop
				Result := Result & f
			end
		end

	findings_model: MML_SEQUENCE [G]
			-- All findings in reporting order: FITS, PARTIAL, FAILS, NO_DATA.
		do
			create Result
			across fits as f loop
				Result := Result & f
			end
			across partial as f loop
				Result := Result & f
			end
			across fails as f loop
				Result := Result & f
			end
			across no_data as f loop
				Result := Result & f
			end
		end

	other_buckets_model (a_verdict: BIB_VERDICT): MML_SEQUENCE [G]
			-- The three buckets other than that of `a_verdict', in reporting order (frame for `extend').
		do
			create Result
			across all_verdicts as v loop
				if not (v ~ a_verdict) then
					Result := Result + bucket_model (v)
				end
			end
		end

feature {BIB_CENSUS_ENGINE, BIB_SHAPE_ENGINE} -- Filling

	extend (a_finding: G)
			-- Add `a_finding' to the bucket of its verdict.
		require
			not_sealed: not is_sealed
		do
			list_for (a_finding.verdict).extend (a_finding)
		ensure
			grown: count (a_finding.verdict) = old count (a_finding.verdict) + 1
			appended: bucket_model (a_finding.verdict) |=| (old bucket_model (a_finding.verdict) & a_finding)
			others_unchanged: other_buckets_model (a_finding.verdict) |=| old other_buckets_model (a_finding.verdict)
			total_grown: total = old total + 1
		end

	seal
			-- Finish filling.
		require
			not_sealed: not is_sealed
		do
			is_sealed := True
		ensure
			sealed: is_sealed
			unchanged: findings_model |=| old findings_model
		end

feature {NONE} -- Representation

	fits, partial, fails, no_data: ARRAYED_LIST [G]
			-- The four buckets.

	list_for (a_verdict: BIB_VERDICT): ARRAYED_LIST [G]
			-- Bucket of `a_verdict'.
		do
			if a_verdict.is_fits then
				Result := fits
			elseif a_verdict.is_partial then
				Result := partial
			elseif a_verdict.is_fails then
				Result := fails
			else
				Result := no_data
			end
		end

invariant
	four_buckets_present: fits /= Void and partial /= Void and fails /= Void and no_data /= Void
	total_consistent: total = fits.count + partial.count + fails.count + no_data.count
	bound_to_definition: definition_id > 0

end
