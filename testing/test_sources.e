note
	description: "[
		The sources an ingest kit is made from (2026-10-30, Larry: kits from Word,
		LibreOffice, EPUB, HTML and PDF files): BIB_MARKUP_TEXT turns each kind's
		markup into Markdown; BIB_SOURCE_READER opens each kind of file, built
		here with simple_archive as a real one would be.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_SOURCES

inherit
	TEST_SET_BASE

feature -- Markup

	test_html_becomes_markdown
			-- Headings, paragraphs and items; script, style and the head dropped; references decoded.
		local
			l_text: STRING_32
		do
			l_text := (create {BIB_MARKUP_TEXT}.make_html).text_of ("<html><head><title>T</title><style>p {}</style></head><body>"
				+ "<h1>Sermon</h1><p>God stands in the council<br>(Psalm 82:1; 89:5-7).</p><ul><li><p>One</p></li><li>Two &amp; three</li></ul>"
				+ "<script>var x = 1;</script><!-- a note --><p>A&nbsp;b &#8212; c &#x2014; d</p></body></html>")
			assert_strings_equal ("as Markdown", {STRING_32} "# Sermon%N%NGod stands in the council%N%N(Psalm 82:1; 89:5-7).%N%N- One%N%N- Two & three%N%NA b %/0x2014/ c %/0x2014/ d%N", l_text)
		end

	test_word_xml_becomes_markdown
			-- A Word paragraph's style makes a heading or an item; only text runs count, not deleted text.
		local
			l_text: STRING_32
		do
			l_text := (create {BIB_MARKUP_TEXT}.make_docx).text_of ("<w:document><w:body><w:p><w:pPr><w:pStyle w:val=%"Heading2%"/></w:pPr><w:r><w:t>Part</w:t></w:r></w:p>"
				+ "<w:p><w:r><w:t xml:space=%"preserve%">Jude 5 </w:t></w:r><w:r><w:t>here.</w:t></w:r><w:del><w:r><w:delText>gone</w:delText></w:r></w:del></w:p>"
				+ "<w:p><w:pPr><w:numPr><w:ilvl w:val=%"0%"/></w:numPr></w:pPr><w:r><w:t>Item</w:t></w:r></w:p></w:body></w:document>")
			assert_strings_equal ("as Markdown", {STRING_32} "## Part%N%NJude 5 here.%N%N- Item%N", l_text)
		end

	test_libreoffice_xml_becomes_markdown
			-- A heading's outline level, counted spaces, list items; a footnote passed over.
		local
			l_text: STRING_32
		do
			l_text := (create {BIB_MARKUP_TEXT}.make_odt).text_of ("<office:document-content><office:body><office:text>"
				+ "<text:h text:outline-level=%"2%">Title</text:h><text:p>One<text:s text:c=%"2%"/>two<text:note><text:note-body><text:p>a footnote</text:p></text:note-body></text:note>.</text:p>"
				+ "<text:list><text:list-item><text:p>Item</text:p></text:list-item></text:list></office:text></office:body></office:document-content>")
			assert_strings_equal ("as Markdown", {STRING_32} "## Title%N%NOne  two.%N%N- Item%N", l_text)
		end

	test_empty_marks_mark_nothing
			-- Scan 72: an empty heading or item (a heading holding only a picture) marks nothing after it.
		do
			assert_strings_equal ("HTML", {STRING_32} "It was a dark night.%N", (create {BIB_MARKUP_TEXT}.make_html).text_of ("<h2><img src=%"x.png%"/></h2><p>It was a dark night.</p>"))
			assert_strings_equal ("Word", {STRING_32} "Body text.%N", (create {BIB_MARKUP_TEXT}.make_docx).text_of ("<w:body><w:p><w:pPr><w:pStyle w:val=%"Heading1%"/></w:pPr></w:p><w:p><w:r><w:t>Body text.</w:t></w:r></w:p></w:body>"))
			assert_strings_equal ("LibreOffice", {STRING_32} "Body%N", (create {BIB_MARKUP_TEXT}.make_odt).text_of ("<office:text><text:h text:outline-level=%"1%"></text:h><text:p>Body</text:p></office:text>"))
			assert_strings_equal ("an empty item", {STRING_32} "After.%N", (create {BIB_MARKUP_TEXT}.make_html).text_of ("<ul><li></li></ul><p>After.</p>"))
		end

	test_markup_that_is_not_tidy
			-- Scan 72: a head never closed, a "<" in text, a named accent, a byte-order mark.
		do
			assert_strings_equal ("a head never closed", {STRING_32} "Text%N", (create {BIB_MARKUP_TEXT}.make_html).text_of ("<html><head><title>x</title><body><p>Text</p></body></html>"))
			assert_strings_equal ("a < in text", {STRING_32} "a < b and c%N", (create {BIB_MARKUP_TEXT}.make_html).text_of ("<p>a < b and c</p>"))
			assert_strings_equal ("an accent", {STRING_32} "caf%/0xE9/%N", (create {BIB_MARKUP_TEXT}.make_html).text_of ("<p>caf&eacute;</p>"))
		end

	test_pdf_lines_become_paragraphs
			-- Scan 72: a narrow column's short lines stay in their sentence; a heading with no blank line
			-- around it stands apart; an ending direction mark leaves a space.
		local
			l_reader: BIB_SOURCE_READER
		do
			create l_reader
			assert_strings_equal ("a narrow column", {STRING_32} "Paul wrote that he said that Jesus would come again to judge the living and the dead.",
				l_reader.prose_from_pdf ("Paul wrote that he said that%NJesus would come again to%Njudge the living and the%Ndead."))
			assert_strings_equal ("a heading between paragraphs", {STRING_32} "In the beginning God created the heavens and the earth, and it was very good.%N%NSecond part%N%NCompare these two passages closely with the first one before.",
				l_reader.prose_from_pdf ("In the beginning God created the heavens and the earth, and it%Nwas very good.%NSecond part%NCompare these two passages closely with the first one%Nbefore."))
			assert_strings_equal ("a word hyphenated at a line's end", {STRING_32} "the resurrection of the dead", l_reader.prose_from_pdf ("the resur-%Nrection of the dead"))
			assert_strings_equal ("the Hebrew word apart", {STRING_32} "The word is %/0x5D0/%/0x5DC/%/0x5D4/%/0x5D9/%/0x5DD/ elohim.",
				l_reader.prose_from_pdf ({STRING_32} "The word is %/0x202B/%/0x5D0/%/0x5DC/%/0x5D4/%/0x5D9/%/0x5DD/%/0x202C/elohim."))
		end

	test_epub_page_names
			-- Scan 72: a page named "../Text/ch1.xhtml#start" from the package's folder.
		local
			l_reader: BIB_SOURCE_READER
		do
			create l_reader
			assert_strings_equal ("up a folder, part dropped", {STRING_32} "Text/ch1.xhtml", l_reader.archive_path ({STRING_32} "OEBPS/", {STRING_32} "../Text/ch1.xhtml#start"))
			assert_strings_equal ("beside the package", {STRING_32} "OEBPS/ch2.xhtml", l_reader.archive_path ({STRING_32} "OEBPS/", {STRING_32} "./ch2.xhtml"))
		end

feature -- Files

	test_archives_read_as_their_kind
			-- A Word file, a LibreOffice text and an EPUB (its pages in spine order, a page name with a
			-- space written %20), each built as a zip; a Word file at a path beyond ASCII read too.
		local
			l_reader: BIB_SOURCE_READER
			l_ok: BOOLEAN
		do
			make_zip (Docx_file, <<["word/document.xml", "<w:document><w:body><w:p><w:r><w:t>Jude 5 in Word.</w:t></w:r></w:p></w:body></w:document>"]>>)
			make_zip (Odt_file, <<["content.xml", "<office:document-content><office:body><office:text><text:p>Jude 9 in LibreOffice.</text:p></office:text></office:body></office:document-content>"]>>)
			make_zip (Epub_file, <<["META-INF/container.xml", "<container><rootfiles><rootfile full-path=%"OEBPS/content.opf%" media-type=%"application/oebps-package+xml%"/></rootfiles></container>"],
				["OEBPS/content.opf", "<package><manifest><item id=%"b%" href=%"ch2.xhtml%"/><item id=%"a%" href=%"ch%%201.xhtml%"/></manifest><spine><itemref idref=%"a%"/><itemref idref=%"b%"/></spine></package>"],
				["OEBPS/ch 1.xhtml", "<html><body><h1>One</h1><p>First page.</p></body></html>"],
				["OEBPS/ch2.xhtml", "<html><body><p>Second page.</p></body></html>"]>>)
			create l_reader
			assert_true ("Word", attached l_reader.text_of (Docx_file) as al_t and then al_t.same_string ({STRING_32} "Jude 5 in Word.%N"))
			assert_true ("LibreOffice", attached l_reader.text_of (Odt_file) as al_t and then al_t.same_string ({STRING_32} "Jude 9 in LibreOffice.%N"))
			assert_true ("EPUB in reading order", attached l_reader.text_of (Epub_file) as al_t and then al_t.same_string ({STRING_32} "# One%N%NFirst page.%N%NSecond page."))
			l_ok := (create {SIMPLE_FILE}.make (Docx_file)).copy_to (Accented_docx)
			assert_true ("a path beyond ASCII", attached l_reader.text_of (Accented_docx) as al_t and then al_t.has_substring ("Jude 5 in Word."))
			l_ok := (create {SIMPLE_FILE}.make (Not_an_archive)).write_text_utf_8 ("plain text, not a zip")
			assert_true ("not an archive: refused with why", l_reader.text_of (Not_an_archive) = Void and then attached l_reader.last_error as al_e and then al_e.has_substring ("archive"))
			across <<Docx_file, Odt_file, Epub_file, Not_an_archive>> as ic loop
				l_ok := (create {SIMPLE_FILE}.make (ic)).delete
			end
			l_ok := (create {SIMPLE_FILE}.make (Accented_docx)).delete
		end

	test_pdf_reads_as_prose
			-- A PDF in reading order (pdftotext through simple_pdf): spaces kept, the Hebrew word whole,
			-- its direction marks dropped, no page breaks. Runs where SIMPLE_BIBLE_PDF names pdftotext's folder.
		local
			l_reader: BIB_SOURCE_READER
		do
			create l_reader
			if attached l_reader.text_of (Sample_pdf) as al_text then
				assert_true ("spaces kept", al_text.has_substring ("(Psalm 82:1; 89:5-7)"))
				assert_true ("the Hebrew word whole", al_text.has_substring ({STRING_32} "%/0x5D0/%/0x5DC/%/0x5D4/%/0x5D9/%/0x5DD/"))
				assert_false ("no direction marks", al_text.has ('%/0x202B/') or al_text.has ('%/0x202C/'))
				assert_false ("no page breaks", al_text.has ('%F'))
				assert_true ("the next heading its own paragraph", al_text.has_substring ("%N%NSecond part%N%N"))
			else
				assert_true ({STRING_32} "the sample PDF read: " + (if attached l_reader.last_error as al_e then al_e else {STRING_32} "" end), False)
			end
				-- A PDF with no text (scanned pages; here a blank page) is refused with why, not a crash
				-- (2026-10-30: a real scanned PDF stopped the window, a precondition in simple_pdf).
			assert_true ("no text: refused", l_reader.text_of (Blank_pdf) = Void)
			assert_true ("saying a scan needs OCR", attached l_reader.last_error as al_e and then al_e.has_substring ("OCR"))
		end

	is_pdf_runnable: BOOLEAN
			-- Can `test_pdf_reads_as_prose' run here?
		do
			Result := (create {BIB_SOURCE_READER}).is_pdf_readable
		end

feature {NONE} -- Fixture

	make_zip (a_path: STRING; a_entries: ARRAY [TUPLE [name, content: STRING]])
			-- A zip archive at `a_path' holding `a_entries'.
		local
			l_zip: SIMPLE_ZIP
		do
			create l_zip.make
			l_zip.begin_create (a_path)
			across a_entries as ic loop
				l_zip.add_entry_from_string (ic.name, ic.content)
			end
			l_zip.end_create
		end

	Docx_file: STRING = "sources_test.docx"
	Odt_file: STRING = "sources_test.odt"
	Epub_file: STRING = "sources_test.epub"
	Not_an_archive: STRING = "sources_test_fake.docx"

	Accented_docx: STRING_32
			-- A Word file's name beyond ASCII.
		once
			Result := {STRING_32} "sources_test_pr%/0xE9/face.docx"
		end

	Sample_pdf: STRING = "..\..\..\testing\fixtures\sermon_sample.pdf"
			-- A sermon's two parts with a Hebrew word, made with wkhtmltopdf (from the test folder F_code).

	Blank_pdf: STRING = "..\..\..\testing\fixtures\blank_page.pdf"
			-- A page with no text on it, as a scanned PDF has none.

end
