note
	description: "[
		Writes the chiasm pack (BIB_CHIASM_SCHEMA; research 28, 2026-11-11) from
		one manifest, `chiasm.structures.json', which the vault tools write from
		Bullinger's parsed structures and their grades. Every build starts from
		an empty file; nothing is merged.

		THE CHECKS, before a byte is written: the manifest says it is
		chiasm.structures/1; every structure has a key given once, a parent
		given before it (or none), a book 1 to 66, a range that runs forward, a
		known pattern, source and grade, a title, and two members or more; every
		member has a letter, a range inside its structure's, a known repair, and
		a partner (when it has one) inside the structure that names it back. A
		manifest that breaks one refuses the build, and `last_error' names the
		file and the rule.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CHIASM_BUILDER

inherit
	BIB_PACK_WRITING

create
	make

feature {NONE} -- Initialization

	make
		do
			create schema
			create structures.make (2048)
			create keys.make (2048)
		ensure
			nothing_built: structure_count = 0
		end

feature -- Access

	schema: BIB_CHIASM_SCHEMA
			-- The tables written.

	structure_count, member_count, graded_count: INTEGER
			-- What the last build wrote.

	Bullinger_key: INTEGER = 1
	Measure_key: INTEGER = 2
	Larry_key: INTEGER = 3
	Boys_key: INTEGER = 4
	Jebb_key: INTEGER = 5
	Forbes_key: INTEGER = 6
			-- The provenance rows: one per source, and the grader.

feature -- Commands

	build (a_manifest, a_pack: READABLE_STRING_GENERAL)
			-- Write the pack `a_pack' afresh from the manifest `a_manifest'.
		require
			manifest_named: not a_manifest.is_empty
			pack_named: not a_pack.is_empty
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			last_error := Void
			structure_count := 0
			member_count := 0
			graded_count := 0
			structures.wipe_out
			keys.wipe_out
			read_manifest (a_manifest.to_string_32)
			if last_error = Void then
				l_db := begin_private_pack (a_pack, schema, schema.Builder_command)
				put_pack_provenance (l_db, Bullinger_key, schema.Bullinger_name, "digital edition by C. T. Haywood (2005), parsed from its OCR",
					"Read from a scanned page; a reference or letter may be misread (each repair is marked).", schema.pack_license)
				put_pack_provenance (l_db, Measure_key, "simple_bible chiasm grader", "version 3: pairs by shared rare headwords; the shape laid at 500 random places",
					"Computed from conc.db (WLC Hebrew, WH Greek): scores, not judgments.",
					create {BIB_LICENSE}.make ({BIB_PRIVATE_PACK_SCHEMA}.Author_license, False, False, False, {BIB_PRIVATE_PACK_SCHEMA}.Pack_author))
				put_pack_provenance (l_db, Larry_key, "Larry Rix, his writings (Divine Name Pattern, frameworks, dossiers)", "gathered from the vault",
					"Larry's own structures, settled or draft as each says.", create {BIB_LICENSE}.make ({BIB_PRIVATE_PACK_SCHEMA}.Author_license, False, False, False, {BIB_PRIVATE_PACK_SCHEMA}.Pack_author))
				put_pack_provenance (l_db, Boys_key, "Boys, A Key to the Book of Psalms (1825) and Tactica Sacra (1824)", "parsed from the archive.org OCR",
					"Read from a scanned page.", create {BIB_LICENSE}.make ("public domain", False, False, False, "Thomas Boys"))
				put_pack_provenance (l_db, Jebb_key, "Jebb, Sacred Literature (1820)", "parsed from the archive.org OCR",
					"Read from a scanned page.", create {BIB_LICENSE}.make ("public domain", False, False, False, "John Jebb"))
				put_pack_provenance (l_db, Forbes_key, "Forbes, The Symmetrical Structure of Scripture (1854)", "parsed from the archive.org OCR",
					"Read from a scanned page.", create {BIB_LICENSE}.make ("public domain", False, False, False, "John Forbes"))
				if last_error = Void then
					write_all (l_db)
				end
				finish_pack (l_db)
			end
		ensure
			counted_on_success: last_error = Void implies structure_count = structures.count
		end

feature {NONE} -- Reading and checking

	structures: ARRAYED_LIST [TUPLE [parent: INTEGER; under, title, kind, pattern, source, grade: STRING_32; book, ch_from, v_from, ch_to, v_to, repaired: INTEGER;
			whole, p_shape, p_pairing: detachable REAL_64_REF;
			members: ARRAYED_LIST [TUPLE [letter: STRING_32; inferred: BOOLEAN; ch_from, v_from, ch_to, v_to: INTEGER; label: STRING_32; pair: INTEGER; score: detachable REAL_64_REF; repair: STRING_32]]]]

	keys: HASH_TABLE [INTEGER, STRING_32]
			-- A structure's index in `structures' by its key.

	read_manifest (a_file: STRING_32)
			-- Read and check the manifest `a_file' into `structures'.
		local
			l_json: SIMPLE_JSON
			i: INTEGER
		do
			create l_json
			if attached l_json.parse_file (a_file) as al_value and then al_value.is_object then
				fail_unless (text_of (al_value.as_object, "schema").same_string_general ("chiasm.structures/1"), a_file, "not a chiasm.structures/1 manifest")
				if attached al_value.as_object.array_item ({STRING_32} "structures") as al_list then
					from i := 1 until i > al_list.count or last_error /= Void loop
						if attached al_list.object_item (i) as al_s then
							read_structure (a_file, al_s)
						end
						i := i + 1
					end
				end
				fail_unless (not structures.is_empty, a_file, "the manifest has no structures")
			else
				last_error := {STRING_32} "Not a JSON object: " + a_file
			end
		end

	read_structure (a_file: STRING_32; a_o: SIMPLE_JSON_OBJECT)
			-- One structure and its members, checked.
		local
			l_key, l_parent: STRING_32
			l_from, l_to: TUPLE [ch, v: INTEGER]
			l_members: ARRAYED_LIST [TUPLE [letter: STRING_32; inferred: BOOLEAN; ch_from, v_from, ch_to, v_to: INTEGER; label: STRING_32; pair: INTEGER; score: detachable REAL_64_REF; repair: STRING_32]]
			l_parent_index, l_book, i: INTEGER
			l_m_from, l_m_to: TUPLE [ch, v: INTEGER]
		do
			l_key := text_of (a_o, "key")
			l_parent := text_of (a_o, "parent_key")
			l_book := number_of (a_o, "book_id").truncated_to_integer
			l_from := place_of (a_o, "from")
			l_to := place_of (a_o, "to")
			fail_unless (not l_key.is_empty and not keys.has (l_key), a_file, {STRING_32} "structure " + l_key + {STRING_32} " has no key or is given twice")
			if not l_parent.is_empty then
				keys.search (l_parent)
				fail_unless (keys.found, a_file, {STRING_32} "structure " + l_key + {STRING_32} " names a parent not given before it: " + l_parent)
				if keys.found then
					l_parent_index := keys.found_item
				end
			end
			fail_unless (l_book >= 1 and l_book <= 66, a_file, {STRING_32} "structure " + l_key + {STRING_32} " is not in a book 1 to 66")
			fail_unless (l_from.ch >= 1 and l_from.v >= 1 and ordinal (l_from) <= ordinal (l_to), a_file, {STRING_32} "structure " + l_key + {STRING_32} " has a range that does not run forward")
			fail_unless (schema.is_pattern (text_of (a_o, "pattern")), a_file, {STRING_32} "structure " + l_key + {STRING_32} " has an unknown pattern: " + text_of (a_o, "pattern"))
			fail_unless (schema.is_source (text_of (a_o, "source")), a_file, {STRING_32} "structure " + l_key + {STRING_32} " has an unknown source: " + text_of (a_o, "source"))
			fail_unless (schema.is_grade (text_of (a_o, "grade")), a_file, {STRING_32} "structure " + l_key + {STRING_32} " has an unknown grade: " + text_of (a_o, "grade"))
			fail_unless (not text_of (a_o, "title").is_empty, a_file, {STRING_32} "structure " + l_key + {STRING_32} " has no title")
			create l_members.make (8)
			if attached a_o.array_item ({STRING_32} "members") as al_list then
				from i := 1 until i > al_list.count or last_error /= Void loop
					if attached al_list.object_item (i) as al_m then
						l_m_from := place_of (al_m, "from")
						l_m_to := place_of (al_m, "to")
						fail_unless (not text_of (al_m, "letter").is_empty, a_file, {STRING_32} "structure " + l_key + {STRING_32} " has a member with no letter")
						fail_unless (ordinal (l_from) <= ordinal (l_m_from) and ordinal (l_m_from) <= ordinal (l_m_to) and ordinal (l_m_to) <= ordinal (l_to), a_file,
							{STRING_32} "structure " + l_key + {STRING_32} " has a member outside its range")
						fail_unless (schema.is_repair (text_of (al_m, "repair")), a_file, {STRING_32} "structure " + l_key + {STRING_32} " has a member with an unknown repair: " + text_of (al_m, "repair"))
						l_members.extend ([text_of (al_m, "letter"), (attached al_m.item ({STRING_32} "letter_inferred") as al_b and then al_b.is_boolean and then al_b.as_boolean),
							l_m_from.ch, l_m_from.v, l_m_to.ch, l_m_to.v, text_of (al_m, "label"), number_of (al_m, "pair_seq").truncated_to_integer.max (0),
							optional_number (al_m, "pair_score"), text_of (al_m, "repair")])
					end
					i := i + 1
				end
			end
			fail_unless (l_members.count >= 2, a_file, {STRING_32} "structure " + l_key + {STRING_32} " has fewer than two members")
			across l_members as ic until last_error /= Void loop
				fail_unless (ic.pair = 0 or else (ic.pair <= l_members.count and then l_members [ic.pair].pair = @ic.cursor_index), a_file,
					{STRING_32} "structure " + l_key + {STRING_32} " has a member whose partner does not name it back")
			end
			if last_error = Void then
				structures.extend ([l_parent_index, text_of (a_o, "under_letter"), text_of (a_o, "title"), text_of (a_o, "kind_printed"), text_of (a_o, "pattern"),
					text_of (a_o, "source"), text_of (a_o, "grade"), l_book, l_from.ch, l_from.v, l_to.ch, l_to.v, number_of (a_o, "repaired").truncated_to_integer.max (0),
					optional_number (a_o, "whole"), optional_number (a_o, "p_shape"), optional_number (a_o, "p_pairing"), l_members])
				keys.put (structures.count, l_key)
			end
		end

	place_of (a_o: SIMPLE_JSON_OBJECT; a_key: READABLE_STRING_GENERAL): TUPLE [ch, v: INTEGER]
			-- [chapter, verse] under `a_key'; [0, 0] when absent.
		do
			Result := [0, 0]
			if attached a_o.array_item (a_key.to_string_32) as al_a and then al_a.count = 2 then
				Result := [al_a.integer_item (1).to_integer_32, al_a.integer_item (2).to_integer_32]
			end
		end

	ordinal (a_place: TUPLE [ch, v: INTEGER]): INTEGER
			-- `a_place' as one number that orders places within a book.
		do
			Result := a_place.ch * 1000 + a_place.v
		end

	number_of (a_o: SIMPLE_JSON_OBJECT; a_key: READABLE_STRING_GENERAL): REAL_64
			-- The number under `a_key'; -1 when absent or not a number.
		do
			Result := -1
			if attached a_o.item (a_key.to_string_32) as al_v and then al_v.is_number then
				Result := al_v.as_real
			end
		end

	optional_number (a_o: SIMPLE_JSON_OBJECT; a_key: READABLE_STRING_GENERAL): detachable REAL_64_REF
			-- The number under `a_key', Void (NULL) when absent or null.
		do
			if attached a_o.item (a_key.to_string_32) as al_v and then al_v.is_number then
				Result := al_v.as_real
			end
		end

feature {NONE} -- Writing

	write_all (a_db: SIMPLE_SQL_DATABASE)
			-- The structures, then their members.
		local
			l_index: INTEGER
			l_parent: detachable INTEGER_REF
		do
			across structures as ic until last_error /= Void loop
				l_index := @ic.cursor_index
				if ic.parent > 0 then
					l_parent := ic.parent
				else
					l_parent := Void
				end
				a_db.execute_with_args ("INSERT INTO structure VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
					<<l_index, l_parent, ic.under, ic.book, ic.ch_from, ic.v_from, ic.ch_to, ic.v_to, ic.title, ic.kind, ic.pattern, ic.source, ic.grade,
					ic.whole, ic.p_shape, ic.p_pairing, ic.repaired, voice_of_source (ic.source), key_of_source (ic.source)>>)
				check_db (a_db, "A structure could not be written.")
				structure_count := structure_count + 1
				if not ic.grade.same_string_general ("not_graded") then
					graded_count := graded_count + 1
				end
				across ic.members as al_m until last_error /= Void loop
					a_db.execute_with_args ("INSERT INTO member VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
						<<l_index, @al_m.cursor_index, al_m.letter, al_m.inferred.to_integer, al_m.ch_from, al_m.v_from, al_m.ch_to, al_m.v_to, al_m.label,
						pair_part (al_m.pair), al_m.score, al_m.repair, voice_of_source (ic.source), key_of_source (ic.source)>>)
					check_db (a_db, "A member could not be written.")
					member_count := member_count + 1
				end
			end
		end

	key_of_source (a_source: READABLE_STRING_GENERAL): INTEGER
			-- The provenance row of `a_source'.
		do
			if a_source.same_string ("larry") then
				Result := Larry_key
			elseif a_source.same_string ("boys") then
				Result := Boys_key
			elseif a_source.same_string ("jebb") then
				Result := Jebb_key
			elseif a_source.same_string ("forbes") then
				Result := Forbes_key
			elseif a_source.same_string ("measure") then
				Result := Measure_key
			else
				Result := Bullinger_key
			end
		ensure
			a_row: Result >= Bullinger_key and Result <= Forbes_key
		end

	voice_of_source (a_source: READABLE_STRING_GENERAL): STRING_8
			-- Larry's structures speak in the author's voice; every other source's is held loosely
			-- (read from a scan, or a measure's).
		do
			if a_source.same_string ("larry") then
				Result := schema.Voice_author
			else
				Result := schema.Voice_loose
			end
		end

	pair_part (a_pair: INTEGER): detachable INTEGER_REF
			-- `a_pair' for the pair column, Void (NULL) for none.
		do
			if a_pair > 0 then
				Result := a_pair
			end
		end

end
