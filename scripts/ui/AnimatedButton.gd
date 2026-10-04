extends Button

@export var hover_scale: float = 1.05
@export var press_scale: float = 0.95
@export var animation_speed: float = 0.1

var _base_modulate: Color = Color(1, 1, 1, 1)
var _hover_tween: Tween = null
var _press_tween: Tween = null

func _ready():
	_base_modulate = modulate
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func _on_mouse_entered():
	if disabled:
		return
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_BACK)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", Vector2(hover_scale, hover_scale), animation_speed)
	_hover_tween.tween_property(self, "modulate", Color(1.1, 1.1, 1.1, 1), animation_speed)

func _on_mouse_exited():
	if disabled:
		return
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_QUAD)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", Vector2(1, 1), animation_speed)
	_hover_tween.tween_property(self, "modulate", _base_modulate, animation_speed)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_tween = create_tween()
			_press_tween.set_trans(Tween.TRANS_QUAD)
			_press_tween.tween_property(self, "scale", Vector2(press_scale, press_scale), 0.05)
		else:
			if _press_tween and _press_tween.is_running():
				_press_tween.kill()
			
			_press_tween = create_tween()
			_press_tween.set_trans(Tween.TRANS_BACK)
			_press_tween.set_ease(Tween.EASE_OUT)
			_press_tween.tween_property(self, "scale", Vector2(hover_scale, hover_scale) if get_rect().has_point(get_local_mouse_position()) else Vector2(1, 1), 0.1)

func set_base_color(color: Color):
	_base_modulate = color
	if not disabled:
		modulate = color