extends Node2D

signal cell_clicked(position: Vector2i)
signal cell_hovered(position: Vector2i)
signal hover_ended()

@export var cell_size: Vector2 = Vector2(40, 40)
@export var grid_size: Vector2i = Vector2i(10, 10)

var grid_data: Array[Array[Dictionary]] = []
var cell_nodes: Array[Array[Node]] = []
var _hovered_cell: Vector2i = Vector2i(-1, -1)

func _ready():
	initialize_grid()

func initialize_grid():
	grid_data.clear()
	cell_nodes.clear()
	
	for child in get_children():
		if child is Node2D and child.name.begins_with("Cell"):
			child.queue_free()
	
	for x in range(grid_size.x):
		grid_data.append([])
		cell_nodes.append([])
		for y in range(grid_size.y):
			grid_data[x].append({"filled": false, "color": Color(1,1,1,1)})
			
			var cell = PanelContainer.new()
			cell.name = "Cell_%d_%d" % [x, y]
			cell.custom_minimum_size = cell_size
			cell.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			cell.position = map_to_local(Vector2i(x, y)) + cell_size * 0.5
			cell.mouse_filter = Control.MOUSE_FILTER_PASS
			
			var bg = ColorRect.new()
			bg.color = Color(0.15, 0.15, 0.2, 1)
			cell.add_child(bg)
			
			var border = Panel.new()
			var stylebox = StyleBoxFlat.new()
			stylebox.border_color = Color(0.3, 0.3, 0.4, 1)
			stylebox.border_width = 1
			stylebox.corner_radius_top_left = 4
			stylebox.corner_radius_top_right = 4
			stylebox.corner_radius_bottom_left = 4
			stylebox.corner_radius_bottom_right = 4
			border.add_theme_stylebox_override("panel", stylebox)
			cell.add_child(border)
			
			add_child(cell)
			cell_nodes[x].append(cell)

func map_to_local(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * cell_size.x, grid_pos.y * cell_size.y)

func get_local_position(grid_pos: Vector2i) -> Vector2:
	return map_to_local(grid_pos) + cell_size * 0.5

func can_place_shape(pos: Vector2i, shape: Array[Vector2i]) -> bool:
	for cell in shape:
		var check_pos = pos + cell
		if check_pos.x < 0 or check_pos.x >= grid_size.x:
			return false
		if check_pos.y < 0 or check_pos.y >= grid_size.y:
			return false
		if grid_data[check_pos.x][check_pos.y]["filled"]:
			return false
	return true

func can_place_any_shape(shape: Array[Vector2i]) -> bool:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			if can_place_shape(Vector2i(x, y), shape):
				return true
	return false

func place_shape(pos: Vector2i, shape: Array[Vector2i], color: Color):
	for cell in shape:
		var grid_pos = pos + cell
		grid_data[grid_pos.x][grid_pos.y] = {"filled": true, "color": color}
		_update_cell_visual(grid_pos)

func _update_cell_visual(pos: Vector2i):
	var cell_data = grid_data[pos.x][pos.y]
	var cell_node = cell_nodes[pos.x][pos.y]
	
	if cell_node.get_child_count() > 1:
		var block = cell_node.get_child(1)
		if block:
			block.modulate = cell_data["color"] if cell_data["filled"] else Color(1,1,1,0)
	else:
		var block = ColorRect.new()
		block.color = cell_data["color"] if cell_data["filled"] else Color(1,1,1,0)
		block.custom_minimum_size = cell_size * 0.88
		block.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		cell_node.add_child(block)
	
	var block_node = cell_node.get_child(1) if cell_node.get_child_count() > 1 else null
	if block_node:
		if cell_data["filled"]:
			block_node.modulate = cell_data["color"]
			var tween = create_tween()
			tween.tween_property(block_node, "scale", Vector2(1.1, 1.1), 0.1)
			tween.tween_property(block_node, "scale", Vector2(1, 1), 0.1)
		else:
			block_node.modulate = Color(1,1,1,0)

func check_and_clear_lines() -> Array:
	var cleared = []
	
	for y in range(grid_size.y):
		var full = true
		for x in range(grid_size.x):
			if not grid_data[x][y]["filled"]:
				full = false
				break
		if full:
			cleared.append({"type": "row", "index": y})
	
	for x in range(grid_size.x):
		var full = true
		for y in range(grid_size.y):
			if not grid_data[x][y]["filled"]:
				full = false
				break
		if full:
			cleared.append({"type": "col", "index": x})
	
	for line in cleared:
		if line["type"] == "row":
			_clear_row(line["index"])
		else:
			_clear_col(line["index"])
	
	return cleared

func _clear_row(row: int):
	for x in range(grid_size.x):
		grid_data[x][row] = {"filled": false, "color": Color(1,1,1,1)}
		_update_cell_visual(Vector2i(x, row))

func _clear_col(col: int):
	for y in range(grid_size.y):
		grid_data[col][y] = {"filled": false, "color": Color(1,1,1,1)}
		_update_cell_visual(Vector2i(col, y))

func clear_grid():
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			grid_data[x][y] = {"filled": false, "color": Color(1,1,1,1)}
			_update_cell_visual(Vector2i(x, y))

func get_grid_state() -> Dictionary:
	var state = {}
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			if grid_data[x][y]["filled"]:
				state["%d,%d" % [x, y]] = grid_data[x][y]
	return state

func restore_grid_state(state: Dictionary):
	clear_grid()
	for key in state:
		var parts = key.split(",")
		var x = parts[0].to_int()
		var y = parts[1].to_int()
		grid_data[x][y] = state[key]
		_update_cell_visual(Vector2i(x, y))

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos = to_local(event.position)
		var grid_pos = Vector2i(int(local_pos.x / cell_size.x), int(local_pos.y / cell_size.y))
		
		if grid_pos.x >= 0 and grid_pos.x < grid_size.x and grid_pos.y >= 0 and grid_pos.y < grid_size.y:
			cell_clicked.emit(grid_pos)
	
	if event is InputEventMouseMotion:
		var local_pos = to_local(event.position)
		var grid_pos = Vector2i(int(local_pos.x / cell_size.x), int(local_pos.y / cell_size.y))
		
		if grid_pos != _hovered_cell:
			if _hovered_cell.x >= 0:
				hover_ended.emit()
			_hovered_cell = grid_pos
			if grid_pos.x >= 0 and grid_pos.x < grid_size.x and grid_pos.y >= 0 and grid_pos.y < grid_size.y:
				cell_hovered.emit(grid_pos)
	
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hovered_cell = Vector2i(-1, -1)
		hover_ended.emit()