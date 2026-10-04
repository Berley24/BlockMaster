extends Node

signal music_volume_changed(volume: float)
signal sfx_volume_changed(volume: float)

var _music_player: AudioStreamPlayer = null
var _sfx_players: Array[AudioStreamPlayer] = []
var _max_sfx_channels: int = 8
var _music_volume: float = 0.5
var _sfx_volume: float = 0.8
var _muted: bool = false

var _music_tracks: Dictionary = {
	"menu": "res://assets/audio/music_menu.ogg",
	"gameplay": "res://assets/audio/music_gameplay.ogg",
	"game_over": "res://assets/audio/music_gameover.ogg",
	"victory": "res://assets/audio/music_victory.ogg",
	"shop": "res://assets/audio/music_shop.ogg"
}

var _sfx_sounds: Dictionary = {
	"click": "res://assets/audio/sfx_click.ogg",
	"place_block": "res://assets/audio/sfx_place.ogg",
	"line_clear": "res://assets/audio/sfx_clear.ogg",
	"combo": "res://assets/audio/sfx_combo.ogg",
	"powerup": "res://assets/audio/sfx_powerup.ogg",
	"coin": "res://assets/audio/sfx_coin.ogg",
	"error": "res://assets/audio/sfx_error.ogg",
	"level_up": "res://assets/audio/sfx_levelup.ogg",
	"life_lost": "res://assets/audio/sfx_lifelost.ogg",
	"daily_reward": "res://assets/audio/sfx_daily.ogg",
	"achievement": "res://assets/audio/sfx_achievement.ogg"
}

func _ready():
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	_music_player.bus = "Music"
	
	for i in range(_max_sfx_channels):
		var player = AudioStreamPlayer.new()
		add_child(player)
		player.bus = "SFX"
		_sfx_players.append(player)
	
	_load_settings()
	_play_music("menu")

func _load_settings():
	_music_volume = SaveManager.get_data("music_volume", 0.5)
	_sfx_volume = SaveManager.get_data("sfx_volume", 0.8)
	_muted = SaveManager.get_data("muted", false)
	_apply_volumes()

func _apply_volumes():
	if _muted:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), -80)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), -80)
	else:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(_music_volume))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(_sfx_volume))

func play_music(track_name: String, fade_time: float = 1.0):
	if not _music_tracks.has(track_name):
		return
	
	var new_stream = load(_music_tracks[track_name])
	if not new_stream:
		return
	
	if _music_player.playing:
		var tween = create_tween()
		tween.tween_property(_music_player, "volume_db", -80, fade_time)
		tween.finished.connect(func(): _switch_music(new_stream, fade_time))
	else:
		_switch_music(new_stream, fade_time)

func _switch_music(new_stream: AudioStream, fade_time: float):
	_music_player.stream = new_stream
	_music_player.play()
	var tween = create_tween()
	tween.tween_property(_music_player, "volume_db", linear_to_db(_music_volume), fade_time)

func stop_music(fade_time: float = 1.0):
	if _music_player.playing:
		var tween = create_tween()
		tween.tween_property(_music_player, "volume_db", -80, fade_time)
		tween.finished.connect(_music_player.stop)

func play_sfx(sound_name: String, pitch_scale: float = 1.0) -> bool:
	if not _sfx_sounds.has(sound_name):
		return false
	
	for player in _sfx_players:
		if not player.playing:
			var stream = load(_sfx_sounds[sound_name])
			if stream:
				player.stream = stream
				player.pitch_scale = pitch_scale
				player.play()
				return true
	
	var player = _sfx_players[0]
	var stream = load(_sfx_sounds[sound_name])
	if stream:
		player.stream = stream
		player.pitch_scale = pitch_scale
		player.play()
		return true
	return false

func play_sfx_at_position(sound_name: String, position: Vector2, pitch_scale: float = 1.0):
	play_sfx(sound_name, pitch_scale)

func set_music_volume(volume: float):
	_music_volume = clamp(volume, 0.0, 1.0)
	SaveManager.set_data("music_volume", _music_volume)
	if not _muted:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(_music_volume))
	music_volume_changed.emit(_music_volume)

func set_sfx_volume(volume: float):
	_sfx_volume = clamp(volume, 0.0, 1.0)
	SaveManager.set_data("sfx_volume", _sfx_volume)
	if not _muted:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(_sfx_volume))
	sfx_volume_changed.emit(_sfx_volume)

func set_muted(muted: bool):
	_muted = muted
	SaveManager.set_data("muted", _muted)
	_apply_volumes()

func get_music_volume() -> float:
	return _music_volume

func get_sfx_volume() -> float:
	return _sfx_volume

func is_muted() -> bool:
	return _muted

func preload_all():
	for track in _music_tracks.values():
		ResourceLoader.load_threaded_request(track)
	for sfx in _sfx_sounds.values():
		ResourceLoader.load_threaded_request(sfx)