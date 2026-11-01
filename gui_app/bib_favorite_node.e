note
	description: "[
		One line of the Favorites tree (research/24 stage C, 2026-11-01): a folder
		or a favorite. SW_TREE keeps its open folders by object identity, so the
		window keeps one node per row and points it at the newest row read back
		(`refresh'), and a reload keeps the tree as the reader left it.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_FAVORITE_NODE

create
	make_folder,
	make_item

feature {NONE} -- Initialization

	make_folder (a_folder: BIB_FAVORITE_FOLDER)
		do
			folder := a_folder
		ensure
			a_folder_node: is_folder and folder = a_folder
		end

	make_item (a_item: BIB_FAVORITE)
		do
			item := a_item
		ensure
			an_item_node: not is_folder and item = a_item
		end

feature -- Access

	folder: detachable BIB_FAVORITE_FOLDER
			-- The folder this line shows (Void for a favorite).

	item: detachable BIB_FAVORITE
			-- The favorite this line shows (Void for a folder).

	is_folder: BOOLEAN
		do
			Result := folder /= Void
		end

	label: STRING_32
			-- A folder's name; a favorite's name with the version it was saved in.
		do
			if attached folder as al_folder then
				Result := al_folder.name
			elseif attached item as al_item then
				if al_item.version.is_empty then
					Result := al_item.label
				else
					Result := al_item.label + {STRING_32} " (" + al_item.version.to_string_32 + {STRING_32} ")"
				end
			else
				create Result.make_empty
			end
		end

	key: INTEGER_64
			-- The row it shows: a folder's id negated, a favorite's id.
		do
			if attached folder as al_folder then
				Result := - al_folder.id
			elseif attached item as al_item then
				Result := al_item.id
			end
		end

feature -- Change

	refresh_folder (a_folder: BIB_FAVORITE_FOLDER)
			-- The folder row read back again.
		require
			a_folder_node: is_folder
			same_row: attached folder as al_folder and then al_folder.id = a_folder.id
		do
			folder := a_folder
		ensure
			set: folder = a_folder
		end

	refresh_item (a_item: BIB_FAVORITE)
			-- The favorite row read back again.
		require
			an_item_node: not is_folder
			same_row: attached item as al_item and then al_item.id = a_item.id
		do
			item := a_item
		ensure
			set: item = a_item
		end

invariant
	one_or_the_other: (folder /= Void) xor (item /= Void)

end
