extends GdUnitTestSuite

const BlockForgeRules := preload("res://src/games/block_forge/BlockForgeRules.gd")
const BlockForgePieces := preload("res://src/games/block_forge/BlockForgePieces.gd")

func test_placement_validity() -> void:
	var board: Array = BlockForgeRules.create_board(8, 8)
	var square: Dictionary = BlockForgePieces.piece_by_id("square_2")
	assert_that(BlockForgeRules.can_place(board, square, Vector2i(0, 0))).is_true()
	board = BlockForgeRules.place(board, square, Vector2i(0, 0))
	assert_that(BlockForgeRules.can_place(board, square, Vector2i(0, 0))).is_false()
	assert_that(BlockForgeRules.can_place(board, square, Vector2i(7, 7))).is_false()

func test_line_clearing() -> void:
	var board: Array = BlockForgeRules.create_board(8, 8)
	for x in range(8):
		board[0][x] = 1
	for y in range(8):
		board[y][3] = 1
	var result: Dictionary = BlockForgeRules.clear_lines(board)
	var cleared_board: Array = result.get("board", [])
	assert_that(int(result.get("count", 0))).is_equal(2)
	for x in range(8):
		assert_that(int(cleared_board[0][x])).is_equal(0)
	for y in range(8):
		assert_that(int(cleared_board[y][3])).is_equal(0)

func test_combo_scoring() -> void:
	var first_clear: Dictionary = BlockForgeRules.score_for_move(4, 1, 1)
	var second_clear: Dictionary = BlockForgeRules.score_for_move(4, 1, 2)
	assert_that(int(first_clear.get("total", 0))).is_equal(79)
	assert_that(int(second_clear.get("total", 0))).is_equal(104)

func test_game_over_detection() -> void:
	var board: Array = BlockForgeRules.create_board(8, 8)
	for y in range(8):
		for x in range(8):
			board[y][x] = 1
	board[7][7] = 0
	var blocked_tray: Array = [
		BlockForgePieces.piece_by_id("square_2"),
		BlockForgePieces.piece_by_id("line_3_h"),
	]
	assert_that(BlockForgeRules.any_move_possible(board, blocked_tray)).is_false()
	var single_tray: Array = [BlockForgePieces.piece_by_id("single")]
	assert_that(BlockForgeRules.any_move_possible(board, single_tray)).is_true()

func test_revive_clears_up_to_n_cells() -> void:
	var board: Array = BlockForgeRules.create_board(8, 8)
	for x in range(6):
		board[0][x] = 1
	var revived: Dictionary = BlockForgeRules.apply_revive(board, 10)
	assert_that(int(revived.get("cleared", 0))).is_equal(6)
	var revived_board: Array = revived.get("board", [])
	var filled_left: int = 0
	for y in range(8):
		for x in range(8):
			if int(revived_board[y][x]) != 0:
				filled_left += 1
	assert_that(filled_left).is_equal(0)
