note
	description: "[
		The River of Time pack (Plan 22 phase 1, 2026-10-30): the EDTF subset
		read to its years (and refused with a reason), a pack built from a
		sidecar, attached and read back with a disputed event's positions
		and its lean, and a sidecar that breaks a rule refused by name.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_TIMELINE

inherit
	TEST_SET_BASE

feature -- EDTF

	test_edtf_reads_the_subset
			-- The 22 cases of spike S5: years, BC years (astronomical), qualifiers, intervals,
			-- open ends, unspecified digits, long years; and seven refusals with their reasons.
		do
			expect ("0030", 30, 30)
			expect ("-1445", -1445, -1445)
			expect ("0000", 0, 0)
			expect ("-0700~", -700, -700)
			expect ("-0586?", -586, -586)
			expect ("-0586%%", -586, -586)
			expect ("-1445/-1259", -1445, -1259)
			expect ("0030/0033", 30, 33)
			expect ("-14XX", -1499, -1400)
			expect ("19XX", 1900, 1999)
			expect ("-1XXX", -1999, -1000)
			expect ("Y-200000", -200000, -200000)
			expect ("Y-200000/Y-190000", -200000, -190000)
			expect ("../0135", {BIB_EDTF}.Open_start, 135)
			expect ("-0063/..", -63, {BIB_EDTF}.Open_end)
				-- days and months (the seed's dates): the year is the unit kept
			expect ("-0596-03-16", -596, -596)
			expect ("0030-04-07", 30, 30)
			expect ("0051-07/0052-06", 51, 52)
			assert_true ("a day named", (create {BIB_EDTF}.make ("-0596-03-16")).has_day)
			refuse ("0030-13", "no such month")
			refuse ("0030-04-32", "no such day")
			refuse ("Y-20000-04", "long or unspecified")
			refuse ("", "empty")
			refuse ("abc", "not a year")
			refuse ("30", "four digits")
			refuse ("-14X5", "a digit after X")
			refuse ("0033/0030", "backward")
			refuse ("Y30", "more than four digits")
			refuse ("-XXXX", "too many X")
			assert_true ("approximate kept", (create {BIB_EDTF}.make ("-0700~")).is_approximate)
			assert_true ("uncertain kept", (create {BIB_EDTF}.make ("-0586?")).is_uncertain)
			assert_integers_equal ("a century's precision", 2, (create {BIB_EDTF}.make ("-14XX")).precision)
		end

feature -- The pack

	test_timeline_pack_builds_attaches_and_reads
			-- A sidecar of two lanes, three events (one disputed, with its lean) and a citation:
			-- built, attached from the pack folder, read back in order with every claim.
		local
			l_builder: BIB_TIMELINE_BUILDER
			l_bible: SIMPLE_BIBLE
			l_ok: BOOLEAN
			l_events: ARRAYED_LIST [BIB_TIMELINE_EVENT]
		do
			prepare
			l_ok := (create {SIMPLE_FILE}.make (Sidecar_file)).write_text_utf_8 (Good_sidecar)
			create l_builder.make
			l_builder.build (<<Sidecar_file>>, Folder_pack_file)
			assert_true ("built: " + (if attached l_builder.last_error as al_e then al_e.to_string_8 else "" end), l_builder.last_error = Void)
			assert_true ("counts", l_builder.lane_count = 2 and l_builder.event_count = 3 and l_builder.claim_count = 4 and l_builder.citation_count = 1)
			l_bible := bible
			l_bible.open
			assert_true ("open with the pack", l_bible.is_open and l_bible.pack_errors.is_empty)
			assert_integers_equal ("one timeline pack", 1, l_bible.timeline_packs.count)
			if attached l_bible.timeline_packs.first as al_pack then
				assert_strings_equal ("titled", "River of Time", al_pack.title)
				assert_integers_equal ("two lanes", 2, al_pack.lanes.count)
				assert_strings_equal ("lanes in their order", "meso", al_pack.lanes.first.id)
				l_events := al_pack.events
				assert_integers_equal ("three events", 3, l_events.count)
				assert_strings_equal ("by the earliest year: Hammurabi first", "hammurabi", l_events.first.id)
				across l_events as ev loop
					if ev.id.same_string ("samaria") then
						assert_true ("the fall of Samaria is disputed", ev.is_disputed and ev.claims.count = 2)
						assert_true ("its second position is the lean", not ev.claims.first.is_lean and ev.claims.last.is_lean)
						assert_strings_equal ("a position names its holder", "Sargon II's annals", ev.claims.last.label)
						assert_integers_equal ("722 BC", -721, ev.claims.first.earliest)
					end
				end
				assert_true ("the citation reads", al_pack.citation_text ("appc").has_substring ("Appendix C"))
			end
			l_bible.close
			cleanup
		end

	test_timeline_builder_refuses_a_broken_sidecar
			-- A date the program cannot read, an unknown lane, two leans and an unknown source
			-- each refuse the build, naming the event and the rule.
		do
			refuses (Good_sidecar.twin, "%"edtf%": %"-0852%"", "%"edtf%": %"853 BC%"", "is not one this program reads")
			refuses (Good_sidecar.twin, "%"lane%": %"levant%"", "%"lane%": %"atlantis%"", "unknown lane")
			refuses (Good_sidecar.twin, "%"lean%": false", "%"lean%": true", "more than one lean")
			refuses (Good_sidecar.twin, "%"citation%": %"appc%", %"held_by%": %"Babylonian", "%"citation%": %"nowhere%", %"held_by%": %"Babylonian", "unknown source")
				-- a citation repeated with the same text in another file is one citation; with another text, refused
			refuses (Good_sidecar.twin, "%"citations%": [{%"id%": %"appc%"", "%"citations%": [{%"id%": %"appc%", %"text%": %"other%"}, {%"id%": %"appc%"", "given twice with different text")
		end

feature {NONE} -- Helpers

	expect (a_text: STRING; a_lo, a_hi: INTEGER)
		local
			e: BIB_EDTF
		do
			create e.make (a_text)
			assert_true (a_text + " is valid", e.is_valid)
			assert_integers_equal (a_text + " earliest", a_lo, e.earliest)
			assert_integers_equal (a_text + " latest", a_hi, e.latest)
		end

	refuse (a_text, a_reason: STRING)
		local
			e: BIB_EDTF
		do
			create e.make (a_text)
			assert_false ("%"" + a_text + "%" refused", e.is_valid)
			assert_true ("%"" + a_text + "%" says why: " + e.error.to_string_8, e.error.has_substring (a_reason))
		end

	refuses (a_sidecar: STRING; a_old, a_new, a_reason: STRING)
			-- The sidecar with `a_old' made `a_new' refuses the build with `a_reason'.
		local
			l_builder: BIB_TIMELINE_BUILDER
			l_ok: BOOLEAN
		do
			prepare
			assert_true ("the change applies: " + a_old, a_sidecar.has_substring (a_old))
			a_sidecar.replace_substring_all (a_old, a_new)
			l_ok := (create {SIMPLE_FILE}.make (Sidecar_file)).write_text_utf_8 (a_sidecar)
			create l_builder.make
			l_builder.build (<<Sidecar_file>>, Folder_pack_file)
			assert_true ("refused for " + a_reason, attached l_builder.last_error as al_e and then al_e.has_substring (a_reason))
			cleanup
		end

	prepare
		local
			l_ok: BOOLEAN
		do
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			if not (create {SIMPLE_FILE}.make (Folder)).is_directory then
				l_ok := (create {SIMPLE_FILE}.make (Folder)).create_directory
			end
			fixture.delete_file (Folder_pack_file)
		end

	cleanup
		local
			l_ok: BOOLEAN
		do
			fixture.delete_file (Folder_pack_file)
			fixture.delete_file (Sidecar_file)
			fixture.delete_file (Content_file)
			l_ok := (create {SIMPLE_FILE}.make (Folder)).delete_directory
		end

	bible: SIMPLE_BIBLE
		local
			l_config: BIB_CONFIG
		do
			create l_config.make_with_core (Content_file)
			l_config := l_config.set_pack_folder (Folder)
			create Result.make (l_config)
		end

	fixture: CONC_FIXTURE
		once
			create Result
		end

	Content_file: STRING = "timeline_test_content.db"
	Folder: STRING = "timeline_test_packs"
	Folder_pack_file: STRING = "timeline_test_packs\timeline.db"
	Sidecar_file: STRING = "timeline_test.timeline.json"

	Good_sidecar: STRING = "[
{"lanes": [{"id": "meso", "title": "Mesopotamia", "group": "Near East", "sort": 1}, {"id": "levant", "title": "Levant and Israel", "group": "Near East", "sort": 2}],
 "citations": [{"id": "appc", "text": "Rix, Larry. A History of Israel in Its Ancient Near Eastern World. Draft, 2026. Appendix C."}],
 "events": [
  {"id": "qarqar", "title": "Battle of Qarqar", "lane": "meso", "kind": "event", "importance": 1, "summary": "Ahab the Israelite in the Kurkh Monolith.",
   "claims": [{"edtf": "-0852", "chronology": "", "held_by": "", "basis": "evidence", "lean": false, "citation": "appc", "note": ""}]},
  {"id": "samaria", "title": "Fall of Samaria", "lane": "levant", "kind": "event", "importance": 1, "summary": "Shalmaneser V or Sargon II.",
   "claims": [{"edtf": "-0721", "chronology": "", "citation": "appc", "held_by": "Babylonian Chronicle", "basis": "evidence", "lean": false, "note": ""},
              {"edtf": "-0719", "chronology": "", "held_by": "Sargon II's annals", "basis": "evidence", "lean": true, "citation": "appc", "note": ""}]},
  {"id": "hammurabi", "title": "Hammurabi of Babylon", "lane": "meso", "kind": "reign", "importance": 1, "summary": "The Code.",
   "claims": [{"edtf": "-1791/-1749", "chronology": "Middle", "held_by": "", "basis": "reckoning", "lean": false, "citation": "appc", "note": ""}]}
 ]}
]"

end
