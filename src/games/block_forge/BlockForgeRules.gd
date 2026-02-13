extends RefCounted

static func create_board(width: int = 8, height: int = 8) -> Array:
	var board: Array = []
	for _y in range(height):
		var row: Array = []
		for _x in range(width):
			row.append(0)
		board.append(row)
	return board

static func can_place(board: Array, piece: Dictionary, origin: Vector2i) -> bool:
	if board.is_empty():
		return false
	var cells: Array = piece.get("cells", [])
	if cells.is_empty():
		return false
	var height: int = board.size()
	var width: int = (board[0] as Array).size()
	for cell_variant in cells:
		var cell: Vector2i = _to_vec2i(cell_variant)
		var x: int = origin.x + cell.x
		var y: int = origin.y + cell.y
		if x < 0 or y < 0 or x >= width or y >= height:
			return false
		if int(board[y][x]) != 0:
			return false
	return true

static func place(board: Array, piece: Dictionary, origin: Vector2i) -> Array:
	var placed_board: Array = _copy_board(board)
	if not can_place(placed_board, piece, origin):
		return placed_board
	for cell_variant in piece.get("cells", []):
		var cell: Vector2i = _to_vec2i(cell_variant)
		var x: int = origin.x + cell.x
		var y: int = origin.y + cell.y
		placed_board[y][x] = 1
	return placed_board

static func find_full_lines(board: Array) -> Dictionary:
	if board.is_empty():
		return {"rows": [], "cols": []}
	var rows: Array = []
	var cols: Array = []
	var height: int = board.size()
	var width: int = (board[0] as Array).size()
	for y in range(height):
		var row_full: bool = true
		for x in range(width):
			if int(board[y][x]) == 0:
				row_full = false
				break
		if row_full:
			rows.append(y)
	for x in range(width):
		var col_full: bool = true
		for y in range(height):
			if int(board[y][x]) == 0:
				col_full = false
				break
		if col_full:
			cols.append(x)
	return {"rows": rows, "cols": cols}

static func clear_lines(board: Array) -> Dictionary:
	var next_board: Array = _copy_board(board)
	var lines: Dictionary = find_full_lines(next_board)
	var rows: Array = lines.get("rows", [])
	var cols: Array = lines.get("cols", [])
	var width: int = 0
	var height: int = next_board.size()
	if height > 0:
		width = (next_board[0] as Array).size()
	for row_index_variant in rows:
		var row_index: int = int(row_index_variant)
		for x in range(width):
			next_board[row_index][x] = 0
	for col_index_variant in cols:
		var col_index: int = int(col_index_variant)
		for y in range(height):
			next_board[y][col_index] = 0
	return {
		"board": next_board,
		"rows": rows.duplicate(),
		"cols": cols.duplicate(),
		"count": rows.size() + cols.size(),
	}

static func any_move_possible(board: Array, tray: Array) -> bool:
	if board.is_empty():
		return false
	var height: int = board.size()
	var width: int = (board[0] as Array).size()
	for piece_variant in tray:
		if not (piece_variant is Dictionary):
			continue
		var piece: Dictionary = piece_variant
		if not piece.has("cells"):
			continue
		for y in range(height):
			for x in range(width):
				if can_place(board, piece, Vector2i(x, y)):
					return true
	return false

static func apply_revive(board: Array, count: int) -> Dictionary:
	var revived_board: Array = _copy_board(board)
	var filled_cells: Array = _collect_filled_cells(revived_board)
	if filled_cells.is_empty() or count <= 0:
		return {"board": revived_board, "cleared": 0, "cells": []}
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(filled_cells.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = filled_cells[i]
		filled_cells[i] = filled_cells[j]
		filled_cells[j] = tmp
	var to_clear: int = min(count, filled_cells.size())
	var cleared_cells: Array = []
	for i in range(to_clear):
		var cell: Vector2i = _to_vec2i(filled_cells[i])
		revived_board[cell.y][cell.x] = 0
		cleared_cells.append(cell)
	return {"board": revived_board, "cleared": to_clear, "cells": cleared_cells}

static func score_for_move(placed_cells: int, cleared_lines: int, combo_streak: int) -> Dictionary:
	var line_bonus: int = max(0, cleared_lines) * 50
	var combo_bonus: int = 0
	if cleared_lines > 0:
		combo_bonus = max(0, combo_streak) * 25
	var total: int = max(0, placed_cells) + line_bonus + combo_bonus
	return {
		"placed": max(0, placed_cells),
		"line_bonus": line_bonus,
		"combo_bonus": combo_bonus,
		"total": total,
	}

static func _copy_board(board: Array) -> Array:
	var copy: Array = []
	for row_variant in board:
		if not (row_variant is Array):
			continue
		var source_row: Array = row_variant
		var row: Array = []
		for cell_variant in source_row:
			row.append(int(cell_variant))
		copy.append(row)
	return copy

static func _collect_filled_cells(board: Array) -> Array:
	var filled: Array = []
	for y in range(board.size()):
		var row: Array = board[y]
		for x in range(row.size()):
			if int(row[x]) != 0:
				filled.append(Vector2i(x, y))
	return filled

static func _to_vec2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		var v: Vector2 = value
		return Vector2i(int(v.x), int(v.y))
	if value is Dictionary:
		return Vector2i(int(value.get("x", 0)), int(value.get("y", 0)))
	return Vector2i.ZERO
