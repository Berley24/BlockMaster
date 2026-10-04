extends Node

signal score_submitted(success: bool)
signal leaderboard_loaded(leaderboard_data: Array)
signal player_rank_updated(rank: int, score: int)
signal achievement_unlocked(achievement_id: String)
signal friends_loaded(friends_data: Array)

var _gpgs: Object = null
var _initialized: bool = false
var _leaderboard_id_high_score: String = "CgkIxxxxxxxxEAIQAA"
var _leaderboard_id_weekly: String = "CgkIxxxxxxxxEAIQAg"
var _leaderboard_id_daily: String = "CgkIxxxxxxxxEAIQAw"
var _achievements: Dictionary = {
	"first_win": "CgkIxxxxxxxxEAIQBA",
	"combo_5": "CgkIxxxxxxxxEAIQBQ",
	"combo_10": "CgkIxxxxxxxxEAIQBg",
	"level_10": "CgkIxxxxxxxxEAIQCA",
	"level_50": "CgkIxxxxxxxxEAIQCQ",
	"coins_1000": "CgkIxxxxxxxxEAIQCg",
	"no_ads_buy": "CgkIxxxxxxxxEAIQDA",
	"streak_7": "CgkIxxxxxxxxEAIQDQ",
	"streak_30": "CgkIxxxxxxxxEAIQDg",
	"league_gold": "CgkIxxxxxxxxEAIQEA",
	"league_diamond": "CgkIxxxxxxxxEAIQEQ",
	"master": "CgkIxxxxxxxxEAIQEg"
}

func _ready():
	_init_gpgs()

func _init_gpgs():
	if Engine.has_singleton("GodotPlayGamesServices"):
		_gpgs = Engine.get_singleton("GodotPlayGamesServices")
		_gpgs.connect("on_auth_finished", _on_auth_finished)
		_gpgs.connect("on_score_submitted", _on_score_submitted)
		_gpgs.connect("on_leaderboard_loaded", _on_leaderboard_loaded)
		_gpgs.connect("on_achievement_unlocked", _on_achievement_unlocked)
		_gpgs.connect("on_friends_loaded", _on_friends_loaded)
		_gpgs.connect("on_player_stats_loaded", _on_player_stats_loaded)
		_initialized = true
		_gpgs.authenticate()
	else:
		push_warning("GodotPlayGamesServices plugin not found. Leaderboards disabled.")
		_load_local_leaderboard()

func _on_auth_finished(success: bool, error: String):
	if success:
		print("GPGS authenticated successfully")
		_submit_high_score()
		_load_weekly_leaderboard()
		_check_achievements()
	else:
		print("GPGS auth failed: ", error)
		_load_local_leaderboard()

func submit_score(score: int, leaderboard_type: String = "high_score"):
	if not _initialized or not _gpgs:
		_submit_local_score(score)
		return
	
	var leaderboard_id = _get_leaderboard_id(leaderboard_type)
	_gpgs.submit_score(leaderboard_id, score)

func _submit_high_score():
	submit_score(GameManager.high_score, "high_score")

func _submit_weekly_score():
	var weekly_score = SaveManager.get_data("weekly_score", 0)
	if weekly_score > 0:
		submit_score(weekly_score, "weekly")

func _submit_daily_score():
	var daily_score = SaveManager.get_data("daily_score", 0)
	if daily_score > 0:
		submit_score(daily_score, "daily")

func _get_leaderboard_id(type: String) -> String:
	match type:
		"high_score": return _leaderboard_id_high_score
		"weekly": return _leaderboard_id_weekly
		"daily": return _leaderboard_id_daily
	return _leaderboard_id_high_score

func show_leaderboard(leaderboard_type: String = "high_score"):
	if _initialized and _gpgs:
		var leaderboard_id = _get_leaderboard_id(leaderboard_type)
		_gpgs.show_leaderboard(leaderboard_id)
	else:
		_load_local_leaderboard()

func load_leaderboard(leaderboard_type: String = "high_score", max_results: int = 50):
	if not _initialized or not _gpgs:
		_load_local_leaderboard()
		return
	
	var leaderboard_id = _get_leaderboard_id(leaderboard_type)
	_gpgs.load_leaderboard(leaderboard_id, max_results, 1, 0)

func _load_weekly_leaderboard():
	load_leaderboard("weekly")

func _load_local_leaderboard():
	var local_data = []
	var saved_scores = SaveManager.get_data("local_leaderboard", [])
	for entry in saved_scores:
		local_data.append(entry)
	leaderboard_loaded.emit(local_data)

func _on_score_submitted(leaderboard_id: String, success: bool, score: int):
	score_submitted.emit(success)
	if success:
		print("Score submitted to ", leaderboard_id, ": ", score)
		_update_local_leaderboard(score)
	else:
		print("Score submission failed")
		_submit_local_score(score)

func _on_leaderboard_loaded(leaderboard_id: String, data: Array):
	var formatted_data = []
	for entry in data:
		formatted_data.append({
			"name": entry.player_name,
			"score": entry.score,
			"rank": entry.rank,
			"avatar_url": entry.avatar_url,
			"is_player": entry.is_current_player
		})
	leaderboard_loaded.emit(formatted_data)

func _update_local_leaderboard(score: int):
	var local_scores = SaveManager.get_data("local_leaderboard", [])
	local_scores.append({
		"name": "Você",
		"score": score,
		"rank": 1,
		"avatar_url": "",
		"is_player": true,
		"date": Time.get_datetime_string_from_system()
	})
	local_scores.sort_custom(self, "_sort_scores")
	local_scores = local_scores.slice(0, 100)
	SaveManager.set_data("local_leaderboard", local_scores)

func _sort_scores(a: Dictionary, b: Dictionary):
	return a.score > b.score

func _submit_local_score(score: int):
	_update_local_leaderboard(score)
	score_submitted.emit(true)

func unlock_achievement(achievement_id: String):
	if not _initialized or not _gpgs:
		return
	
	if achievement_id in _achievements:
		_gpgs.unlock_achievement(_achievements[achievement_id])

func _on_achievement_unlocked(achievement_id: String):
	print("Achievement unlocked: ", achievement_id)
	achievement_unlocked.emit(achievement_id)

func _check_achievements():
	if GameManager.total_games_played >= 1:
		unlock_achievement("first_win")
	if GameManager.best_combo >= 5:
		unlock_achievement("combo_5")
	if GameManager.best_combo >= 10:
		unlock_achievement("combo_10")
	if GameManager.current_level >= 10:
		unlock_achievement("level_10")
	if GameManager.current_level >= 50:
		unlock_achievement("level_50")
	if GameManager.coins >= 1000:
		unlock_achievement("coins_1000")
	if GameManager.has_no_ads:
		unlock_achievement("no_ads_buy")
	if GameManager.daily_streak >= 7:
		unlock_achievement("streak_7")
	if GameManager.daily_streak >= 30:
		unlock_achievement("streak_30")
	if GameManager.current_league >= 2:
		unlock_achievement("league_gold")
	if GameManager.current_league >= 4:
		unlock_achievement("league_diamond")
	if GameManager.current_league >= 6:
		unlock_achievement("master")

func load_friends():
	if _initialized and _gpgs:
		_gpgs.load_friends()
	else:
		friends_loaded.emit([])

func _on_friends_loaded(friends: Array):
	var formatted = []
	for friend in friends:
		formatted.append({
			"name": friend.name,
			"avatar_url": friend.avatar_url,
			"player_id": friend.player_id
		})
	friends_loaded.emit(formatted)

func _on_player_stats_loaded(stats: Dictionary):
	print("Player stats loaded: ", stats)

func get_player_rank(leaderboard_type: String = "high_score") -> int:
	var local_scores = SaveManager.get_data("local_leaderboard", [])
	var high_score = GameManager.high_score
	var rank = 1
	for entry in local_scores:
		if entry.score > high_score:
			rank += 1
	return rank

func reset_weekly_scores():
	SaveManager.set_data("weekly_score", 0)

func reset_daily_scores():
	SaveManager.set_data("daily_score", 0)

func add_to_weekly_score(points: int):
	var current = SaveManager.get_data("weekly_score", 0)
	SaveManager.set_data("weekly_score", current + points)

func add_to_daily_score(points: int):
	var current = SaveManager.get_data("daily_score", 0)
	SaveManager.set_data("daily_score", current + points)