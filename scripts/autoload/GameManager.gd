extends Node

signal game_state_changed(state)
signal score_changed(score)
signal coins_changed(coins)
signal lives_changed(lives)
signal level_changed(level)
signal xp_changed(xp, level)
signal daily_reward_ready()
signal streak_changed(streak)
signal league_changed(league)

enum GameState { MAIN_MENU, PLAYING, PAUSED, GAME_OVER, LEVEL_COMPLETE, SHOP, LEADERBOARD, SETTINGS }

var current_state: GameState = GameState.MAIN_MENU
var score: int = 0
var high_score: int = 0
var coins: int = 0
var lives: int = 5
var max_lives: int = 5
var current_level: int = 1
var xp: int = 0
var level_xp_requirement: int = 100
var current_league: int = 0
var daily_streak: int = 0
var last_daily_claim: int = 0
var total_games_played: int = 0
var total_lines_cleared: int = 0
var best_combo: int = 0
var current_combo: int = 0
var multiplier: float = 1.0
var has_no_ads: bool = false
var no_ads_expiry: int = 0
var owned_powerups: Dictionary = {}
var equipped_powerup: String = ""
var tutorial_completed: bool = false
var first_launch: bool = true

const LEAGUES = ["Bronze", "Prata", "Ouro", "Platina", "Diamante", "Mestre", "GrÃ£o-Mestre"]
const LIVES_RECOVERY_TIME = 300
const MAX_COMBO_MULTIPLIER = 5.0
const XP_PER_LEVEL_BASE = 100

func _ready():
	SaveManager.load_game.connect(_on_game_loaded)
	SaveManager.load_game()
	MonetizationManager.purchase_completed.connect(_on_purchase_completed)
	MonetizationManager.ads_removed.connect(_on_ads_removed)
	NotificationManager.daily_notification_clicked.connect(_on_daily_notification)
	
	if first_launch:
		_first_launch_setup()
	
	# Show consent dialog if needed (after a short delay for UI to be ready)
	call_deferred("_check_consent")

func _first_launch_setup():
	first_launch = false
	coins = 500
	lives = max_lives
	_save_game()

func _on_game_loaded(data: Dictionary):
	score = data.get("score", 0)
	high_score = data.get("high_score", 0)
	coins = data.get("coins", 0)
	lives = data.get("lives", max_lives)
	max_lives = data.get("max_lives", 5)
	current_level = data.get("current_level", 1)
	xp = data.get("xp", 0)
	current_league = data.get("current_league", 0)
	daily_streak = data.get("daily_streak", 0)
	last_daily_claim = data.get("last_daily_claim", 0)
	total_games_played = data.get("total_games_played", 0)
	total_lines_cleared = data.get("total_lines_cleared", 0)
	best_combo = data.get("best_combo", 0)
	has_no_ads = data.get("has_no_ads", false)
	no_ads_expiry = data.get("no_ads_expiry", 0)
	owned_powerups = data.get("owned_powerups", {})
	equipped_powerup = data.get("equipped_powerup", "")
	tutorial_completed = data.get("tutorial_completed", false)
	first_launch = data.get("first_launch", true)
	
	_check_no_ads_expiry()
	_update_league()
	_check_daily_reward()
	_emit_all_signals()

func _check_consent():
	if not SaveManager.get_data("consent_given", false):
		var consent_dialog = load("res://scenes/ui/ConsentDialog.tscn").instantiate()
		get_tree().root.add_child(consent_dialog)
		consent_dialog.consent_given.connect(_on_consent_given)
		consent_dialog.show()

func _on_consent_given(personalized_ads: bool, analytics: bool, notifications: bool):
	print("Consent given: ads=", personalized_ads, " analytics=", analytics, " notifs=", notifications)
	if has_no_ads and no_ads_expiry > 0:
		var now = Time.get_unix_time_from_system()
		if now > no_ads_expiry:
			has_no_ads = false
			no_ads_expiry = 0
			_save_game()

func _update_league():
	var new_league = 0
	if high_score >= 500000: new_league = 6
	elif high_score >= 200000: new_league = 5
	elif high_score >= 100000: new_league = 4
	elif high_score >= 50000: new_league = 3
	elif high_score >= 20000: new_league = 2
	elif high_score >= 5000: new_league = 1
	
	if new_league != current_league:
		current_league = new_league
		league_changed.emit(current_league)
		_save_game()

func _check_daily_reward():
	var now = Time.get_unix_time_from_system()
	var today = Time.get_datetime_dict_from_system()["day"]
	var last_claim_day = Time.get_datetime_dict_from_unix_time(last_daily_claim)["day"]
	
	if last_daily_claim == 0 or today != last_claim_day:
		daily_reward_ready.emit()

func _emit_all_signals():
	game_state_changed.emit(current_state)
	score_changed.emit(score)
	coins_changed.emit(coins)
	lives_changed.emit(lives)
	level_changed.emit(current_level)
	xp_changed.emit(xp, current_level)
	streak_changed.emit(daily_streak)
	league_changed.emit(current_league)

func set_state(new_state: GameState):
	current_state = new_state
	game_state_changed.emit(new_state)

func add_score(points: int):
	score += int(points * multiplier)
	if score > high_score:
		high_score = score
		_update_league()
	score_changed.emit(score)
	_save_game()

func add_coins(amount: int):
	coins += amount
	coins_changed.emit(coins)
	_save_game()

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		coins_changed.emit(coins)
		_save_game()
		return true
	return false

func lose_life() -> bool:
	if lives > 0:
		lives -= 1
		lives_changed.emit(lives)
		_save_game()
		return true
	return false

func gain_life():
	if lives < max_lives:
		lives += 1
		lives_changed.emit(lives)
		_save_game()

func use_life_for_continue() -> bool:
	if coins >= 100:
		return spend_coins(100)
	elif lives > 0:
		return lose_life()
	return false

func add_xp(amount: int):
	xp += amount
	while xp >= level_xp_requirement:
		xp -= level_xp_requirement
		current_level += 1
		level_xp_requirement = int(XP_PER_LEVEL_BASE * pow(1.2, current_level - 1))
		level_changed.emit(current_level)
		add_coins(current_level * 10)
	xp_changed.emit(xp, current_level)
	_save_game()

func start_new_game():
	total_games_played += 1
	current_combo = 0
	multiplier = 1.0
	set_state(GameState.PLAYING)
	_save_game()

func end_game(victory: bool = false):
	if victory:
		add_xp(50 + current_level * 5)
		add_coins(10 + current_level * 2)
	set_state(GameState.GAME_OVER)
	MonetizationManager.show_interstitial_ad()
	_save_game()

func pause_game():
	if current_state == GameState.PLAYING:
		set_state(GameState.PAUSED)

func resume_game():
	if current_state == GameState.PAUSED:
		set_state(GameState.PLAYING)

func claim_daily_reward():
	var now = Time.get_unix_time_from_system()
	var today = Time.get_datetime_dict_from_system()["day"]
	var last_claim_day = Time.get_datetime_dict_from_unix_time(last_daily_claim)["day"]
	
	if last_daily_claim == 0 or today != last_claim_day:
		var reward_coins = 50 + daily_streak * 10
		var reward_lives = min(1 + int(daily_streak / 7), 3)
		
		add_coins(reward_coins)
		lives = min(lives + reward_lives, max_lives)
		lives_changed.emit(lives)
		
		daily_streak += 1
		last_daily_claim = now
		streak_changed.emit(daily_streak)
		_save_game()
		return {"coins": reward_coins, "lives": reward_lives}
	return null

func buy_no_ads_monthly():
	if MonetizationManager.purchase_product("no_ads_monthly"):
		return true
	return false

func buy_no_ads_permanent():
	if MonetizationManager.purchase_product("no_ads_permanent"):
		return true
	return false

func buy_coin_pack(pack_id: String):
	return MonetizationManager.purchase_product(pack_id)

func equip_powerup(powerup_id: String):
	if powerup_id in owned_powerups:
		equipped_powerup = powerup_id
		_save_game()

func _on_purchase_completed(product_id: String, is_subscription: bool):
	match product_id:
		"no_ads_monthly":
			has_no_ads = true
			no_ads_expiry = Time.get_unix_time_from_system() + 2592000
		"no_ads_permanent":
			has_no_ads = true
			no_ads_expiry = 0
		"coins_100":
			add_coins(100)
		"coins_500":
			add_coins(550)
		"coins_1200":
			add_coins(1400)
		"coins_2500":
			add_coins(3000)
		"powerup_bomb":
			owned_powerups["bomb"] = true
		"powerup_shuffle":
			owned_powerups["shuffle"] = true
		"powerup_undo":
			owned_powerups["undo"] = true
		"powerup_color_clear":
			owned_powerups["color_clear"] = true
	_save_game()

func _on_ads_removed():
	has_no_ads = true
	no_ads_expiry = 0
	_save_game()

func _on_daily_notification():
	claim_daily_reward()

func _save_game():
	var data = {
		"score": score,
		"high_score": high_score,
		"coins": coins,
		"lives": lives,
		"max_lives": max_lives,
		"current_level": current_level,
		"xp": xp,
		"current_league": current_league,
		"daily_streak": daily_streak,
		"last_daily_claim": last_daily_claim,
		"total_games_played": total_games_played,
		"total_lines_cleared": total_lines_cleared,
		"best_combo": best_combo,
		"has_no_ads": has_no_ads,
		"no_ads_expiry": no_ads_expiry,
		"owned_powerups": owned_powerups,
		"equipped_powerup": equipped_powerup,
		"tutorial_completed": tutorial_completed,
		"first_launch": first_launch
	}
	SaveManager.save_game(data)

func get_league_name() -> String:
	return LEAGUES[current_league]

func get_league_icon() -> String:
	return "res://assets/ui/league_%d.png" % current_league

func get_next_league_threshold() -> int:
	match current_league:
		0: return 5000
		1: return 20000
		2: return 50000
		3: return 100000
		4: return 200000
		5: return 500000
		6: return -1
	return -1

func get_lives_recovery_time() -> int:
	if lives >= max_lives:
		return 0
	var now = Time.get_unix_time_from_system()
	var last_recovery = SaveManager.get_data("last_life_recovery", now)
	var elapsed = now - last_recovery
	var remaining = LIVES_RECOVERY_TIME - (elapsed % LIVES_RECOVERY_TIME)
	return max(0, remaining)

func recover_life_over_time():
	if lives < max_lives:
		var now = Time.get_unix_time_from_system()
		var last_recovery = SaveManager.get_data("last_life_recovery", now)
		var elapsed = now - last_recovery
		var lives_to_recover = int(elapsed / LIVES_RECOVERY_TIME)
		if lives_to_recover > 0:
			lives = min(lives + lives_to_recover, max_lives)
			SaveManager.set_data("last_life_recovery", now - (elapsed % LIVES_RECOVERY_TIME))
			lives_changed.emit(lives)
			_save_game()

func reset_game_data():
	score = 0
	high_score = 0
	coins = 0
	lives = max_lives
	current_level = 1
	xp = 0
	level_xp_requirement = XP_PER_LEVEL_BASE
	current_league = 0
	daily_streak = 0
	last_daily_claim = 0
	total_games_played = 0
	total_lines_cleared = 0
	best_combo = 0
	has_no_ads = false
	no_ads_expiry = 0
	owned_powerups = {}
	equipped_powerup = ""
	tutorial_completed = false
	first_launch = true
	_save_game()
	_emit_all_signals()
