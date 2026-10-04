extends PanelContainer

var current_shape: Array[Vector2i] = []
var current_color: Color = Color(1, 1, 1, 1)
var block_nodes: Array[Node] = []

func set_shape(block_data: Dictionary):
	clear()
	current_shape = block_data["shape"]
	current_color = block_data["color"]
	_draw_shape()

func _draw_shape():
	if current_shape.is_empty():
		return
	
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for cell in current_shape:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)
	
	var shape_width = max_x - min_x + 1
	var shape_height = max_y - min_y + 1
	
	var cell_size = 28.0
	var start_x = (100.0 - shape_width * cell_size) / 2.0
	var start_y = (100.0 - shape_height * cell_size) / 2.0
	
	for cell in current_shape:
		var block = ColorRect.new()
		block.color = current_color
		block.custom_minimum_size = Vector2(cell_size * 0.9, cell_size * 0.9)
		block.position = Vector2(start_x + (cell.x - min_x) * cell_size + cell_size * 0.5, 
								 start_y + (cell.y - min_y) * cell_size + cell_size * 0.5)
		block.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		add_child(block)
		block_nodes.append(block)
		
		var tween = create_tween()
		tween.tween_property(block, "scale", Vector2(1.1, 1.1), 0.1).set_delay(randf_range(0, 0.2))
		tween.tween_property(block, "scale", Vector2(1, 1), 0.1)

func clear():
	for block in block_nodes:
		block.queue_free()
	block_nodes.clear()
	current_shape = []
	current_color = Color(1, 1, 1, 1)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not current_shape.is_empty():
			get_viewport().gui_grab_click()