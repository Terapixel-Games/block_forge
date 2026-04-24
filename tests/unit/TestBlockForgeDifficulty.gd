extends "res://tests/framework/TestCase.gd"

const BlockForgeRules := preload("res://src/games/block_forge/BlockForgeRules.gd")
const BlockForgeDifficulty := preload("res://src/games/block_forge/BlockForgeDifficulty.gd")

func test_pressure_level_scales_with_board_fill() -> void:
	var empty_board: Array = BlockForgeRules.create_board(8, 8)
	var mid_board: Array = _board_with_filled_cells(8, 8, 34)
	var high_board: Array = _board_with_filled_cells(8, 8, 50)

	var empty_pressure: int = BlockForgeDifficulty.pressure_level(empty_board, 0)
	var mid_pressure: int = BlockForgeDifficulty.pressure_level(mid_board, 0)
	var high_pressure: int = BlockForgeDifficulty.pressure_level(high_board, 3)

	assert_equal(empty_pressure, 0, "Empty board should start at pressure 0")
	assert_true(mid_pressure >= 1, "Mid-fill board should increase pressure")
	assert_true(high_pressure >= 3, "High fill + dry streak should hit critical pressure")

func test_max_piece_cells_guardrail_reduces_spikes() -> void:
	var p0: int = BlockForgeDifficulty.max_piece_cells_for_pressure(0)
	var p1: int = BlockForgeDifficulty.max_piece_cells_for_pressure(1)
	var p2: int = BlockForgeDifficulty.max_piece_cells_for_pressure(2)
	var p3: int = BlockForgeDifficulty.max_piece_cells_for_pressure(3)

	assert_true(p0 >= p1 and p1 >= p2 and p2 >= p3, "Piece-size guardrail should tighten as pressure rises")
	assert_true(p3 <= 3, "Critical pressure should clamp to small pieces")

func test_lifeline_guardrail_activation() -> void:
	assert_true(BlockForgeDifficulty.should_force_lifeline(2, 0), "High pressure should force lifeline slot")
	assert_true(BlockForgeDifficulty.should_force_lifeline(0, 3), "Dry streak should force lifeline slot")
	assert_true(not BlockForgeDifficulty.should_force_lifeline(0, 0), "Low pressure without dry streak should not force lifeline")

func _board_with_filled_cells(width: int, height: int, filled_cells: int) -> Array:
	var board: Array = BlockForgeRules.create_board(width, height)
	var limit: int = min(filled_cells, width * height)
	var index: int = 0
	for y in range(height):
		for x in range(width):
			if index >= limit:
				return board
			board[y][x] = 1
			index += 1
	return board
