note
	description: "Rotating local backup of user data on exit and restore from Settings (03 A-022, AC-1a-40; simple_sql online backup in Phase 4)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_USER_BACKUP

create
	make

feature {NONE} -- Initialization

	make (a_folder: READABLE_STRING_GENERAL)
		require
			folder_chosen: not a_folder.is_empty
		do
			folder := a_folder.to_string_32
		ensure
			none_yet: backup_count = 0
		end

feature -- Access

	folder: STRING_32
	backup_count: INTEGER
	newest_backup_time: INTEGER_64
			-- Seconds since the epoch of the newest backup (0 when none).
	last_error: detachable BIB_ERROR

feature -- Commands

	backup_on_exit (a_store: BIB_USER_STORE)
		require
			open: a_store.is_open
		do
			-- Phase 4
		ensure
			rotated: backup_count <= Max_backups
			newest_first: last_error = Void implies newest_backup_time >= old newest_backup_time
		end

	restore (a_backup_index: INTEGER; a_store: BIB_USER_STORE)
		require
			exists: a_backup_index >= 1 and a_backup_index <= backup_count
		do
			-- Phase 4: the current user.db is kept as a backup first.
		ensure
			current_kept_as_backup: last_error = Void implies backup_count >= old backup_count
		end

feature -- Constants

	Max_backups: INTEGER = 5

invariant
	folder_chosen: not folder.is_empty
	bounded: backup_count >= 0 and backup_count <= Max_backups

end
