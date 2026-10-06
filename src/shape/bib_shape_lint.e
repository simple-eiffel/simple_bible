note
	description: "Port of `shape_db.py lint': flags a 100%% FITS result as suspicious and definitions written after the answer."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SHAPE_LINT

feature -- Linting

	flags (a_shape: BIB_SHAPE; a_run: BIB_SHAPE_RUN): ARRAYED_LIST [STRING_32]
			-- Lint findings for `a_shape' and its run.
		require
			same_shape: a_run.slug.same_string (a_shape.slug)
		do
			check implemented_in_phase_4: False then end
		ensure
			all_fits_flagged: (a_run.buckets.total > 0 and then a_run.buckets.count (create {BIB_VERDICT}.make_fits) = a_run.buckets.total)
				implies not Result.is_empty
		end

end
