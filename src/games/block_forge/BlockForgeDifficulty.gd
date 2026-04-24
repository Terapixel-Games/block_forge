extends RefCounted

static func board_fill_ratio(board: Array) -> float:
    if board.is_empty():
        return 0.0
    var filled: int = 0
    var total: int = 0
    for row_variant in board:
        if not (row_variant is Array):
            continue
        var row: Array = row_variant
        total += row.size()
        for cell in row:
            if int(cell) != 0:
                filled += 1
    if total <= 0:
        return 0.0
    return clampf(float(filled) / float(total), 0.0, 1.0)

static func pressure_level(board: Array, turns_without_clear: int) -> int:
    var pressure: int = 0
    var fill: float = board_fill_ratio(board)
    if fill >= 0.45:
        pressure += 1
    if fill >= 0.62:
        pressure += 1
    if fill >= 0.76:
        pressure += 1
    if turns_without_clear >= 2:
        pressure += 1
    return clampi(pressure, 0, 3)

static func max_piece_cells_for_pressure(pressure: int) -> int:
    match clampi(pressure, 0, 3):
        0:
            return 8
        1:
            return 6
        2:
            return 4
        _:
            return 3

static func should_force_lifeline(pressure: int, turns_without_clear: int) -> bool:
    return pressure >= 2 or turns_without_clear >= 3
