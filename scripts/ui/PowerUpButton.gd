extends Button

@export var powerup_type: String = "bomb"

var _owned: bool = false
var _count: int = 0
var _icon: TextureRect = null
var _count_label: Label = null
var _cooldown_timer: Timer = null
var _on_cooldown: bool = false

func _ready():
	setup_ui()
	GameManager.coins_changed.connect(_update_affordability)
	_update_ownership()

func setup_ui():
	custom_minimum_size = Vector2(70, 70)
	
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(48, 48)
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_icon)
	
	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_count_label.theme_override_font_sizes/font_size = 14
	_count_label.theme_override_colors/font_color = Color(1, 1, 1, 1)
	_count_label.theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
	_count_label.theme_override_constants/outline_size = 2
	_count_label.custom_minimum_size = Vector2(70, 70)
	add_child(_count_label)
	
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_on_cooldown_finished)
	add_child(_cooldown_timer)
	
	pressed.connect(_on_pressed)
	
	_set_icon()

func _set_icon():
	var icons = {
		"bomb": "res://assets/ui/powerup_bomb.png",
		"shuffle": "res://assets/ui/powerup_shuffle.png",
		"undo": "res://assets/ui/powerup_undo.png",
		"color_clear": "res://assets/ui/powerup_colorclear.png"
	}
	
	if icons.has(powerup_type) and ResourceLoader.exists(icons[powerup_type]):
		_icon.texture = load(icons[powerup_type])
	else:
		var colors = {"bomb": Color(1, 0.3, 0.3), "shuffle": Color(0.3, 1, 0.5), "undo": Color(0.5, 0.5, 1), "color_clear": Color(1, 0.5, 1)}
		_icon.color = colors.get(powerup_type, Color(1, 1, 1))

func _update_ownership():
	_owned = GameManager.owned_powerups.has(powerup_type)
	_count = SaveManager.get_data("powerup_%s_count" % powerup_type, 0)
	_update_count_label()
	_update_affordability()

func _update_count_label():
	if _count > 0:
		_count_label.text = "x%d" % _count
	else:
		_count_label.text = ""

func _update_affordability(_coins: int = 0):
	var can_afford = _owned or GameManager.coins >= _get_price()
	disabled = _on_cooldown or not can_afford or not _owned and _count <= 0
	
	if _on_cooldown:
		modulate = Color(0.5, 0.5, 0.5, 0.7)
	elif not _owned and _count <= 0:
		modulate = Color(0.7, 0.7, 0.7, 0.5)
	else:
		modulate = Color(1, 1, 1, 1)

func _get_price() -> int:
	match powerup_type:
		"bomb": return 200
		"shuffle": return 150
		"undo": return 100
		"color_clear": return 300
	return 100

func _on_pressed():
	if _on_cooldown:
		AudioManager.play_sfx("error")
		return
	
	if not _owned:
		if GameManager.coins >= _get_price():
			if GameManager.spend_coins(_get_price()):
				_owned = true
				GameManager.owned_powerups[powerup_type] = true
				_count = 1
				GameManager.save_game()
				_update_ownership()
			else:
				AudioManager.play_sfx("error")
				return
		else:
			AudioManager.play_sfx("error")
			return
	
	if _count <= 0:
		AudioManager.play_sfx("error")
		return
	
	_use_powerup()

func _use_powerup():
	var game_scene = get_tree().get_root().get_node_or_null("GameScene")
	if not game_scene:
		return
	
	var success = false
	match powerup_type:
		"bomb":
			success = game_scene.use_bomb()
		"shuffle":
			success = game_scene.use_shuffle()
		"undo":
			success = game_scene.use_undo()
		"color_clear":
			success = game_scene.use_color_clear()
	
	if success:
		_count -= 1
		GameManager.powerup_uses[powerup_type] += 1
		SaveManager.set_data("powerup_%s_count" % powerup_type, _count)
		_update_count_label()
		_start_cooldown()
		AudioManager.play_sfx("powerup")
	else:
		AudioManager.play_sfx("error")

func _start_cooldown():
	_on_cooldown = true
	_cooldown_timer.start(5.0)
	_update_affordability()

func _on_cooldown_finished():
	_on_cooldown = false
	_update_affordability()

func add_count(amount: int):
	_count += amount
	SaveManager.set_data("powerup_%s_count" % powerup_type, _count)
	_update_count_label()
	_update_affordability()

func get_count() -> int:
	return _count

func is_owned() -> bool:
	return _owned