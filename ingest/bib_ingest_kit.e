note
	description: "[
		The ingest kit (0.7.32, research/21-INGEST-KIT.md; Larry, 2026-10-29: "a
		'file-open' dialog that then includes the target source file directly in the
		output file with prompt instructions tailored for that ingest file along
		with the link/ref data from the existing Simple Bible and its present
		contents"). One Markdown file an AI chat reads whole: instructions written
		for this source, the prepared-file format with an example, everything
		Simple Bible can link to (the Bible's books and their short forms, the link
		forms, every name of Larry's books, essays, frameworks and notes), then the
		source itself. BIB_NOTE_IMPORTER reads back exactly the format it describes.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_INGEST_KIT

create
	make

feature {NONE} -- Initialization

	make (a_bible: SIMPLE_BIBLE)
			-- A kit writer listing what `a_bible' holds.
		require
			open: a_bible.is_open
		do
			bible := a_bible
		end

feature -- Access

	bible: SIMPLE_BIBLE

	Kit_version: INTEGER = 1
	Format_version: INTEGER = 1
			-- The kit's own version and that of the prepared file it asks for (`sbn').

	Long_source: INTEGER = 20000
			-- Characters past which a source is asked to be divided into chapters.

	kit_text (a_source_name, a_source_text: READABLE_STRING_GENERAL): STRING_32
			-- The kit for the source `a_source_text', read from the file named `a_source_name'.
		require
			named: not a_source_name.is_empty
		local
			l_names: ARRAYED_LIST [TUPLE [kind, name, link: STRING_32]]
		do
			create Result.make (a_source_text.count + 200000)
			Result.append ({STRING_32} "# Simple Bible ingest kit%N%N")
			Result.append ({STRING_32} "kit: " + Kit_version.out.to_string_32 + {STRING_32} "    simple_bible: " + {BIB_RELEASE}.Program_version.to_string_32
				+ {STRING_32} "    made: " + (create {SIMPLE_DATE_TIME}.make_now).to_iso8601_date.to_string_32
				+ {STRING_32} "    source: " + a_source_name.to_string_32 + {STRING_32} " (" + a_source_text.count.out.to_string_32 + {STRING_32} " characters)%N%N")
			Result.append (instructions (a_source_name, a_source_text))
			Result.append (format_section)
			l_names := (create {BIB_NAME_LIST}.make (bible)).names ("")
			Result.append (holdings_section (l_names))
			Result.append ({STRING_32} "## The source%N%N")
			Result.append (fence_for (a_source_text) + {STRING_32} "text%N")
			Result.append (a_source_text.to_string_32)
			if not a_source_text.is_empty and then a_source_text.item (a_source_text.count) /= '%N' then
				Result.append_character ('%N')
			end
			Result.append (fence_for (a_source_text) + {STRING_32} "%N")
		ensure
			holds_the_source: Result.has_substring (a_source_text.to_string_32)
		end

feature {NONE} -- Sections

	instructions (a_source_name, a_source_text: READABLE_STRING_GENERAL): STRING_32
			-- What the AI is asked to do, for this source.
		local
			l_name: STRING_32
		do
			l_name := a_source_name.to_string_32.as_lower
			create Result.make (3000)
			Result.append ({STRING_32} "## Instructions%N%N")
			Result.append ({STRING_32} "You are preparing the source at the end of this file for Simple Bible, a Bible study program. Return ONE file, in the format described under %"The prepared file you return%", and nothing else: no comments before or after it.%N%N")
			Result.append ({STRING_32} "1. Keep the author's words. Tidy layout and obvious typing slips only; do not summarize, shorten, reorder or add opinions. The prepared text should be about as long as the source.%N")
			if l_name.ends_with (".md") then
				Result.append ({STRING_32} "2. The source is Markdown: keep its headings, lists, quotes and emphasis as they are.%N")
			else
				Result.append ({STRING_32} "2. The source is plain text: give it Markdown structure where the text plainly has it (headings, lists, block quotes), and no more.%N")
			end
			if a_source_text.count > Long_source then
				Result.append ({STRING_32} "3. The source is long (" + a_source_text.count.out.to_string_32 + {STRING_32} " characters): divide it into chapters at its own headings or clear breaks, each beginning with a %"# %" title line.%N")
			else
				Result.append ({STRING_32} "3. The source is short: make it one chapter with one %"# %" title line, unless it plainly has parts of its own.%N")
			end
			Result.append ({STRING_32} "4. Write every Bible reference plainly in a standard form (%"Romans 8:28%", %"1 Cor 13:4-7%", %"Psalm 23%"), using the book names and short forms listed below. Simple Bible links them itself; do not make Bible links yourself.%N")
			Result.append ({STRING_32} "5. Where the text alludes to a passage without citing it, add a suggestion on a line of its own right after that paragraph: {{suggest: Galatians 5:1 | why, in a few words}}. Suggest only what the text really alludes to.%N")
			Result.append ({STRING_32} "6. Where the text names one of the author's books, essays, frameworks or notes listed below, you may link it with exactly the link given there: [the KACC lens](framework:kacc). Link to nothing else. Ordinary web links already in the source may stay.%N")
			Result.append ({STRING_32} "7. Fill in the header honestly; leave a field empty rather than guess.%N%N")
		end

	format_section: STRING_32
			-- The prepared file's format, with an example.
		do
			create Result.make (2000)
			Result.append ({STRING_32} "## The prepared file you return%N%N")
			Result.append ({STRING_32} "A header between two lines of three hyphens, then the text as Markdown. The header's fields:%N%N")
			Result.append ({STRING_32} "- sbn: " + Format_version.out.to_string_32 + {STRING_32} " (always)%N")
			Result.append ({STRING_32} "- id: a short name for this material, lowercase letters and digits only (romans8sermon)%N")
			Result.append ({STRING_32} "- title, author, date (YYYY-MM-DD if known), source (the source file's name)%N")
			Result.append ({STRING_32} "- status: draft, manuscript or published%N%N")
			Result.append ({STRING_32} "````markdown%N---%Nsbn: 1%Nid: romans8sermon%Ntitle: Sermon notes on Romans 8%Nauthor: Larry Rix%Ndate: 2026-10-12%Nsource: Sermon notes on Romans 8.txt%Nstatus: draft%N---%N# No Condemnation%N%N")
			Result.append ({STRING_32} "Paul opens Romans 8:1 with the verdict the whole letter has argued for.%N%N{{suggest: Galatians 5:1 | the same freedom from the law}}%N%N")
			Result.append ({STRING_32} "The [KACC lens](framework:kacc) asks who rules here.%N````%N%N")
		end

	holdings_section (a_names: ARRAYED_LIST [TUPLE [kind, name, link: STRING_32]]): STRING_32
			-- The Bible's books and their forms, the link forms, and every name with its link.
		local
			l_abbreviations: BIB_BOOK_ABBREVIATIONS
			i: INTEGER
		do
			create l_abbreviations
			create Result.make (a_names.count * 60 + 8000)
			Result.append ({STRING_32} "## What Simple Bible holds (link only to these)%N%N")
			Result.append ({STRING_32} "### Bible books and the forms a reference may use%N%N")
			from i := 1 until i > 66 loop
				if bible.books.has_book (i) then
					Result.append ({STRING_32} "- " + bible.books.book (i).name + {STRING_32} " (" + bible.books.book (i).code)
					across l_abbreviations.forms_of (i) as ic loop
						Result.append ({STRING_32} ", " + ic)
					end
					Result.append ({STRING_32} ")%N")
				end
				i := i + 1
			end
			Result.append ({STRING_32} "%N### Link forms%N%N")
			Result.append ({STRING_32} "- book:<id> a book, book:<id>/<chapter> one chapter%N- essay:<series> an essay series, essay:<series>/<n> one essay%N")
			Result.append ({STRING_32} "- framework:<id> a framework%N- note:<id> a note brought in earlier, note:<id>/<chapter> one chapter of it%N")
			Result.append ({STRING_32} "- Bible references: write them plainly (rule 4); Simple Bible links them.%N%N")
			Result.append ({STRING_32} "### Names and their links (kind, name, link; " + a_names.count.out.to_string_32 + {STRING_32} " in all)%N%N")
			across a_names as ic loop
				Result.append (ic.kind + {STRING_32} " | " + ic.name + {STRING_32} " | " + ic.link + {STRING_32} "%N")
			end
			Result.append ({STRING_32} "%N")
		end

	fence_for (a_text: READABLE_STRING_GENERAL): STRING_32
			-- A code fence longer than any run of backticks in `a_text'.
		local
			l_run, l_longest: INTEGER
		do
			across a_text.to_string_32 as ic loop
				if ic = '`' then
					l_run := l_run + 1
					l_longest := l_longest.max (l_run)
				else
					l_run := 0
				end
			end
			create Result.make_filled ('`', (l_longest + 1).max (3))
		ensure
			long_enough: Result.count >= 3
		end

end
