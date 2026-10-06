note
	description: "User data keyed to hub ids; append-only; the Markdown note store (AC-1a-39..43)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_USER_STORE

inherit
	TEST_SET_BASE

feature -- Tests

	test_notes_keyed_by_hub_id
		local
			n: BIB_NOTE
		do
			create n.make (2501, "", "God so loved")
			assert ("keyed", n.hub_id = 2501 and not n.is_topical)
			assert ("unstored", not n.is_stored)
			create n.make_topical ("Covenant", "notes")
			assert ("topical", n.is_topical)
		end

	test_user_items_carry_no_version
			-- A highlight is keyed by hub id only; there is no version field to diverge (AC-1a-39).
		local
			h: BIB_HIGHLIGHT
		do
			create h.make (2501, "promise")
			assert ("hub id", h.hub_id = 2501)
			assert ("kind", h.kind = {BIB_USER_STORE}.Kind_highlight)
		end

	test_user_store_is_the_only_writer
		local
			u: BIB_USER_STORE
			c: BIB_CORE_SOURCE
		do
			create u.make ("user.db")
			create c.make ("core.db")
			assert ("user store writes", not u.is_read_only)
			assert ("core read-only", c.is_read_only)
		end

	test_highlight_shows_in_every_version
			-- Skeletal (Phase 5, AC-1a-39): a BSB highlight on John 3:16 appears on John 3:16 in every version.
		do
		end

	test_edit_appends_and_delete_is_soft
			-- Skeletal (Phase 5, AC-1a-40): an edit writes a new version; a delete is soft; both restore.
		do
		end

	test_backup_on_exit_restores
			-- Skeletal (Phase 5, AC-1a-40): a rotating backup is written on exit and restores.
		do
		end

	test_previous_schema_migrates
			-- Skeletal (Phase 5, AC-1a-41): the previous-schema fixture migrates with every setting, layout and note.
		do
		end

	test_markdown_store_is_default_with_index
			-- Skeletal (Phase 5, AC-1a-42; RQ-06 gate): notes as Markdown files, user.db as index, plain verse links.
		do
		end

	test_markdown_external_edit_gets_conflict_copy
			-- Skeletal (Phase 5, AC-1a-43): a file changed outside the program is never overwritten.
		do
		end

	test_markdown_second_instance_read_only
			-- Skeletal (Phase 5, AC-1a-43): a second instance opens read-only.
		do
		end

	test_markdown_rename_leaves_no_dangling_row
			-- Skeletal (Phase 5, AC-1a-43): a renamed or deleted file leaves no dangling index row.
		do
		end

end
