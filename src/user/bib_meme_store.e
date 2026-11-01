note
	description: "[
		meme.db opened read-write (research/25, 2026-11-01): Larry's memes for the
		meme tool. `open' reads every meme's words, picture cuts and passages
		(the pictures stay in the file until `picture' fetches one); the
		queries answer the passage being read; `add_meme' keeps a new one as
		Larry adds them, so the file grows on his machine and the next
		installer built there ships it.

		A missing meme.db is no error to the program: the tool says there are
		no memes yet. A file that is not a meme pack, or of another version, is
		refused with the reason and left untouched.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_MEME_STORE

create
	make

feature {NONE} -- Initialization

	make (a_path: READABLE_STRING_GENERAL)
			-- A store over the meme.db at `a_path' (not opened yet).
		require
			named: not a_path.is_empty
		do
			path := a_path.to_string_32
			create memes.make (0)
			create schema
		ensure
			closed: not is_open
		end

feature -- Access

	path: STRING_32
			-- Where meme.db is.

	is_open: BOOLEAN

	last_error: detachable STRING_32
			-- Why `open' failed (Void: it did not, or there is no file).

	write_error: detachable STRING_32
			-- Why the last write failed (Void: it did not).

	memes: ARRAYED_LIST [BIB_MEME]
			-- Every meme, in the order kept.

	schema: BIB_MEME_SCHEMA

	meme_by_slug (a_slug: READABLE_STRING_GENERAL): detachable BIB_MEME
		do
			across memes as ic until Result /= Void loop
				if ic.slug.same_string_general (a_slug) then
					Result := ic
				end
			end
		end

	memes_for_verse (a_hub: INTEGER_64): ARRAYED_LIST [BIB_MEME]
			-- The memes one of whose passages takes in verse `a_hub'.
		do
			create Result.make (4)
			across memes as ic loop
				if ic.names_verse (a_hub) then
					Result.extend (ic)
				end
			end
		end

	memes_for_chapter (a_book, a_chapter: INTEGER): ARRAYED_LIST [BIB_MEME]
			-- The memes one of whose passages lies in that chapter.
		do
			create Result.make (4)
			across memes as ic loop
				if ic.names_chapter (a_book, a_chapter) then
					Result.extend (ic)
				end
			end
		end

	picture (a_meme: BIB_MEME; a_variant: READABLE_STRING_GENERAL): detachable MANAGED_POINTER
			-- The PNG bytes of `a_meme''s picture `a_variant' (Void: none such).
		require
			open: is_open
		do
			if attached database as al_db then
				across al_db.query_with_args ("SELECT png FROM meme_image WHERE meme_id = ? AND variant = ?", <<a_meme.id, a_variant.to_string_8>>).rows as ic until Result /= Void loop
					Result := ic.blob_value ("png")
				end
			end
		end

feature -- Commands

	open
			-- Open meme.db read-write and read every meme; nothing when there is no file.
		require
			closed: not is_open
		local
			l_db: SIMPLE_SQL_DATABASE
			l_kind: STRING_32
			l_version: INTEGER
		do
			last_error := Void
			if (create {SIMPLE_FILE}.make (path)).is_file then
				create l_db.make (path)
				if l_db.has_error then
					last_error := {STRING_32} "meme.db could not be opened: " + path
				else
					create l_kind.make_empty
					across l_db.query ("SELECT value FROM meta WHERE key = 'pack_kind'").rows as ic loop
						l_kind := ic.string_value ("value")
					end
					across l_db.query ("PRAGMA user_version").rows as ic loop
						l_version := ic.integer_value ("user_version")
					end
					if l_db.has_error or else not l_kind.same_string_general (schema.Pack_kind) then
						last_error := {STRING_32} "This is not a meme pack: " + path
					elseif l_version /= schema.Schema_version then
						last_error := {STRING_32} "meme.db has version " + l_version.out + {STRING_32} "; this program reads version " + schema.Schema_version.out + {STRING_32} "."
					end
				end
				if last_error = Void then
					database := l_db
					is_open := True
					load
				else
					l_db.close
				end
			end
		ensure
			open_or_not: is_open implies last_error = Void
		end

	close
		do
			if attached database as al_db then
				al_db.close
			end
			database := Void
			is_open := False
			memes.wipe_out
		ensure
			closed: not is_open
		end

	add_meme (a_title, a_description: READABLE_STRING_GENERAL; a_png: MANAGED_POINTER;
			a_passages: ARRAYED_LIST [TUPLE [hub_from, hub_to: INTEGER_64; wording: STRING_32]])
			-- Keep a new meme: its title, description, picture (a PNG) and passages. Larry's additions,
			-- 2026-11-01: "I will add as I go".
		require
			open: is_open
			titled: not a_title.is_empty
			a_png_picture: schema.is_png (a_png)
			passages_ordered: across a_passages as ic all ic.hub_from > 0 and ic.hub_to >= ic.hub_from end
		local
			l_slug: STRING_32
			l_size: TUPLE [width, height: INTEGER]
			l_id: INTEGER_64
		do
			write_error := Void
			if attached database as al_db then
				l_slug := free_slug (slug_of (a_title))
				l_size := schema.png_size (a_png)
				al_db.begin_transaction
				al_db.execute_with_args ("INSERT INTO meme (slug, title, description, meme_set, credit, added_at) VALUES (?, ?, ?, 'Added', 'Larry Rix', ?)",
					<<l_slug, a_title.to_string_32, a_description.to_string_32, (create {SIMPLE_DATE_TIME}.make_now).to_iso8601>>)
				l_id := al_db.last_insert_rowid
				if not al_db.has_error then
					al_db.execute_with_args ("INSERT INTO meme_image (meme_id, variant, png, width, height) VALUES (?, ?, ?, ?, ?)",
						<<l_id, schema.Feed_variant, a_png, l_size.width, l_size.height>>)
				end
				across a_passages as ic until al_db.has_error loop
					al_db.execute_with_args ("INSERT INTO meme_passage (meme_id, hub_from, hub_to, reference) VALUES (?, ?, ?, ?)",
						<<l_id, ic.hub_from, ic.hub_to, ic.wording>>)
				end
				if al_db.has_error then
					if attached al_db.last_error_message as al_message then
						write_error := {STRING_32} "The meme could not be kept: " + al_message
					else
						write_error := {STRING_32} "The meme could not be kept."
					end
					al_db.rollback
				else
					al_db.commit
					memes.wipe_out
					load
				end
			end
		ensure
			one_more: write_error = Void implies memes.count = old memes.count + 1
		end

feature -- Names

	slug_of (a_title: READABLE_STRING_GENERAL): STRING_32
			-- "Spirit = Mind" as "spirit-mind": letters and digits, lowercase, joined by hyphens.
		local
			l_dash: BOOLEAN
		do
			create Result.make (a_title.count)
			across a_title.to_string_32.as_lower as c loop
				if c.is_alpha_numeric and c.natural_32_code < 128 then
					if l_dash and not Result.is_empty then
						Result.append_character ('-')
					end
					Result.append_character (c)
					l_dash := False
				else
					l_dash := True
				end
			end
			if Result.is_empty then
				Result := {STRING_32} "meme"
			end
		ensure
			named: not Result.is_empty
		end

feature {NONE} -- Implementation

	database: detachable SIMPLE_SQL_DATABASE

	load
			-- Every meme not removed, with its picture cuts and passages.
		require
			open: is_open
		local
			l_meme: BIB_MEME
			l_by_id: HASH_TABLE [BIB_MEME, INTEGER_64]
		do
			create l_by_id.make (128)
			if attached database as al_db then
				across al_db.query ("SELECT meme_id, slug, title, description, trigger_line, hook, punch, meme_set, credit, license FROM meme WHERE deleted = 0 AND slug <> '' ORDER BY meme_id").rows as ic loop
					create l_meme.make (ic.integer_64_value ("meme_id"), ic.string_value ("slug"), ic.string_value ("title"), ic.string_value ("description"))
					l_meme.set_lines (ic.string_value ("trigger_line"), ic.string_value ("hook"), ic.string_value ("punch"),
						ic.string_value ("meme_set"), ic.string_value ("credit"), ic.string_value ("license"))
					memes.extend (l_meme)
					l_by_id.force (l_meme, l_meme.id)
				end
				across al_db.query ("SELECT meme_id, variant, width, height FROM meme_image ORDER BY meme_id, variant <> 'feed', variant").rows as ic loop
					if attached l_by_id.item (ic.integer_64_value ("meme_id")) as al_meme then
						al_meme.variants.extend ([ic.string_value ("variant").to_string_8, ic.integer_value ("width"), ic.integer_value ("height")])
					end
				end
				across al_db.query ("SELECT meme_id, hub_from, hub_to, reference FROM meme_passage WHERE hub_from > 0 AND hub_to >= hub_from ORDER BY rowid").rows as ic loop
					if attached l_by_id.item (ic.integer_64_value ("meme_id")) as al_meme then
						al_meme.passages.extend ([ic.integer_64_value ("hub_from"), ic.integer_64_value ("hub_to"), ic.string_value ("reference")])
					end
				end
			end
		end

	free_slug (a_slug: STRING_32): STRING_32
			-- `a_slug', or `a_slug' with a number after it when it is taken.
		local
			n: INTEGER
		do
			Result := a_slug
			from n := 2 until meme_by_slug (Result) = Void loop
				Result := a_slug + {STRING_32} "-" + n.out
				n := n + 1
			end
		end

invariant
	closed_means_empty: not is_open implies memes.is_empty

end
