extends Node

signal game_saved(success: bool)
signal game_loaded(data: Dictionary)

var _save_path: String = "user://savegame.json"
var _settings_path: String = "user://settings.json"
var _cache: Dictionary = {}

func _ready():
	_load_settings()

func save_game(data: Dictionary) -> bool:
	var file = FileAccess.open(_save_path, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(data, "\t")
		file.store_string(json_str)
		file.close()
		game_saved.emit(true)
		return true
	game_saved.emit(false)
	return false

func load_game() -> Dictionary:
	var file = FileAccess.open(_save_path, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var data = JSON.parse_string(json_str)
		if data.error == OK:
			game_loaded.emit(data)
			return data
	game_loaded.emit({})
	return {}

func get_data(key: String, default = null):
	if _cache.has(key):
		return _cache[key]
	
	var file = FileAccess.open(_settings_path, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var data = JSON.parse_string(json_str)
		if data.error == OK and data.has(key):
			_cache[key] = data[key]
			return data[key]
	return default

func set_data(key: String, value):
	_cache[key] = value
	var file = FileAccess.open(_settings_path, FileAccess.WRITE)
	if file:
		var data = _load_settings_file()
		data[key] = value
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func _load_settings() -> Dictionary:
	var file = FileAccess.open(_settings_path, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var data = JSON.parse_string(json_str)
		if data.error == OK:
			_cache = data
			return data
	_cache = {}
	return {}

func _load_settings_file() -> Dictionary:
	var file = FileAccess.open(_settings_path, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var data = JSON.parse_string(json_str)
		if data.error == OK:
			return data
	return {}

func clear_save():
	var file = FileAccess.open(_save_path, FileAccess.WRITE)
	if file:
		file.store_string("{}")
		file.close()
	game_saved.emit(true)

func has_save() -> bool:
	return FileAccess.file_exists(_save_path)

func backup_save() -> bool:
	if FileAccess.file_exists(_save_path):
		var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("/", "-")
		var backup_path = "user://savegame_backup_%s.json" % timestamp
		return DirAccess.copy_absolute(_save_path, backup_path)
	return false

func migrate_save(old_version: int, new_version: int):
	var data = load_game()
	if data:
		data["save_version"] = new_version
		save_game(data)