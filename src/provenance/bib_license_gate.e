note
	description: "[
		The refusal to ship unknown or restricted sources (FR-004, AC-1a-02/03).
		Records which keys were refused and names each in the refusal message.
		The engine owns the rule; the build pipeline applies it to its manifest.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LICENSE_GATE

create
	make

feature {NONE} -- Initialization

	make
			-- Create a gate with no refusals.
		do
			create refused_keys.make (0)
			create refusal_message.make_empty
		ensure
			no_refusal: not has_refusal
		end

feature -- Decision

	ship_allowed (a_item: BIB_LICENSED_ITEM): BOOLEAN
			-- May `a_item' ship?
		do
			Result := a_item.ship and a_item.license.may_ship_in_free_tool
		ensure
			unknown_refused: a_item.license.is_unknown implies not Result
			restricted_refused: a_item.license.is_restricted implies not Result
			flag_respected: not a_item.ship implies not Result
		end

	check_items (a_items: ITERABLE [BIB_LICENSED_ITEM])
			-- Gate every item; record each one asked to ship that may not.
		do
			-- Phase 4: reset; for each item with `ship' and not `ship_allowed', record its key and name it in `refusal_message'.
		ensure
			refusal_iff_refused_ship: has_refusal = across a_items as i some i.ship and not ship_allowed (i) end
			every_refusal_named: across refused_keys as k all refusal_message.has_substring (k) end
		end

feature -- Status

	has_refusal: BOOLEAN
			-- Was any item refused by the last `check_items'?
		do
			Result := not refused_keys.is_empty
		end

	refusal_message: STRING_32
			-- Named error naming every refused key.

feature -- Model

	refused_model: MML_SEQUENCE [STRING_32]
			-- Keys refused by the last check, in order.
		do
			create Result
			across refused_keys as k loop
				Result := Result & k
			end
		end

feature {NONE} -- Representation

	refused_keys: ARRAYED_LIST [STRING_32]

invariant
	message_when_refused: has_refusal implies not refusal_message.is_empty

end
