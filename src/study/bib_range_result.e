note
	description: "The range of renderings of one lemma, before any ruling (FR-029, AC-1a-30)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_RANGE_RESULT

inherit
	BIB_ENGINE_RESULT

create
	make_success, make_failure

feature {NONE} -- Initialization

	make_success (a_key: BIB_KEY; a_renderings: ITERABLE [BIB_RENDERING]; a_method: BIB_METHOD; a_citations: ITERABLE [BIB_PROVENANCE])
		require
			cited: across a_citations as c some True end
		do
			key := a_key
			create renderings.make (8)
			across a_renderings as r loop
				renderings.extend (r)
			end
			set_success (a_method, a_citations)
		end

	make_failure (a_key: BIB_KEY; a_method: BIB_METHOD; a_error: BIB_ERROR)
		do
			key := a_key
			create renderings.make (0)
			set_failure (a_method, a_error)
		end

feature -- Access

	key: BIB_KEY

	count: INTEGER
		do
			Result := renderings.count
		end

	has_distinct_glosses: BOOLEAN
			-- Is each (version, gloss) pair listed once?
		local
			l_seen: MML_SET [STRING_32]
		do
			create l_seen
			Result := True
			across renderings as r loop
				if l_seen [r.version_code.to_string_32 + {STRING_32} "|" + r.gloss] then
					Result := False
				end
				l_seen := l_seen & (r.version_code.to_string_32 + {STRING_32} "|" + r.gloss)
			end
		end

feature -- Model

	renderings_model: MML_SEQUENCE [BIB_RENDERING]
		do
			create Result
			across renderings as r loop
				Result := Result & r
			end
		end

	facts_model: MML_SEQUENCE [BIB_SOURCED]
		do
			create Result
			across renderings as r loop
				Result := Result & r
			end
		end

feature {NONE} -- Representation

	renderings: ARRAYED_LIST [BIB_RENDERING]

end
