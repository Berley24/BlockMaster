extends Control

@onready var back_button: Button = %BackButton
@onready var tab_global: TabButton = %TabGlobal
@onready var tab_weekly: TabButton = %TabWeekly
@onready var tab_daily: TabButton = %TabDaily
@onready var tab_friends: TabButton = %TabFriends
@onready var player_name: Label = %PlayerName
@onready var player_score: Label = %PlayerScore
@onready var player_rank: Label = %PlayerRank
@onready var player_league: TextureRect = %PlayerLeague
@onready var leaderboard_list: VBoxContainer = %LeaderboardList
@onready var refresh_button: Button = %RefreshButton

var _current_tab: int = 0
var _leaderboard_data: Array = []

func _ready():
	LeaderboardManager.leaderboard_loaded.connect(_on_leaderboard_loaded)
	LeaderboardManager.friends_loaded.connect(_on_friends_loaded)
	GameManager.score_changed.connect(_update_player_info)
	GameManager.league_changed.connect(_update_player_info)
	
	_setup_tabs()
	_setup_buttons()
	_update_player_info()
	_show_tab(0)

func _setup_tabs():
	tab_global.pressed.connect(_on_tab_pressed.bind(0))
	tab_weekly.pressed.connect(_on_tab_pressed.bind(1))
	tab_daily.pressed.connect(_on_tab_pressed.bind(2))
	tab_friends.pressed.connect(_on_tab_pressed.bind(3))

func _setup_buttons():
	back_button.pressed.connect(_on_back_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)

func _on_tab_pressed(tab_index: int):
	_show_tab(tab_index)
	AudioManager.play_sfx("click")

func _show_tab(index: int):
	_current_tab = index
	
	var tabs = [tab_global, tab_weekly, tab_daily, tab_friends]
	for i, tab in enumerate(tabs):
		tab.button_pressed = i == index
	
	_clear_leaderboard()
	
	match index:
		0:
			LeaderboardManager.load_leaderboard("high_score")
		1:
			LeaderboardManager.load_leaderboard("weekly")
		2:
			LeaderboardManager.load_leaderboard("daily")
		3:
			LeaderboardManager.load_friends()

func _on_back_pressed():
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")

func _on_refresh_pressed():
	_show_tab(_current_tab)
	AudioManager.play_sfx("click")

func _update_player_info(_score: int = 0):
	player_name.text = "Você"
	player_score.text = "Pontuação: %d" % GameManager.high_score
	player_rank.text = "Rank: #%d" % LeaderboardManager.get_player_rank("high_score")
	player_league.texture = load(GameManager.get_league_icon()) if ResourceLoader.exists(GameManager.get_league_icon()) else null

func _on_leaderboard_loaded(data: Array):
	_leaderboard_data = data
	_populate_leaderboard(data)

func _on_friends_loaded(friends: Array):
	_populate_leaderboard(friends)

func _populate_leaderboard(data: Array):
	_clear_leaderboard()
	
	for i, entry in enumerate(data):
		var item = LeaderboardEntry.new()
		item.setup(entry, i + 1, entry.get("is_player", false))
		leaderboard_list.add_child(item)

func _clear_leaderboard():
	for child in leaderboard_list.get_children():
		child.queue_free()