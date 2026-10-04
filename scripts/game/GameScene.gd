extends Node2D

@onready var grid: Grid = %Grid
@onready var next_block_previews: Array[BlockPreview] = [
	%BlockPreview, %BlockPreview2, %BlockPreview3
]
@onready var score_label: Label = %ScoreLabel
@onready var high_score_label: Label = %HighScoreLabel
@onready var level_label: Label = %LevelLabel
@onready var coins_label: Label = %CoinsLabel
@onready var lives_label: Label = %LivesLabel
@onready var combo_label: Label = %ComboDisplay
@onready var game_over_overlay: ColorRect = %GameOverOverlay
@onready var final_score_label: Label = %FinalScoreLabel
@onready var best_score_label: Label = %BestScoreLabel
@onready var coins_earned_label: Label = %CoinsEarnedLabel
@onready var continue_button: Button = %ContinueButton
@onready var watch_ad_button: Button = %WatchAdButton
@onready var menu_button: Button = %MenuButton
@onready var retry_button: Button = %RetryButton
@onready var pause_overlay: ColorRect = %PauseOverlay
@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var pause_menu_button: Button = %PauseMenuButton
@onready var settings_button: Button = %SettingsButton
@onready var pause_button: TextureButton = %PauseButton
@onready var daily_reward_popup: ColorRect = %DailyRewardPopup
@onready var streak_label: Label = %StreakLabel
@onready var reward_items: VBoxContainer = %RewardItems
@onready var claim_button: Button = %ClaimButton
@onready var close_daily_button: Button = %CloseDailyButton

var current_blocks: Array[Array[Vector2i]] = []
var next_blocks_queue: Array[Array[Vector2i]] = []
var selected_block_index: int = -1
var dragged_block: Node = null
var drag_start_pos: Vector2
var ghost_blocks: Array[Node] = []
var can_place: bool = false
var game_active: bool = false
var lines_cleared_this_turn: int = 0
var coins_earned_this_game: int = 0
var powerup_uses: Dictionary = {"bomb": 0, "shuffle": 0, "undo": 0, "color_clear": 0}
var last_move_data: Dictionary = {}

const BLOCK_SHAPES = [
	[[Vector2i(0,0)]],
	[[Vector2i(0,0), Vector2i(1,0)]],
	[[Vector2i(0,0), Vector2i(0,1)]],
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)]],
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2)]],
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1)]],
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)]],
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)]],
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)]],
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1)]],
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)]],
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)]],
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1)]],
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(2,1)]],
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)]],
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(1,2)]],
]

const BLOCK_COLORS = [
	Color(0.2, 0.8, 1.0),
	Color(1.0, 0.4, 0.4),
	Color(1.0, 0.8, 0.2),
	Color(0.4, 1.0, 0.4),
	Color(0.9, 0.4, 1.0),
	Color(1.0, 0.6, 0.2),
	Color(0.4, 0.8, 1.0),
	Color(1.0, 0.3, 0.6),
]

func _ready():
	grid.cell_size = Vector2(40, 40)
	grid.grid_size = Vector2i(10, 10)
	grid.initialize_grid()
	
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.daily_reward_ready.connect(_show_daily_reward)
	SaveManager.load_game.connect(_on_game_loaded)
	
	_grid_setup_signals()
	_setup_buttons()
	_generate_next_blocks()
	_update_ui()
	
	if GameManager.current_state == GameManager.GameState.PLAYING:
		_start_game()

func _grid_setup_signals():
	grid.cell_clicked.connect(_on_cell_clicked)
	grid.cell_hovered.connect(_on_cell_hovered)
	grid.hover_ended.connect(_on_hover_ended)

func _setup_buttons():
	continue_button.pressed.connect(_on_continue_pressed)
	watch_ad_button.pressed.connect(_on_watch_ad_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	pause_menu_button.pressed.connect(_on_menu_pressed)
	settings_button.pressed.connect(_open_settings)
	pause_button.pressed.connect(_on_pause_pressed)
	claim_button.pressed.connect(_on_claim_daily)
	close_daily_button.pressed.connect(_hide_daily_reward)
	
	for i, preview in enumerate(next_block_previews):
		preview.gui_input.connect(_on_preview_gui_input.bind(i))

func _on_game_state_changed(state):
	match state:
		GameManager.GameState.PLAYING:
			if not game_active:
				_start_game()
		GameManager.GameState.PAUSED:
			_pause_game()
		GameManager.GameState.GAME_OVER:
			_game_over()
		GameManager.GameState.MAIN_MENU:
			_return_to_menu()

func _on_game_loaded(data):
	_update_ui()
	if GameManager.current_state == GameManager.GameState.PLAYING:
		_start_game()

func _start_game():
	game_active = true
	grid.clear_grid()
	current_blocks = []
	next_blocks_queue = []
	selected_block_index = -1
	lines_cleared_this_turn = 0
	coins_earned_this_game = 0
	powerup_uses = {"bomb": 0, "shuffle": 0, "undo": 0, "color_clear": 0}
	last_move_data = {}
	
	_generate_next_blocks()
	_fill_current_blocks()
	_update_ui()
	game_over_overlay.hide()
	pause_overlay.hide()

func _fill_current_blocks():
	while current_blocks.size() < 3 and next_blocks_queue.size() > 0:
		current_blocks.append(next_blocks_queue.pop_front())
		_generate_next_blocks()
	
	for i in range(3):
		if i < current_blocks.size():
			next_block_previews[i].set_shape(current_blocks[i])
		else:
			next_block_previews[i].clear()

func _generate_next_blocks():
	while next_blocks_queue.size() < 6:
		var shape = BLOCK_SHAPES.pick_random()
		var color = BLOCK_COLORS.pick_random()
		next_blocks_queue.append({"shape": shape, "color": color})

func _on_preview_gui_input(event, index):
	if not game_active or GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if index < current_blocks.size():
			_select_block(index)

func _select_block(index: int):
	selected_block_index = index
	AudioManager.play_sfx("click")

func _on_cell_clicked(cell_pos: Vector2i):
	if not game_active or selected_block_index == -1:
		return
	
	if _try_place_block(cell_pos):
		_place_block(cell_pos)
		_check_lines()
		_check_game_over()
	else:
		AudioManager.play_sfx("error", 0.8)

func _on_cell_hovered(cell_pos: Vector2i):
	if not game_active or selected_block_index == -1:
		return
	
	var shape = current_blocks[selected_block_index]["shape"]
	can_place = grid.can_place_shape(cell_pos, shape)
	_show_ghost(cell_pos, shape, can_place)

func _on_hover_ended():
	_hide_ghost()

func _try_place_block(pos: Vector2i) -> bool:
	var block_data = current_blocks[selected_block_index]
	return grid.can_place_shape(pos, block_data["shape"])

func _place_block(pos: Vector2i):
	var block_data = current_blocks[selected_block_index]
	var shape = block_data["shape"]
	var color = block_data["color"]
	
	last_move_data = {
		"pos": pos,
		"shape": shape,
		"color": color,
		"index": selected_block_index,
		"grid_state": grid.get_grid_state()
	}
	
	grid.place_shape(pos, shape, color)
	current_blocks.remove_at(selected_block_index)
	selected_block_index = -1
	
	AudioManager.play_sfx("place_block")
	_fill_current_blocks()
	
	GameManager.add_score(10 * (GameManager.current_combo + 1))
	GameManager.current_combo += 1
	if GameManager.current_combo > GameManager.best_combo:
		GameManager.best_combo = GameManager.current_combo
	GameManager.multiplier = min(1.0 + GameManager.current_combo * 0.2, GameManager.MAX_COMBO_MULTIPLIER)
	
	if GameManager.current_combo >= 2:
		_show_combo()
		AudioManager.play_sfx("combo", 1.0 + GameManager.current_combo * 0.1)
	
	coins_earned_this_game += 1
	if coins_earned_this_game % 50 == 0:
		GameManager.add_coins(1)

func _check_lines():
	var cleared = grid.check_and_clear_lines()
	lines_cleared_this_turn = cleared.size()
	
	if lines_cleared_this_turn > 0:
		GameManager.total_lines_cleared += lines_cleared_this_turn
		var points = lines_cleared_this_turn * 100 * GameManager.multiplier
		GameManager.add_score(int(points))
		GameManager.add_coins(lines_cleared_this_turn * 5)
		coins_earned_this_game += lines_cleared_this_turn * 5
		LeaderboardManager.add_to_weekly_score(int(points))
		LeaderboardManager.add_to_daily_score(int(points))
		
		AudioManager.play_sfx("line_clear")
		_show_clear_effect(cleared)
		
		if GameManager.current_combo == 0:
			GameManager.current_combo = 1
	else:
		GameManager.current_combo = 0
		GameManager.multiplier = 1.0
		_hide_combo()

func _check_game_over():
	if current_blocks.size() == 0:
		_fill_current_blocks()
	
	var can_place_any = false
	for block_data in current_blocks:
		if grid.can_place_any_shape(block_data["shape"]):
			can_place_any = true
			break
	
	if not can_place_any:
		_game_over()

func _game_over():
	game_active = false
	game_over_overlay.show()
	final_score_label.text = "Pontuação: %d" % GameManager.score
	best_score_label.text = "Recorde: %d" % GameManager.high_score
	
	var coins_earned = 10 + GameManager.current_level * 2 + coins_earned_this_game
	coins_earned_label.text = "+%d moedas" % coins_earned
	
	continue_button.disabled = GameManager.coins < 100 and GameManager.lives <= 0
	watch_ad_button.visible = not GameManager.has_no_ads
	
	AudioManager.play_music("game_over")
	AudioManager.play_sfx("life_lost")
	
	GameManager.end_game()

func _on_continue_pressed():
	if GameManager.coins >= 100:
		GameManager.spend_coins(100)
		_continue_game()
	elif GameManager.lives > 0:
		GameManager.lose_life()
		_continue_game()
	else:
		AudioManager.play_sfx("error")

func _continue_game():
	game_over_overlay.hide()
	GameManager.set_state(GameManager.GameState.PLAYING)
	_start_game()

func _on_watch_ad_pressed():
	MonetizationManager.show_rewarded_ad("continue", 1)

func _on_retry_pressed():
	if GameManager.lose_life():
		game_over_overlay.hide()
		GameManager.set_state(GameManager.GameState.PLAYING)
		_start_game()
	else:
		AudioManager.play_sfx("error")

func _on_menu_pressed():
	game_over_overlay.hide()
	pause_overlay.hide()
	GameManager.set_state(GameManager.GameState.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")

func _on_pause_pressed():
	if game_active:
		GameManager.set_state(GameManager.GameState.PAUSED)

func _pause_game():
	pause_overlay.show()
	game_active = false
	AudioManager.play_sfx("click")

func _on_resume_pressed():
	pause_overlay.hide()
	game_active = true
	GameManager.set_state(GameManager.GameState.PLAYING)
	AudioManager.play_sfx("click")

func _on_restart_pressed():
	if GameManager.lose_life():
		pause_overlay.hide()
		GameManager.set_state(GameManager.GameState.PLAYING)
		_start_game()
	else:
		AudioManager.play_sfx("error")

func _open_settings():
	get_tree().change_scene_to_file("res://scenes/menus/SettingsMenu.tscn")

func _show_combo():
	combo_label.text = "COMBO x%d!" % GameManager.current_combo
	combo_label.show()
	combo_label.modulate = Color(1, 1, 1, 1)
	var tween = create_tween()
	tween.tween_property(combo_label, "modulate:a", 0.3, 0.3).set_loops(4).set_trans(Tween.TRANS_SINE)

func _hide_combo():
	var tween = create_tween()
	tween.tween_property(combo_label, "modulate:a", 0, 0.3)
	tween.finished.connect(combo_label.hide)

func _show_ghost(pos: Vector2i, shape: Array[Vector2i], valid: bool):
	_hide_ghost()
	var color = Color(1, 1, 1, 0.3) if valid else Color(1, 0.3, 0.3, 0.3)
	
	for cell in shape:
		var ghost = ColorRect.new()
		ghost.color = color
		ghost.custom_minimum_size = grid.cell_size
		grid.add_child(ghost)
		ghost.position = grid.map_to_local(pos + cell) + grid.cell_size * 0.5
		ghost.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		ghost_blocks.append(ghost)

func _hide_ghost():
	for ghost in ghost_blocks:
		ghost.queue_free()
	ghost_blocks.clear()

func _show_clear_effect(cleared_lines: Array):
	for line_data in cleared_lines:
		var line_type = line_data.type
		var index = line_data.index
		
		var effect = ColorRect.new()
		effect.color = Color(1, 1, 1, 0.5)
		effect.custom_minimum_size = Vector2(grid.grid_size.x * grid.cell_size.x, grid.cell_size.y) if line_type == "row" else Vector2(grid.cell_size.x, grid.grid_size.y * grid.cell_size.y)
		grid.add_child(effect)
		
		var pos = grid.map_to_local(Vector2i(0, index)) if line_type == "row" else grid.map_to_local(Vector2i(index, 0))
		effect.position = pos + effect.custom_minimum_size * 0.5
		effect.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		
		var tween = create_tween()
		tween.tween_property(effect, "modulate:a", 0, 0.3)
		tween.tween_property(effect, "scale", Vector2(1.2, 1.2), 0.3)
		tween.finished.connect(effect.queue_free)

func _on_score_changed(score):
	score_label.text = str(score)
	high_score_label.text = "Best: %d" % GameManager.high_score

func _on_coins_changed(coins):
	coins_label.text = str(coins)

func _on_lives_changed(lives):
	lives_label.text = "%d/%d" % [lives, GameManager.max_lives]

func _on_level_changed(level):
	level_label.text = "Nv. %d" % level

func _update_ui():
	score_label.text = str(GameManager.score)
	high_score_label.text = "Best: %d" % GameManager.high_score
	level_label.text = "Nv. %d" % GameManager.current_level
	coins_label.text = str(GameManager.coins)
	lives_label.text = "%d/%d" % [GameManager.lives, GameManager.max_lives]

func _show_daily_reward():
	daily_reward_popup.show()
	streak_label.text = "Sequência: %d %s" % [GameManager.daily_streak + 1, "dia" if GameManager.daily_streak == 0 else "dias"]
	
	for child in reward_items.get_children():
		child.queue_free()
	
	var reward = GameManager.claim_daily_reward()
	if reward:
		var coins_item = HBoxContainer.new()
		coins_item.add_child(Label.new().set_text("💰 %d moedas" % reward.coins))
		reward_items.add_child(coins_item)
		
		if reward.lives > 0:
			var lives_item = HBoxContainer.new()
			lives_item.add_child(Label.new().set_text("❤️ %d %s" % [reward.lives, "vida" if reward.lives == 1 else "vidas"]))
			reward_items.add_child(lives_item)

func _on_claim_daily():
	AudioManager.play_sfx("daily_reward")
	_update_ui()
	_hide_daily_reward()

func _hide_daily_reward():
	daily_reward_popup.hide()

func _return_to_menu():
	game_active = false
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")

func _process(delta):
	if game_active:
		GameManager.recover_life_over_time()

func use_bomb() -> bool:
	var cleared = grid.check_and_clear_lines()
	if cleared.size() > 0:
		return true
	
	var center_x = grid.grid_size.x // 2
	var center_y = grid.grid_size.y // 2
	var radius = 2
	var any_cleared = false
	
	for x in range(grid.grid_size.x):
		for y in range(grid.grid_size.y):
			var dist = Vector2(x - center_x, y - center_y).length()
			if dist <= radius and grid.grid_data[x][y]["filled"]:
				grid.grid_data[x][y] = {"filled": false, "color": Color(1,1,1,1)}
				grid._update_cell_visual(Vector2i(x, y))
				any_cleared = true
	
	if any_cleared:
		GameManager.add_score(200)
		AudioManager.play_sfx("powerup")
		return true
	return false

func use_shuffle() -> bool:
	var filled_cells = []
	for x in range(grid.grid_size.x):
		for y in range(grid.grid_size.y):
			if grid.grid_data[x][y]["filled"]:
				filled_cells.append({"pos": Vector2i(x, y), "color": grid.grid_data[x][y]["color"]})
	
	if filled_cells.is_empty():
		return false
	
	grid.clear_grid()
	filled_cells.shuffle()
	
	var empty_positions = []
	for x in range(grid.grid_size.x):
		for y in range(grid.grid_size.y):
			empty_positions.append(Vector2i(x, y))
	empty_positions.shuffle()
	
	for i, cell_data in enumerate(filled_cells):
		if i < empty_positions.size():
			var pos = empty_positions[i]
			grid.grid_data[pos.x][pos.y] = {"filled": true, "color": cell_data["color"]}
			grid._update_cell_visual(pos)
	
	AudioManager.play_sfx("powerup")
	return true

func use_undo() -> bool:
	if GameManager.last_move_data.is_empty():
		return false
	
	var last = GameManager.last_move_data
	grid.restore_grid_state(last["grid_state"])
	
	if last["index"] >= 0 and last["index"] <= current_blocks.size():
		current_blocks.insert(last["index"], {"shape": last["shape"], "color": last["color"]})
	else:
		current_blocks.append({"shape": last["shape"], "color": last["color"]})
	
	_fill_current_blocks()
	GameManager.last_move_data = {}
	AudioManager.play_sfx("powerup")
	return true

func use_color_clear() -> bool:
	var color_counts: Dictionary = {}
	for x in range(grid.grid_size.x):
		for y in range(grid.grid_size.y):
			if grid.grid_data[x][y]["filled"]:
				var c = grid.grid_data[x][y]["color"]
				var key = "%f,%f,%f" % [c.r, c.g, c.b]
				if not color_counts.has(key):
					color_counts[key] = {"color": c, "count": 0, "cells": []}
				color_counts[key]["count"] += 1
				color_counts[key]["cells"].append(Vector2i(x, y))
	
	if color_counts.is_empty():
		return false
	
	var most_common = ""
	var max_count = 0
	for key in color_counts:
		if color_counts[key]["count"] > max_count:
			max_count = color_counts[key]["count"]
			most_common = key
	
	if max_count == 0:
		return false
	
	var target_color = color_counts[most_common]["color"]
	var cells_to_clear = color_counts[most_common]["cells"]
	
	for pos in cells_to_clear:
		grid.grid_data[pos.x][pos.y] = {"filled": false, "color": Color(1,1,1,1)}
		grid._update_cell_visual(pos)
	
	GameManager.add_score(max_count * 50)
	AudioManager.play_sfx("powerup")
	return true

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if game_active and not game_over_overlay.visible:
			_on_pause_pressed()
		elif pause_overlay.visible:
			_on_resume_pressed()