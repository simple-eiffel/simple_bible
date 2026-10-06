note
	description: "A document in the author library (rix.db). Status and its banner travel with it everywhere (D-019, AC-1a-34)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_AUTHOR_DOC

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_doc_id: INTEGER_64; a_title, a_relpath, a_collection: READABLE_STRING_GENERAL; a_status: BIB_DOC_STATUS; a_banner: READABLE_STRING_GENERAL;
			a_cited_hub_ids: ITERABLE [INTEGER_64]; a_provenance: BIB_PROVENANCE)
		require
			id_positive: a_doc_id > 0
			title_present: not a_title.is_empty
			relpath_present: not a_relpath.is_empty
			banner_for_flagged: a_status.needs_banner implies not a_banner.is_empty
		do
			doc_id := a_doc_id
			title := a_title.to_string_32
			relpath := a_relpath.to_string_32
			collection := a_collection.to_string_32
			status := a_status
			banner_text := a_banner.to_string_32
			create voice.make_author
			provenance := a_provenance
			create cited_hub_ids.make (8)
			across a_cited_hub_ids as h loop
				cited_hub_ids.extend (h)
			end
		ensure
			status_set: status = a_status
		end

feature -- Access

	doc_id: INTEGER_64
	title: STRING_32
	relpath: STRING_32
	collection: STRING_32
	status: BIB_DOC_STATUS
	voice: BIB_VOICE
	banner_text: STRING_32
			-- e.g. "Withdrawn by the author. Kept for the record; not authority."
	provenance: BIB_PROVENANCE

feature -- Status

	cites (a_hub_id: INTEGER_64): BOOLEAN
		do
			Result := cited_hub_ids.has (a_hub_id)
		ensure
			model_agrees: Result = cited_model [a_hub_id]
		end

feature -- Model

	cited_model: MML_SET [INTEGER_64]
			-- Verses this document cites (rix.db `verse_refs').
		do
			create Result
			across cited_hub_ids as h loop
				Result := Result & h
			end
		end

feature {NONE} -- Representation

	cited_hub_ids: ARRAYED_LIST [INTEGER_64]

invariant
	status_valid: status.is_valid
	voice_author: voice.is_author
	title_present: not title.is_empty
	banner_for_flagged: status.needs_banner implies not banner_text.is_empty

end
