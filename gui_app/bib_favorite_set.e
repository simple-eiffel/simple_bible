note
	description: "[
		The reader's favorites as one state (research/24 stage C, 2026-11-01):
		the folders and favorites user.db holds, which of them show (a removed
		folder hides everything in it), the one order the tree lists them in (a
		notes app's file explorer: folders first, then by name, changed time or
		created time), and the verses and chapters they star. `changed' is told
		after every load and every new order; the tree and every starred view
		join it, and joining tells the present.

		A passage that spans a whole chapter stars the chapter (in the Books
		tree), not each of its verses; a verse or a range stars its verses.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_FAVORITE_SET

create
	make

feature {NONE} -- Initialization

	make
		do
			create folders.make (0)
			create items.make (0)
			create starred_passages.make (0)
			create starred_chapters.make (0)
			create changed.make
			sort_order := By_name
		ensure
			empty: folders.is_empty and items.is_empty
		end

feature -- Access

	folders: ARRAYED_LIST [BIB_FAVORITE_FOLDER]
			-- Every folder user.db lists (not removed), oldest first.

	items: ARRAYED_LIST [BIB_FAVORITE]
			-- Every favorite user.db lists (not removed), oldest first.

	sort_order: INTEGER
			-- How the tree lists each folder's contents (`By_name' and the rest).

	folder (a_id: INTEGER_64): detachable BIB_FAVORITE_FOLDER
			-- The listed folder `a_id'.
		do
			across folders as ic until Result /= Void loop
				if ic.id = a_id then
					Result := ic
				end
			end
		end

	item (a_id: INTEGER_64): detachable BIB_FAVORITE
			-- The listed favorite `a_id'.
		do
			across items as ic until Result /= Void loop
				if ic.id = a_id then
					Result := ic
				end
			end
		end

	is_folder_shown (a_id: INTEGER_64): BOOLEAN
			-- Is folder `a_id' (0: the root) shown: it and every folder above it listed?
		local
			l_id: INTEGER_64
			n: INTEGER
		do
			from
				l_id := a_id
				Result := True
			until
				l_id = 0 or not Result
			loop
				if n <= folders.count and then attached folder (l_id) as al_folder then
					l_id := al_folder.parent_id
					n := n + 1
				else
					Result := False
				end
			end
		end

	is_inside (a_id, a_ancestor: INTEGER_64): BOOLEAN
			-- Is folder `a_id' folder `a_ancestor' itself, or inside it (0: the root holds all)?
		local
			l_id: INTEGER_64
			n: INTEGER
		do
			from
				l_id := a_id
			until
				Result or l_id = 0 or n > folders.count
			loop
				if l_id = a_ancestor then
					Result := True
				elseif attached folder (l_id) as al_folder then
					l_id := al_folder.parent_id
				else
					l_id := 0
				end
				n := n + 1
			end
			Result := Result or a_ancestor = 0
		end

	child_folders (a_parent_id: INTEGER_64): ARRAYED_LIST [BIB_FAVORITE_FOLDER]
			-- The folders in folder `a_parent_id', in `sort_order' (none when it is not shown).
		do
			create Result.make (4)
			if is_folder_shown (a_parent_id) then
				across folders as ic loop
					if ic.parent_id = a_parent_id then
						insert_folder (Result, ic)
					end
				end
			end
		end

	child_items (a_folder_id: INTEGER_64): ARRAYED_LIST [BIB_FAVORITE]
			-- The favorites in folder `a_folder_id', in `sort_order' (none when it is not shown).
		do
			create Result.make (8)
			if is_folder_shown (a_folder_id) then
				across items as ic loop
					if ic.folder_id = a_folder_id then
						insert_item (Result, ic)
					end
				end
			end
		end

	shown_item_count: INTEGER
			-- Favorites in shown folders.
		do
			across items as ic loop
				if is_folder_shown (ic.folder_id) then
					Result := Result + 1
				end
			end
		end

	shown_folder_count: INTEGER
		do
			across folders as ic loop
				if is_folder_shown (ic.id) then
					Result := Result + 1
				end
			end
		end

	folder_path (a_id: INTEGER_64): STRING_32
			-- "Grace / Faith" for folder `a_id'; empty for the root.
		local
			l_id: INTEGER_64
			n: INTEGER
		do
			create Result.make_empty
			from
				l_id := a_id
			until
				l_id = 0 or n > folders.count
			loop
				if attached folder (l_id) as al_folder then
					if Result.is_empty then
						Result := al_folder.name.twin
					else
						Result := al_folder.name + {STRING_32} " / " + Result
					end
					l_id := al_folder.parent_id
				else
					l_id := 0
				end
				n := n + 1
			end
		end

	shown_folders_by_path: ARRAYED_LIST [BIB_FAVORITE_FOLDER]
			-- Every shown folder, by its path (the Add sheet's folder choices).
		local
			i: INTEGER
		do
			create Result.make (folders.count)
			across folders as ic loop
				if is_folder_shown (ic.id) then
					from i := 1 until i > Result.count or else folder_path (ic.id).as_lower < folder_path (Result.i_th (i).id).as_lower loop
						i := i + 1
					end
					Result.go_i_th (i)
					Result.put_left (ic)
				end
			end
		end

feature -- Stars

	is_verse_starred (a_hub: INTEGER_64): BOOLEAN
			-- Does a shown verse or range (not a whole chapter) take in verse `a_hub'?
		do
			Result := across starred_passages as ic some ic.covers (a_hub) end
		end

	is_chapter_starred (a_book, a_chapter: INTEGER): BOOLEAN
			-- Is chapter `a_chapter' of `a_book' a shown whole-chapter favorite?
		do
			Result := starred_chapters.has (a_book * 1000 + a_chapter)
		end

feature -- Events

	changed: SW_EVENT [TUPLE]
			-- Told after every load and every new order; listeners read the queries.

	on_change (a_action: PROCEDURE)
			-- `a_action' told every change, and now.
		do
			changed.subscribe (a_action)
			a_action.call (Void)
		end

feature -- Doors

	load (a_folders: ARRAYED_LIST [BIB_FAVORITE_FOLDER]; a_items: ARRAYED_LIST [BIB_FAVORITE])
			-- What user.db lists now; the stars are worked out again and the listeners told.
		local
			l_hub: BIB_HUB_ID
		do
			folders := a_folders
			items := a_items
			starred_passages.wipe_out
			starred_chapters.wipe_out
			create l_hub
			across items as ic loop
				if (ic.is_passage or ic.is_verse_quotation) and then is_folder_shown (ic.folder_id) then
					if ic.is_whole_chapter then
						starred_chapters.extend (l_hub.book_of (ic.hub_id) * 1000 + l_hub.chapter_of (ic.hub_id))
					else
						starred_passages.extend (ic)
					end
				end
			end
			changed.call (Void)
		ensure
			kept: folders = a_folders and items = a_items
		end

	set_sort_order (a_order: INTEGER)
			-- List each folder's contents by `a_order'.
		require
			known: a_order >= By_name and a_order <= By_created_oldest
		do
			if a_order /= sort_order then
				sort_order := a_order
				changed.call (Void)
			end
		ensure
			set: sort_order = a_order
		end

feature -- Orders (a notes app's file explorer: one order for the whole tree)

	By_name: INTEGER = 1
	By_name_descending: INTEGER = 2
	By_changed_newest: INTEGER = 3
	By_changed_oldest: INTEGER = 4
	By_created_newest: INTEGER = 5
	By_created_oldest: INTEGER = 6

	order_name (a_order: INTEGER): STRING_32
			-- How order `a_order' reads in a menu.
		require
			known: a_order >= By_name and a_order <= By_created_oldest
		do
			inspect a_order
			when By_name then
				Result := {STRING_32} "Name (A to Z)"
			when By_name_descending then
				Result := {STRING_32} "Name (Z to A)"
			when By_changed_newest then
				Result := {STRING_32} "Changed (newest first)"
			when By_changed_oldest then
				Result := {STRING_32} "Changed (oldest first)"
			when By_created_newest then
				Result := {STRING_32} "Created (newest first)"
			else
				Result := {STRING_32} "Created (oldest first)"
			end
		end

feature {NONE} -- Implementation

	starred_passages: ARRAYED_LIST [BIB_FAVORITE]
			-- The shown verses and ranges (not whole chapters).

	starred_chapters: ARRAYED_LIST [INTEGER]
			-- The shown whole chapters, as book * 1000 + chapter.

	insert_folder (a_list: ARRAYED_LIST [BIB_FAVORITE_FOLDER]; a_folder: BIB_FAVORITE_FOLDER)
			-- `a_folder' into `a_list' at its place in `sort_order'.
		local
			i: INTEGER
		do
			from i := 1 until i > a_list.count or else comes_before (a_folder.name, a_folder, a_list.i_th (i).name, a_list.i_th (i)) loop
				i := i + 1
			end
			a_list.go_i_th (i)
			a_list.put_left (a_folder)
		end

	insert_item (a_list: ARRAYED_LIST [BIB_FAVORITE]; a_item: BIB_FAVORITE)
			-- `a_item' into `a_list' at its place in `sort_order'.
		local
			i: INTEGER
		do
			from i := 1 until i > a_list.count or else comes_before (a_item.label, a_item, a_list.i_th (i).label, a_list.i_th (i)) loop
				i := i + 1
			end
			a_list.go_i_th (i)
			a_list.put_left (a_item)
		end

	comes_before (a_name: STRING_32; a: BIB_USER_ITEM; a_other_name: STRING_32; b: BIB_USER_ITEM): BOOLEAN
			-- Does `a' (named `a_name') come before `b' in `sort_order'? Ties fall to the older first.
		do
			inspect sort_order
			when By_name then
				Result := a_name.as_lower < a_other_name.as_lower or (a_name.as_lower.same_string (a_other_name.as_lower) and a.id < b.id)
			when By_name_descending then
				Result := a_name.as_lower > a_other_name.as_lower or (a_name.as_lower.same_string (a_other_name.as_lower) and a.id < b.id)
			when By_changed_newest, By_changed_oldest then
				if attached a.changed_at as al_a and then attached b.changed_at as al_b and then not al_a.is_equal (al_b) then
					Result := (al_a > al_b) = (sort_order = By_changed_newest)
				else
					Result := a.id < b.id
				end
			when By_created_newest then
				Result := a.id > b.id
			else
				Result := a.id < b.id
			end
		end

invariant
	known_order: sort_order >= By_name and sort_order <= By_created_oldest

end
