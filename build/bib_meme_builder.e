note
	description: "[
		Writes meme.db (BIB_MEME_SCHEMA) from the seed beside Larry's memes
		(research/25, 2026-11-01): `memes.seed.json', one entry a meme with its
		words, credit, license, pictures (paths relative to the seed) and
		passages as written ("1 Corinthians 2:10-16"). Each passage is read with
		BIB_PASSAGE_TEXT, as the meme tool's Add meme reads one; a whole
		chapter ("Psalm 23") spans the chapter.

		THE CHECKS: the seed exists and parses with a "memes" array; a picture
		that is missing or no PNG, and a passage that does not read, are
		warnings (`warnings') and are left out; a meme with no picture is left
		out; a build that keeps no meme is refused.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_MEME_BUILDER

inherit
	BIB_PACK_WRITING

create
	make

feature {NONE} -- Initialization

	make (a_books: BIB_BOOK_CATALOG)
			-- A builder reading passages with the book names of `a_books'.
		do
			create schema
			create passages.make (a_books)
			create warnings.make (0)
		ensure
			nothing_built: meme_count = 0
		end

feature -- Access

	schema: BIB_MEME_SCHEMA

	warnings: ARRAYED_LIST [STRING_32]
			-- What the last build left out, and why.

	meme_count, picture_count, passage_count: INTEGER
			-- What the last build wrote.

feature -- Commands

	build (a_seed, a_pack: READABLE_STRING_GENERAL)
			-- Write `a_pack' afresh from the seed `a_seed'.
		require
			seed_named: not a_seed.is_empty
			pack_named: not a_pack.is_empty
		local
			l_db: SIMPLE_SQL_DATABASE
			l_json: SIMPLE_JSON
			l_folder: STRING_32
			l_now: STRING_8
			i: INTEGER
		do
			last_error := Void
			warnings.wipe_out
			meme_count := 0
			picture_count := 0
			passage_count := 0
			create l_json
			if not (create {SIMPLE_FILE}.make (a_seed)).is_file then
				last_error := {STRING_32} "No such file: " + a_seed.to_string_32
			elseif attached l_json.parse_file (a_seed.to_string_8) as al_value and then al_value.is_object
				and then attached al_value.as_object.array_item ({STRING_32} "memes") as al_memes
			then
				l_folder := (create {SIMPLE_FILE}.make (a_seed)).parent_path.to_string_32
				l_now := (create {SIMPLE_DATE_TIME}.make_now).to_iso8601
				l_db := begin_private_pack (a_pack, schema, schema.Builder_command)
				put_pack_provenance (l_db, 1, schema.Source_name, "memes.seed.json",
					"Each meme keeps its own credit and license; a meme built on a photograph credits the photographer.", schema.pack_license)
				from i := 1 until i > al_memes.count or last_error /= Void loop
					if al_memes.item (i).is_object then
						write_meme (l_db, al_memes.item (i).as_object, l_folder, l_now)
					end
					i := i + 1
				end
				if last_error = Void and meme_count = 0 then
					last_error := {STRING_32} "The seed kept no meme: " + a_seed.to_string_32
				end
				finish_pack (l_db)
			else
				last_error := {STRING_32} "The seed does not read as JSON with a %"memes%" array: " + a_seed.to_string_32
			end
		ensure
			something_kept_on_success: last_error = Void implies meme_count > 0
		end

feature -- Passages

	passage_range (a_text: READABLE_STRING_GENERAL): detachable TUPLE [hub_from, hub_to: INTEGER_64]
			-- The verses `a_text' names (BIB_PASSAGE_TEXT); Void when it does not read as a reference.
		do
			Result := passages.range (a_text)
		ensure
			ordered: attached Result as al_range implies (al_range.hub_from > 0 and al_range.hub_to >= al_range.hub_from)
		end

feature {NONE} -- Implementation

	passages: BIB_PASSAGE_TEXT
			-- Reads a passage as the books read theirs.

	write_meme (a_db: SIMPLE_SQL_DATABASE; a_meme: SIMPLE_JSON_OBJECT; a_folder: STRING_32; a_now: STRING_8)
			-- One seed entry, its pictures and passages; left out (a warning) when no picture reads.
		local
			l_slug: STRING_32
			l_pictures: ARRAYED_LIST [TUPLE [cut: STRING_32; png: MANAGED_POINTER]]
			l_id: INTEGER_64
			l_size: TUPLE [width, height: INTEGER]
			i: INTEGER
		do
			l_slug := text_of (a_meme, "slug")
			create l_pictures.make (2)
			if attached a_meme.array_item ({STRING_32} "images") as al_images then
				from i := 1 until i > al_images.count loop
					if al_images.item (i).is_object then
						add_picture (l_pictures, al_images.item (i).as_object, a_folder, l_slug)
					end
					i := i + 1
				end
			end
			if l_slug.is_empty then
				warnings.extend ({STRING_32} "A seed entry without a slug was left out.")
			elseif l_pictures.is_empty then
				warnings.extend ({STRING_32} "No picture of " + l_slug + {STRING_32} " read; it was left out.")
			else
				a_db.execute_with_args ("INSERT INTO meme (slug, title, description, trigger_line, hook, punch, meme_set, credit, license, added_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
					<<l_slug, text_of (a_meme, "title"), text_of (a_meme, "description"), text_of (a_meme, "trigger"), text_of (a_meme, "hook"),
					text_of (a_meme, "punch"), text_of (a_meme, "set"), text_of (a_meme, "credit"), text_of (a_meme, "license"), a_now>>)
				check_db (a_db, {STRING_32} "The meme " + l_slug + {STRING_32} " could not be written.")
				l_id := a_db.last_insert_rowid
				meme_count := meme_count + 1
				across l_pictures as ic until last_error /= Void loop
					l_size := schema.png_size (ic.png)
					a_db.execute_with_args ("INSERT INTO meme_image (meme_id, variant, png, width, height) VALUES (?, ?, ?, ?, ?)",
						<<l_id, ic.cut, ic.png, l_size.width, l_size.height>>)
					check_db (a_db, {STRING_32} "A picture of " + l_slug + {STRING_32} " could not be written.")
					picture_count := picture_count + 1
				end
				across strings_of (a_meme, "passages") as ic until last_error /= Void loop
					if attached passage_range (ic) as al_range then
						a_db.execute_with_args ("INSERT INTO meme_passage (meme_id, hub_from, hub_to, reference) VALUES (?, ?, ?, ?)",
							<<l_id, al_range.hub_from, al_range.hub_to, ic>>)
						check_db (a_db, {STRING_32} "A passage of " + l_slug + {STRING_32} " could not be written.")
						passage_count := passage_count + 1
					else
						warnings.extend ({STRING_32} "%"" + ic + {STRING_32} "%" in " + l_slug + {STRING_32} " does not read as a passage; it was left out.")
					end
				end
			end
		end

	add_picture (a_pictures: ARRAYED_LIST [TUPLE [cut: STRING_32; png: MANAGED_POINTER]]; a_image: SIMPLE_JSON_OBJECT; a_folder, a_slug: STRING_32)
			-- The picture `a_image' names, read from beside the seed, when it is a PNG and its cut is new.
		local
			l_file: STRING_32
			l_variant: STRING_32
		do
			l_variant := text_of (a_image, "variant")
			if l_variant.is_empty then
				l_variant := schema.Feed_variant.to_string_32
			end
			l_file := a_folder + {STRING_32} "\" + text_of (a_image, "file")
			l_file.replace_substring_all ({STRING_32} "/", {STRING_32} "\")
			if across a_pictures as ic some ic.cut.same_string (l_variant) end then
				warnings.extend ({STRING_32} "A second " + l_variant + {STRING_32} " picture of " + a_slug + {STRING_32} " was left out.")
			elseif attached read_bytes (l_file) as al_png and then schema.is_png (al_png) then
				a_pictures.extend ([l_variant, al_png])
			else
				warnings.extend ({STRING_32} "No PNG at " + text_of (a_image, "file") + {STRING_32} " (" + a_slug + {STRING_32} ").")
			end
		end

	read_bytes (a_file: STRING_32): detachable MANAGED_POINTER
			-- The bytes of `a_file' (Void: it does not read).
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_file)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				create Result.make (l_file.count)
				l_file.read_to_managed_pointer (Result, 0, l_file.count)
				l_file.close
			end
		end

end
