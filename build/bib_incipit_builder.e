note
	description: "[
		Writes the incipit pack (BIB_INCIPIT_SCHEMA; research 27, 2026-11-11)
		from one manifest, `incipit.links.json', which the vault tools write:
		"kinds" (the declared tests), "units" (whole source passages, LXX
		numbering), "measure_run" (the measure's version and chance lines) and
		"links". Every build starts from an empty file; nothing is merged.

		THE CHECKS, before a byte is written: the manifest says it is
		incipit.links/1; every kind is one the schema declares, given once, with
		a known mark style and a definition and a way to fail; every unit is
		given once, with a known book class and a title; the chance lines run
		upward; every link names an NT and an LXX verse as "BOOK C:V", a
		declared kind, a known loudness and followed text, a volume of 0 or
		more, an LXX verse inside a unit, at least one witness (each on the
		schema's list and with a provenance row in version 1), and only the
		measure's known features; no NT verse and LXX verse are joined twice. A
		manifest that breaks one refuses the build, and `last_error' names the
		file and the rule.

		Provenance: UBS Parallel Passages (CC BY-SA 4.0), Huehn 1899 (public
		domain; read from a scan), the volume measure (computed, the author's
		own work). A link carries the UBS row when UBS names it, else Huehn's,
		else the measure's.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_INCIPIT_BUILDER

inherit
	BIB_PACK_WRITING

create
	make

feature {NONE} -- Initialization

	make
		do
			create schema
			create kinds.make (8)
			create units.make (512)
			create unit_ids.make (512)
			create links.make (4096)
			create pairs.make (4096)
			run := [{STRING_32} "", {STRING_32} "", {STRING_32} "", {STRING_32} "", {STRING_32} "", {INTEGER_64} 0, 0.0, 0.0, 0.0]
		ensure
			nothing_built: link_count = 0
		end

feature -- Access

	schema: BIB_INCIPIT_SCHEMA
			-- The tables written.

	kind_count, unit_count, link_count, witness_count, feature_count: INTEGER
			-- What the last build wrote.

	Ubs_key: INTEGER = 1
	Huehn_key: INTEGER = 2
	Measure_key: INTEGER = 3
			-- The provenance rows.

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
			kind_count := 0
			unit_count := 0
			link_count := 0
			witness_count := 0
			feature_count := 0
			kinds.wipe_out
			units.wipe_out
			unit_ids.wipe_out
			links.wipe_out
			pairs.wipe_out
			run := [{STRING_32} "", {STRING_32} "", {STRING_32} "", {STRING_32} "", {STRING_32} "", {INTEGER_64} 0, 0.0, 0.0, 0.0]
			read_manifest (a_manifest.to_string_32)
			if last_error = Void then
				l_db := begin_private_pack (a_pack, schema, schema.Builder_command)
				put_pack_provenance (l_db, Ubs_key, schema.Ubs_source_name, "ParallelPassages.xml (2023)",
					"OT quotations in the NT as UBS lists them; word matches marked on the LXX words.", schema.pack_license)
				put_pack_provenance (l_db, Huehn_key, Huehn_name, "Die messianischen Weissagungen, volume 2 (1899), parsed from the scan",
					"Read from a scanned page; a reference may be misread.", create {BIB_LICENSE}.make ("public domain", False, False, False, {STRING_32} "Eugen H%/252/hn"))
				put_pack_provenance (l_db, Measure_key, "simple_bible volume measure", run.measure_version,
					{STRING_32} "Computed from conc.db (" + run.nt_edition + {STRING_32} ", " + run.lxx_edition + {STRING_32} "): scores, not judgments.",
					create {BIB_LICENSE}.make ({BIB_PRIVATE_PACK_SCHEMA}.Author_license, False, False, False, {BIB_PRIVATE_PACK_SCHEMA}.Pack_author))
				if last_error = Void then
					write_all (l_db)
				end
				finish_pack (l_db)
			end
		ensure
			counted_on_success: last_error = Void implies link_count = links.count
		end

feature {NONE} -- Reading and checking

	Huehn_name: STRING_32
		once
			Result := {STRING_32} "H%/252/hn 1899"
		end

	kinds: ARRAYED_LIST [TUPLE [kind, label, definition_formal, could_fail_if, mark_style: STRING_32]]

	units: ARRAYED_LIST [TUPLE [book: STRING_32; ch, v_to: INTEGER; hebrew_ref, english_ref, title, book_class: STRING_32]]

	unit_ids: HASH_TABLE [INTEGER, STRING_32]
			-- A unit's index in `units' by "BOOK CH".

	run: TUPLE [measure_version, run_on, nt_edition, lxx_edition, method: STRING_32; candidates: INTEGER_64; chance_95, chance_99, chance_999: REAL_64]
			-- The measure run.

	links: ARRAYED_LIST [TUPLE [nt_book: STRING_32; nt_ch, nt_v: INTEGER; lxx_book: STRING_32; lxx_ch, lxx_v, unit: INTEGER;
			kind, loudness, follows: STRING_32; volume: REAL_64; en_book, en_ch, en_v: INTEGER;
			witnesses: ARRAYED_LIST [TUPLE [witness, detail: STRING_32]]; features: ARRAYED_LIST [TUPLE [name: STRING_32; value: REAL_64]]]]

	pairs: HASH_TABLE [BOOLEAN, STRING_32]
			-- Every "NT ref|LXX ref" read, to refuse a pair given twice without a quadratic scan.

	read_manifest (a_file: STRING_32)
			-- Read and check the manifest `a_file' into `kinds', `units', `run' and `links'.
		local
			l_json: SIMPLE_JSON
			l_root: SIMPLE_JSON_OBJECT
			i: INTEGER
		do
			create l_json
			if attached l_json.parse_file (a_file) as al_value and then al_value.is_object then
				l_root := al_value.as_object
				fail_unless (text_of (l_root, "schema").same_string_general ("incipit.links/1"), a_file, "not an incipit.links/1 manifest")
				if attached l_root.array_item ({STRING_32} "kinds") as al_kinds then
					from i := 1 until i > al_kinds.count or last_error /= Void loop
						if attached al_kinds.object_item (i) as al_k then
							read_kind (a_file, al_k)
						end
						i := i + 1
					end
				end
				if attached l_root.array_item ({STRING_32} "units") as al_units then
					from i := 1 until i > al_units.count or last_error /= Void loop
						if attached al_units.object_item (i) as al_u then
							read_unit (a_file, al_u)
						end
						i := i + 1
					end
				end
				if attached l_root.object_item ({STRING_32} "measure_run") as al_run then
					read_run (a_file, al_run)
				else
					fail_unless (False, a_file, "the manifest has no measure_run")
				end
				if attached l_root.array_item ({STRING_32} "links") as al_links then
					from i := 1 until i > al_links.count or last_error /= Void loop
						if attached al_links.object_item (i) as al_l then
							read_link (a_file, al_l)
						end
						i := i + 1
					end
				end
				fail_unless (not links.is_empty, a_file, "the manifest has no links")
			else
				last_error := {STRING_32} "Not a JSON object: " + a_file
			end
		end

	read_kind (a_file: STRING_32; a_o: SIMPLE_JSON_OBJECT)
			-- One declared kind, checked.
		local
			l_kind: STRING_32
		do
			l_kind := text_of (a_o, "kind")
			fail_unless (schema.is_kind (l_kind), a_file, {STRING_32} "an undeclared kind: " + l_kind)
			fail_unless (not across kinds as al_seen some al_seen.kind.same_string (l_kind) end, a_file, {STRING_32} "kind " + l_kind + {STRING_32} " is given twice")
			fail_unless (across schema.Mark_styles as al_m some al_m.same_string_general (text_of (a_o, "mark_style")) end, a_file,
				{STRING_32} "kind " + l_kind + {STRING_32} " has an unknown mark style: " + text_of (a_o, "mark_style"))
			fail_unless (not text_of (a_o, "definition_formal").is_empty and not text_of (a_o, "could_fail_if").is_empty, a_file,
				{STRING_32} "kind " + l_kind + {STRING_32} " lacks its definition or its way to fail")
			if last_error = Void then
				kinds.extend ([l_kind, text_of (a_o, "label"), text_of (a_o, "definition_formal"), text_of (a_o, "could_fail_if"), text_of (a_o, "mark_style")])
			end
		end

	read_unit (a_file: STRING_32; a_o: SIMPLE_JSON_OBJECT)
			-- One source unit (a whole LXX chapter in version 1), checked.
		local
			l_key: STRING_32
			l_ch, l_to: INTEGER
		do
			l_ch := number_of (a_o, "lxx_ch").truncated_to_integer
			l_to := number_of (a_o, "lxx_v_to").truncated_to_integer
			l_key := text_of (a_o, "lxx_book") + {STRING_32} " " + l_ch.out.to_string_32
			fail_unless (not text_of (a_o, "lxx_book").is_empty and l_ch >= 1 and l_to >= 1, a_file, {STRING_32} "unit " + l_key + {STRING_32} " lacks its book, chapter or last verse")
			fail_unless (not unit_ids.has (l_key), a_file, {STRING_32} "unit " + l_key + {STRING_32} " is given twice")
			fail_unless (across schema.Book_classes as al_b some al_b.same_string_general (text_of (a_o, "book_class")) end, a_file,
				{STRING_32} "unit " + l_key + {STRING_32} " has an unknown book class: " + text_of (a_o, "book_class"))
			fail_unless (not text_of (a_o, "title").is_empty, a_file, {STRING_32} "unit " + l_key + {STRING_32} " has no title")
			if last_error = Void then
				units.extend ([text_of (a_o, "lxx_book"), l_ch, l_to, text_of (a_o, "hebrew_ref"), text_of (a_o, "english_ref"), text_of (a_o, "title"), text_of (a_o, "book_class")])
				unit_ids.put (units.count, l_key)
			end
		end

	read_run (a_file: STRING_32; a_o: SIMPLE_JSON_OBJECT)
			-- The measure run, checked: named, and its chance lines running upward.
		do
			run := [text_of (a_o, "measure_version"), text_of (a_o, "run_on"), text_of (a_o, "nt_edition"), text_of (a_o, "lxx_edition"), text_of (a_o, "method"),
				number_of (a_o, "candidates").truncated_to_integer_64, number_of (a_o, "chance_95"), number_of (a_o, "chance_99"), number_of (a_o, "chance_999")]
			fail_unless (not run.measure_version.is_empty and not run.run_on.is_empty, a_file, "the measure run lacks its version or date")
			fail_unless (run.chance_95 > 0 and run.chance_95 <= run.chance_99 and run.chance_99 <= run.chance_999, a_file, "the chance lines do not run upward")
		end

	read_link (a_file: STRING_32; a_o: SIMPLE_JSON_OBJECT)
			-- One link, checked against the kinds, units and the schema's lists.
		local
			l_nt, l_lxx: detachable TUPLE [book: STRING_32; ch, v: INTEGER]
			l_pair, l_kind: STRING_32
			l_witnesses: ARRAYED_LIST [TUPLE [witness, detail: STRING_32]]
			l_features: ARRAYED_LIST [TUPLE [name: STRING_32; value: REAL_64]]
			l_unit, i, l_en_book, l_en_ch, l_en_v: INTEGER
		do
			l_nt := verse_of (text_of (a_o, "nt"))
			l_lxx := verse_of (text_of (a_o, "lxx"))
			l_pair := text_of (a_o, "nt") + {STRING_32} "|" + text_of (a_o, "lxx")
			l_kind := text_of (a_o, "kind")
			fail_unless (l_nt /= Void, a_file, {STRING_32} "a link's NT verse is not BOOK C:V: " + text_of (a_o, "nt"))
			fail_unless (l_lxx /= Void, a_file, {STRING_32} "a link's LXX verse is not BOOK C:V: " + text_of (a_o, "lxx"))
			fail_unless (not pairs.has (l_pair), a_file, {STRING_32} "link " + l_pair + {STRING_32} " is given twice")
			fail_unless (across kinds as al_k some al_k.kind.same_string (l_kind) end, a_file, {STRING_32} "link " + l_pair + {STRING_32} " has an undeclared kind: " + l_kind)
			fail_unless (schema.is_loudness (text_of (a_o, "loudness")), a_file, {STRING_32} "link " + l_pair + {STRING_32} " has an unknown loudness: " + text_of (a_o, "loudness"))
			fail_unless (across schema.Followed_texts as al_f some al_f.same_string_general (text_of (a_o, "follows")) end, a_file,
				{STRING_32} "link " + l_pair + {STRING_32} " follows an unknown text: " + text_of (a_o, "follows"))
			fail_unless (number_of (a_o, "volume") >= 0, a_file, {STRING_32} "link " + l_pair + {STRING_32} " has no volume of 0 or more")
			if last_error = Void and then attached l_lxx as al_lxx then
				unit_ids.search (al_lxx.book + {STRING_32} " " + al_lxx.ch.out.to_string_32)
				if unit_ids.found then
					l_unit := unit_ids.found_item
					fail_unless (al_lxx.v <= units [l_unit].v_to, a_file, {STRING_32} "link " + l_pair + {STRING_32} " points past the end of its unit")
				else
					fail_unless (False, a_file, {STRING_32} "link " + l_pair + {STRING_32} " points into no unit")
				end
			end
			if attached a_o.object_item ({STRING_32} "english") as al_en then
				l_en_book := number_of (al_en, "book_id").truncated_to_integer
				l_en_ch := number_of (al_en, "ch").truncated_to_integer
				l_en_v := number_of (al_en, "v").truncated_to_integer
				fail_unless (l_en_book >= 1 and l_en_book <= 66 and l_en_ch >= 1 and l_en_v >= 1, a_file,
					{STRING_32} "link " + l_pair + {STRING_32} " has an English place that is not a book 1 to 66, chapter and verse")
			end
			create l_witnesses.make (2)
			if attached a_o.array_item ({STRING_32} "witnesses") as al_w then
				from i := 1 until i > al_w.count or last_error /= Void loop
					if attached al_w.object_item (i) as al_one then
						fail_unless (key_of_witness (text_of (al_one, "witness")) > 0, a_file,
							{STRING_32} "link " + l_pair + {STRING_32} " names a witness with no provenance in version 1: " + text_of (al_one, "witness"))
						l_witnesses.extend ([text_of (al_one, "witness"), text_of (al_one, "detail")])
					end
					i := i + 1
				end
			end
			fail_unless (not l_witnesses.is_empty, a_file, {STRING_32} "link " + l_pair + {STRING_32} " has no witness")
			create l_features.make (7)
			if attached a_o.object_item ({STRING_32} "features") as al_feats then
				across al_feats.keys as ic until last_error /= Void loop
					fail_unless (across schema.Features as al_f some al_f.same_string_general (ic) end, a_file,
						{STRING_32} "link " + l_pair + {STRING_32} " has an unknown feature: " + ic)
					l_features.extend ([ic, number_of (al_feats, ic)])
				end
			end
			if last_error = Void and then attached l_nt as al_nt and then attached l_lxx as al_lxx then
				links.extend ([al_nt.book, al_nt.ch, al_nt.v, al_lxx.book, al_lxx.ch, al_lxx.v, l_unit, l_kind, text_of (a_o, "loudness"), text_of (a_o, "follows"),
					number_of (a_o, "volume"), l_en_book, l_en_ch, l_en_v, l_witnesses, l_features])
				pairs.put (True, l_pair)
			end
		end

	verse_of (a_ref: STRING_32): detachable TUPLE [book: STRING_32; ch, v: INTEGER]
			-- "BOOK C:V" read, or Void.
		local
			l_space, l_colon: INTEGER
			l_ch, l_v: STRING_32
		do
			l_space := a_ref.index_of (' ', 1)
			l_colon := a_ref.index_of (':', 1)
			if l_space > 1 and l_colon > l_space + 1 and l_colon < a_ref.count then
				l_ch := a_ref.substring (l_space + 1, l_colon - 1)
				l_v := a_ref.substring (l_colon + 1, a_ref.count)
				if l_ch.is_integer and l_v.is_integer and then l_ch.to_integer >= 1 and l_v.to_integer >= 1 then
					Result := [a_ref.substring (1, l_space - 1), l_ch.to_integer, l_v.to_integer]
				end
			end
		ensure
			counted_from_one: attached Result as r implies r.ch >= 1 and r.v >= 1
		end

	key_of_witness (a_witness: READABLE_STRING_GENERAL): INTEGER
			-- The provenance row of `a_witness', or 0 when version 1 has none for it.
		do
			if a_witness.same_string ("ubs") then
				Result := Ubs_key
			elseif a_witness.same_string ("huhn") then
				Result := Huehn_key
			elseif a_witness.same_string ("measure") then
				Result := Measure_key
			end
		end

	english_part (a_number: INTEGER): detachable INTEGER_REF
			-- `a_number' for an English place column, Void (NULL) when the link has none (0).
		do
			if a_number > 0 then
				Result := a_number
			end
		end

	voice_of_key (a_key: INTEGER): STRING_8
			-- The voice of a row from provenance row `a_key': UBS is trusted; a row read from a
			-- scan, or scored by the measure, is held loosely.
		do
			if a_key = Ubs_key then
				Result := schema.Voice_trusted
			else
				Result := schema.Voice_loose
			end
		end

	number_of (a_o: SIMPLE_JSON_OBJECT; a_key: READABLE_STRING_GENERAL): REAL_64
			-- The number under `a_key'; -1 when absent or not a number.
		do
			Result := -1
			if attached a_o.item (a_key.to_string_32) as al_v and then al_v.is_number then
				Result := al_v.as_real
			end
		end

feature {NONE} -- Writing

	write_all (a_db: SIMPLE_SQL_DATABASE)
			-- The kinds, units, measure run, links, witnesses and features, in that order.
		local
			l_key, l_index: INTEGER
			l_run: detachable ANY
		do
			across kinds as ic until last_error /= Void loop
				a_db.execute_with_args ("INSERT INTO link_kind VALUES (?, ?, ?, ?, ?, ?, ?)", <<ic.kind, ic.label, ic.definition_formal, ic.could_fail_if, ic.mark_style, schema.Voice_author, Measure_key>>)
				check_db (a_db, "A kind could not be written.")
				kind_count := kind_count + 1
			end
			across units as ic until last_error /= Void loop
				l_index := @ic.cursor_index
				a_db.execute_with_args ("INSERT INTO source_unit VALUES (?, ?, ?, 1, ?, ?, ?, ?, ?, ?, ?, ?)",
					<<l_index, ic.book, ic.ch, ic.ch, ic.v_to, ic.hebrew_ref, ic.english_ref, ic.title, ic.book_class, Measure_key, schema.Voice_trusted>>)
				check_db (a_db, "A unit could not be written.")
				unit_count := unit_count + 1
			end
			if last_error = Void then
				a_db.execute_with_args ("INSERT INTO measure_run VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
					<<run.measure_version, run.run_on, run.nt_edition, run.lxx_edition, run.candidates, run.chance_95, run.chance_99, run.chance_999, run.method, schema.Voice_loose, Measure_key>>)
				check_db (a_db, "The measure run could not be written.")
			end
			across links as ic until last_error /= Void loop
				l_index := @ic.cursor_index
				l_key := Measure_key
				if ic.features.is_empty then
					l_run := Void
				else
					l_run := 1
						-- the one measure run
				end
				if across ic.witnesses as al_w some al_w.witness.same_string_general ("ubs") end then
					l_key := Ubs_key
				elseif across ic.witnesses as al_w some al_w.witness.same_string_general ("huhn") end then
					l_key := Huehn_key
				end
				a_db.execute_with_args ("INSERT INTO incipit_link VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
					<<l_index, ic.nt_book, ic.nt_ch, ic.nt_v, ic.nt_v, ic.lxx_book, ic.lxx_ch, ic.lxx_v, ic.lxx_v, ic.unit, ic.kind, ic.volume,
					ic.loudness, ic.follows, l_run, english_part (ic.en_book), english_part (ic.en_ch), english_part (ic.en_v), l_key, voice_of_key (l_key)>>)
				check_db (a_db, "A link could not be written.")
				link_count := link_count + 1
				across ic.witnesses as al_w until last_error /= Void loop
					a_db.execute_with_args ("INSERT INTO link_witness VALUES (?, ?, ?, ?, ?)", <<l_index, al_w.witness, al_w.detail, key_of_witness (al_w.witness), voice_of_key (key_of_witness (al_w.witness))>>)
					check_db (a_db, "A witness could not be written.")
					witness_count := witness_count + 1
				end
				across ic.features as al_f until last_error /= Void loop
					a_db.execute_with_args ("INSERT INTO link_feature VALUES (?, ?, ?, ?, ?)", <<l_index, al_f.name, al_f.value, schema.Voice_loose, Measure_key>>)
					check_db (a_db, "A feature could not be written.")
					feature_count := feature_count + 1
				end
			end
		end

end
