note
	description: "[
		meme.db, version 1 (research/25, 2026-11-01): Larry's memes, each a title,
		a description (the post copy that goes with it), its trigger, hook and
		punch lines, the set it belongs to, its credit and license, one or more
		pictures (the feed design, a typographic card, a square or wide cut) and
		the passages it references, as hub ranges with the reference as written.

		Written first by BIB_MEME_BUILDER from the seed beside the memes in the
		vault; read and added to by BIB_MEME_STORE. It is a data file beside
		user.db, not a pack in the packs folder: the meme tool writes to it.
		Public: Larry's own work, free to share; a meme built on someone's
		photograph keeps that photograph's credit and license in its row.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_MEME_SCHEMA

inherit
	BIB_PRIVATE_PACK_SCHEMA

feature -- Constants

	Pack_kind: STRING_8 = "memes"
			-- `meta.pack_kind' of meme.db.

	Pack_file_name: STRING_8 = "meme.db"

	Pack_title: STRING_8 = "Memes"

	Builder_command: STRING_8 = "bible_build --memes"

	Source_name: STRING_8 = "Larry Rix's memes"

	Feed_variant: STRING_8 = "feed"
			-- The picture a meme shows first.

	is_png (a_bytes: MANAGED_POINTER): BOOLEAN
			-- Do `a_bytes' start as a PNG does (the signature, then the IHDR chunk)?
		do
			Result := a_bytes.count >= 24
				and then a_bytes.read_natural_8 (0) = 0x89 and then a_bytes.read_natural_8 (1) = 0x50
				and then a_bytes.read_natural_8 (2) = 0x4E and then a_bytes.read_natural_8 (3) = 0x47
				and then a_bytes.read_natural_8 (12) = 0x49 and then a_bytes.read_natural_8 (13) = 0x48
				and then a_bytes.read_natural_8 (14) = 0x44 and then a_bytes.read_natural_8 (15) = 0x52
		end

	png_size (a_bytes: MANAGED_POINTER): TUPLE [width, height: INTEGER]
			-- The width and height a PNG's IHDR chunk gives (big-endian at bytes 16 and 20).
		require
			a_png: is_png (a_bytes)
		do
			Result := [big_endian (a_bytes, 16), big_endian (a_bytes, 20)]
		end

	pack_tables: ARRAY [STRING_8]
			-- meme.db's own tables.
		once
			Result := <<
				"CREATE TABLE meme(meme_id INTEGER PRIMARY KEY, slug TEXT NOT NULL UNIQUE, title TEXT NOT NULL, description TEXT NOT NULL, trigger_line TEXT NOT NULL DEFAULT '', hook TEXT NOT NULL DEFAULT '', punch TEXT NOT NULL DEFAULT '', meme_set TEXT NOT NULL DEFAULT '', credit TEXT NOT NULL DEFAULT '', license TEXT NOT NULL DEFAULT '', added_at TEXT NOT NULL, deleted INTEGER NOT NULL DEFAULT 0)",
				"CREATE TABLE meme_image(meme_id INTEGER NOT NULL REFERENCES meme(meme_id), variant TEXT NOT NULL, png BLOB NOT NULL, width INTEGER NOT NULL, height INTEGER NOT NULL, PRIMARY KEY (meme_id, variant))",
				"CREATE TABLE meme_passage(meme_id INTEGER NOT NULL REFERENCES meme(meme_id), hub_from INTEGER NOT NULL, hub_to INTEGER NOT NULL CHECK (hub_to >= hub_from), reference TEXT NOT NULL)",
				"CREATE INDEX meme_passage_place ON meme_passage(hub_from, hub_to)">>
		end

feature {NONE} -- Implementation

	big_endian (a_bytes: MANAGED_POINTER; a_at: INTEGER): INTEGER
			-- The 32-bit big-endian number at byte `a_at'.
		require
			inside: a_at >= 0 and a_at + 4 <= a_bytes.count
		do
			Result := (a_bytes.read_natural_8 (a_at).to_integer_32 |<< 24) + (a_bytes.read_natural_8 (a_at + 1).to_integer_32 |<< 16)
				+ (a_bytes.read_natural_8 (a_at + 2).to_integer_32 |<< 8) + a_bytes.read_natural_8 (a_at + 3).to_integer_32
		end

end
