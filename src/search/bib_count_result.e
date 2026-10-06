note
	description: "A concordance count: the key, the per-book table and the total as a fact, under a stated scope."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_COUNT_RESULT

inherit
	BIB_ENGINE_RESULT

create
	make_success, make_failure

feature {NONE} -- Initialization

	make_success (a_key: BIB_KEY; a_table: BIB_COUNT_TABLE; a_total: BIB_FACT [INTEGER_64]; a_method: BIB_METHOD; a_citations: ITERABLE [BIB_PROVENANCE])
			-- The count of `a_key'; `a_total' carries the provenance of the counted edition.
		require
			total_agrees: a_total.value = a_table.total
			cited: across a_citations as c some True end
		do
			key := a_key
			table := a_table
			total := a_total
			set_success (a_method, a_citations)
		ensure
			success: is_success
		end

	make_failure (a_key: BIB_KEY; a_method: BIB_METHOD; a_error: BIB_ERROR)
		do
			key := a_key
			create table.make
			set_failure (a_method, a_error)
		ensure
			failed: not is_success
		end

feature -- Access

	key: BIB_KEY
	table: BIB_COUNT_TABLE
	total: detachable BIB_FACT [INTEGER_64]
			-- The total as a fact (attached on success).

feature -- Model

	facts_model: MML_SEQUENCE [BIB_SOURCED]
		do
			create Result
			if attached total as t then
				Result := Result & t
			end
		end

invariant
	success_has_total: is_success = (total /= Void)
	total_agrees: attached total as t implies t.value = table.total

end
