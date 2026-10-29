note
	description: "[
		One tool call NEEDLE proposes for an Ask request (0.7.31): the tool's name
		("open_passage", "search_text" ...) and its arguments, each a text or a list
		of texts. BIB_ASK_CHECK checks it, may repair an argument (`set_text'), and
		only then does the window run it with its own actions: no model text is
		ever shown.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ASK_CALL

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL)
			-- A call of tool `a_name', no arguments yet.
		require
			named: not a_name.is_empty
		do
			name := a_name.to_string_32
			create texts_by_key.make (4)
			create lists_by_key.make (2)
		ensure
			named: name.same_string_general (a_name)
			no_arguments: keys.is_empty
		end

feature -- Access

	name: STRING_32
			-- The tool.

	keys: ARRAYED_LIST [STRING_32]
			-- Every argument's key, texts then lists.
		do
			create Result.make (texts_by_key.count + lists_by_key.count)
			across texts_by_key as ic loop
				Result.extend (@ic.key)
			end
			across lists_by_key as ic loop
				Result.extend (@ic.key)
			end
		end

	has (a_key: READABLE_STRING_GENERAL): BOOLEAN
			-- Does the call give argument `a_key'?
		do
			Result := texts_by_key.has (a_key.to_string_32) or lists_by_key.has (a_key.to_string_32)
		end

	text (a_key: READABLE_STRING_GENERAL): STRING_32
			-- Text argument `a_key'; empty when the call gives none.
		do
			if attached texts_by_key.item (a_key.to_string_32) as al_text then
				Result := al_text
			else
				create Result.make_empty
			end
		end

	texts (a_key: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- List argument `a_key'; empty when the call gives none.
		do
			if attached lists_by_key.item (a_key.to_string_32) as al_list then
				Result := al_list
			else
				create Result.make (0)
			end
		end

	description: STRING_32
			-- "open_passage(reference=John 3:16)", for the log.
		do
			Result := name.twin
			Result.append_character ('(')
			across texts_by_key as ic loop
				if Result [Result.count] /= '(' then
					Result.append ({STRING_32} ", ")
				end
				Result.append (@ic.key + {STRING_32} "=" + ic)
			end
			across lists_by_key as ic loop
				if Result [Result.count] /= '(' then
					Result.append ({STRING_32} ", ")
				end
				Result.append (@ic.key + {STRING_32} "=[")
				across ic as ic_item loop
					if Result [Result.count] /= '[' then
						Result.append ({STRING_32} ", ")
					end
					Result.append (ic_item)
				end
				Result.append_character (']')
			end
			Result.append_character (')')
		end

feature -- Element change

	set_text (a_key, a_value: READABLE_STRING_GENERAL)
			-- Text argument `a_key' is `a_value' (a reading or a repair).
		require
			key_given: not a_key.is_empty
		do
			texts_by_key.force (a_value.to_string_32, a_key.to_string_32)
		ensure
			set: text (a_key).same_string_general (a_value)
		end

	set_texts (a_key: READABLE_STRING_GENERAL; a_values: ARRAYED_LIST [STRING_32])
			-- List argument `a_key' is `a_values'.
		require
			key_given: not a_key.is_empty
		do
			lists_by_key.force (a_values, a_key.to_string_32)
		ensure
			set: texts (a_key) = a_values
		end

feature {NONE} -- Representation

	texts_by_key: HASH_TABLE [STRING_32, STRING_32]
	lists_by_key: HASH_TABLE [ARRAYED_LIST [STRING_32], STRING_32]

invariant
	named: not name.is_empty

end
