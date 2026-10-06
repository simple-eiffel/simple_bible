note
	description: "[
		Compiled-in private plug-ins (A-012, FR-125). Empty in the public build:
		no registration call exists in any public root, and the purity test
		asserts `plugin_count = 0' (AC-1a-57). Sealed before SIMPLE_BIBLE.open.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_PLUGIN_REGISTRY

create
	make

feature {NONE} -- Initialization

	make
		do
			create plugins.make (2)
		ensure
			empty: plugin_count = 0
			open_for_registration: not is_sealed
		end

feature -- Status

	plugin_count: INTEGER
		do
			Result := plugins.count
		ensure
			model_agrees: Result = plugins_model.count
		end

	is_sealed: BOOLEAN

	has_plugin (a_name: READABLE_STRING_8): BOOLEAN
		do
			Result := across plugins as p some p.name.same_string (a_name) end
		end

feature -- Commands

	register (a_plugin: BIB_PLUGIN)
		require
			not_sealed: not is_sealed
			not_registered: not has_plugin (a_plugin.name)
		do
			plugins.extend (a_plugin)
		ensure
			appended: plugins_model |=| (old plugins_model & a_plugin)
		end

	seal
		do
			is_sealed := True
		ensure
			sealed: is_sealed
			unchanged: plugins_model |=| old plugins_model
		end

feature -- Model

	plugins_model: MML_SEQUENCE [BIB_PLUGIN]
		do
			create Result
			across plugins as p loop
				Result := Result & p
			end
		end

feature {NONE} -- Representation

	plugins: ARRAYED_LIST [BIB_PLUGIN]

invariant
	count_non_negative: plugin_count >= 0

end
