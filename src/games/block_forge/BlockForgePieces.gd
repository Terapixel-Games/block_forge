extends RefCounted

const PIECE_LIBRARY: Array = [
	{"id": "single", "cells": [Vector2i(0, 0)]},
	{"id": "line_2_h", "cells": [Vector2i(0, 0), Vector2i(1, 0)]},
	{"id": "line_2_v", "cells": [Vector2i(0, 0), Vector2i(0, 1)]},
	{"id": "line_3_h", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]},
	{"id": "line_3_v", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]},
	{"id": "line_4_h", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]},
	{"id": "line_4_v", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)]},
	{"id": "square_2", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]},
	{"id": "l_3_a", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]},
	{"id": "l_3_b", "cells": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]},
	{"id": "l_3_c", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]},
	{"id": "l_3_d", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)]},
	{
		"id": "square_3_hole",
		"cells": [
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
			Vector2i(0, 1), Vector2i(2, 1),
			Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		]
	},
]

static func random_piece(rng: RandomNumberGenerator) -> Dictionary:
	return _clone_piece(PIECE_LIBRARY[rng.randi_range(0, PIECE_LIBRARY.size() - 1)])

static func piece_by_id(id: String) -> Dictionary:
	for piece in PIECE_LIBRARY:
		if str(piece.get("id", "")) == id:
			return _clone_piece(piece)
	return _clone_piece(PIECE_LIBRARY[0])

static func bounds(piece: Dictionary) -> Vector2i:
	var max_x: int = 0
	var max_y: int = 0
	for cell_variant in piece.get("cells", []):
		var cell: Vector2i = _to_vec2i(cell_variant)
		max_x = max(max_x, cell.x)
		max_y = max(max_y, cell.y)
	return Vector2i(max_x + 1, max_y + 1)

static func _clone_piece(piece: Dictionary) -> Dictionary:
	var cells_copy: Array = []
	for cell_variant in piece.get("cells", []):
		var cell: Vector2i = _to_vec2i(cell_variant)
		cells_copy.append(Vector2i(cell.x, cell.y))
	return {"id": str(piece.get("id", "piece")), "cells": cells_copy}

static func _to_vec2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		var v: Vector2 = value
		return Vector2i(int(v.x), int(v.y))
	if value is Dictionary:
		return Vector2i(int(value.get("x", 0)), int(value.get("y", 0)))
	return Vector2i.ZERO
