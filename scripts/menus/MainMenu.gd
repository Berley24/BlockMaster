extends Control

@onready var play_button: AnimatedButton = %PlayButton
@onready var daily_button: AnimatedButton = %DailyButton
@onready var shop_button: AnimatedButton = %ShopButton
@onready var leaderboard_button: AnimatedButton = %LeaderboardButton
@onready var settings_button: AnimatedButton = %SettingsButton
@onready var coins_label: Label = %CoinsLabel
@onready var lives_label: Label = %LivesLabel
@onready var league_icon: TextureRect = %LeagueIcon
@onready var league_name: Label = %LeagueName
@onready var league_progress: ProgressBar = %LeagueProgress
@onready var no_ads_badge: TextureButton = %NoAdsBadge
@onready var daily_reward_popup: ColorRect = %DailyRewardPopup
@onready var streak_label: Label = %StreakLabel
@onready var reward_items: VBoxContainer = %RewardItems
@onready var claim_button: AnimatedButton = %ClaimButton
@onready var close_daily_button: Button = %CloseDailyButton

func _ready():
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.league_changed.connect(_on_league_changed)
	GameManager.daily_reward_ready.connect(_show_daily_reward)
	SaveManager.load_game.connect(_on_game_loaded)
	
	_setup_buttons()
	_update_ui()
	_check_daily_reward()
	_check_no_ads_badge()
	
	AudioManager.play_music("menu")
	NotificationManager.schedule_daily_reward_notification()

func _setup_buttons():
	play_button.pressed.connect(_on_play_pressed)
	daily_button.pressed.connect(_show_daily_reward)
	shop_button.pressed.connect(_open_shop)
	leaderboard_button.pressed.connect(_open_leaderboard)
	settings_button.pressed.connect(_open_settings)
	claim_button.pressed.connect(_on_claim_daily)
	close_daily_button.pressed.connect(_hide_daily_reward)
	no_ads_badge.pressed.connect(_open_shop)

func _on_game_state_changed(state):
	if state == GameManager.GameState.MAIN_MENU:
		_update_ui()
		_check_daily_reward()
		_check_no_ads_badge()
		AudioManager.play_music("menu")

func _on_game_loaded(data):
	_update_ui()
	_check_daily_reward()
	_check_no_ads_badge()

func _on_play_pressed():
	AudioManager.play_sfx("click")
	GameManager.start_new_game()
	get_tree().change_scene_to_file("res://scenes/game/GameScene.tscn")

func _open_shop():
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/menus/ShopMenu.tscn")

func _open_leaderboard():
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/menus/LeaderboardMenu.tscn")

func _open_settings():
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/menus/SettingsMenu.tscn")

func _on_coins_changed(coins):
	coins_label.text = str(coins)

func _on_lives_changed(lives):
	lives_label.text = "%d/%d" % [lives, GameManager.max_lives]

func _on_league_changed(league):
	_update_league_ui()

func _update_ui():
	coins_label.text = str(GameManager.coins)
	lives_label.text = "%d/%d" % [GameManager.lives, GameManager.max_lives]
	_update_league_ui()

func _update_league_ui():
	league_name.text = GameManager.get_league_name()
	
	var threshold = GameManager.get_next_league_threshold()
	if threshold > 0:
		var progress = (GameManager.high_score / threshold) * 100
		league_progress.value = min(progress, 100)
	else:
		league_progress.value = 100

func _check_no_ads_badge():
	no_ads_badge.visible = not GameManager.has_no_ads

func _check_daily_reward():
	var now = Time.get_unix_time_from_system()
	var today = Time.get_datetime_dict_from_system()["day"]
	var last_claim_day = Time.get_datetime_dict_from_unix_time(GameManager.last_daily_claim)["day"]
	
	daily_button.visible = true
	if today != last_claim_day or GameManager.last_daily_claim == 0:
		daily_button.text = "🎁 RECOMPENSA DIÁRIA DISPONÍVEL!"
		daily_button.modulate = Color(1, 0.9, 0.3, 1)
	else:
		daily_button.text = "🎁 Recompensa Diária"
		daily_button.modulate = Color(1, 1, 1, 1)

func _show_daily_reward():
	daily_reward_popup.show()
	streak_label.text = "Sequência: %d %s" % [GameManager.daily_streak + 1, "dia" if GameManager.daily_streak == 0 else "dias"]
	
	for child in reward_items.get_children():
		child.queue_free()
	
	var reward_coins = 50 + GameManager.daily_streak * 10
	var reward_lives = min(1 + GameManager.daily_streak // 7, 3)
	
	var coins_item = HBoxContainer.new()
	coins_item.theme_override_constants/separation = 10
	var coin_icon = TextureRect.new()
	coin_icon.custom_minimum_size = Vector2(32, 32)
	coins_item.add_child(coin_icon)
	var coins_text = Label.new()
	coins_text.text = "💰 %d moedas" % reward_coins
	coins_text.vertical_alignment = 1
	coins_text.theme_override_font_sizes/font_size = 22
	coins_item.add_child(coins_text)
	reward_items.add_child(coins_item)
	
	if reward_lives > 0:
		var lives_item = HBoxContainer.new()
		lives_item.theme_override_constants/separation = 10
		var heart_icon = TextureRect.new()
		heart_icon.custom_minimum_size = Vector2(32, 32)
		lives_item.add_child(heart_icon)
		var lives_text = Label.new()
		lives_text.text = "❤️ %d %s" % [reward_lives, "vida" if reward_lives == 1 else "vidas"]
		lives_text.vertical_alignment = 1
		lives_text.theme_override_font_sizes/font_size = 22
		lives_item.add_child(lives_text)
		reward_items.add_child(lives_item)

func _on_claim_daily():
	var reward = GameManager.claim_daily_reward()
	if reward:
		AudioManager.play_sfx("daily_reward")
		_update_ui()
		_check_daily_reward()
	_hide_daily_reward()

func _hide_daily_reward():
	daily_reward_popup.hide()