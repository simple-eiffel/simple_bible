note
	description: "[
		The clients BIB_GUI_APP selectively exports its window-harness features to
		(research/23, 2026-10-31): a class that inherits this one may build the
		whole window offscreen (`make_harness') and drive it; no other client
		sees those features. The GUI tests (testing_gui) inherit it.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_WINDOW_HARNESS_CLIENT

end
