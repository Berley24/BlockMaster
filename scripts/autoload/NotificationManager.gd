extends Node

signal daily_notification_clicked()
signal notification_received(title: String, body: String, data: Dictionary)

var _notification_manager: Object = null
var _initialized: bool = false
var _daily_notification_id: int = 1001
var _weekly_notification_id: int = 1002
var _event_notification_id: int = 1003

func _ready():
	_init_notifications()

func _init_notifications():
	if Engine.has_singleton("GodotNotifications"):
		_notification_manager = Engine.get_singleton("GodotNotifications")
		_notification_manager.connect("on_notification_clicked", _on_notification_clicked)
		_notification_manager.connect("on_notification_received", _on_notification_received)
		_notification_manager.connect("on_token_received", _on_token_received)
		_initialized = true
		_request_permission()
	else:
		push_warning("GodotNotifications plugin not found. Local notifications disabled.")
		_schedule_local_notifications()

func _request_permission():
	if _notification_manager:
		_notification_manager.request_permission()

func _on_token_received(token: String):
	print("FCM Token: ", token)
	SaveManager.set_data("fcm_token", token)

func _on_notification_clicked(notification_id: int, data: Dictionary):
	if notification_id == _daily_notification_id:
		daily_notification_clicked.emit()
	notification_received.emit("", "", data)

func _on_notification_received(title: String, body: String, data: Dictionary):
	notification_received.emit(title, body, data)

func schedule_daily_reward_notification(hour: int = 10, minute: int = 0):
	if not _initialized:
		_schedule_local_daily(hour, minute)
		return
	
	var notification_data = {
		"id": _daily_notification_id,
		"title": "🎁 Recompensa Diária!",
		"body": "Suas moedas e vidas grátis estão esperando. Vem buscar!",
		"icon": "res://assets/ui/icon.png",
		"channel_id": "daily_rewards",
		"channel_name": "Recompensas Diárias",
		"channel_importance": 3,
		"trigger": {
			"type": "daily",
			"hour": hour,
			"minute": minute,
			"exact": true
		},
		"data": {"type": "daily_reward"}
	}
	_notification_manager.schedule_notification(notification_data)

func schedule_weekly_tournament_notification(day_of_week: int = 1, hour: int = 19, minute: int = 0):
	if not _initialized:
		return
	
	var notification_data = {
		"id": _weekly_notification_id,
		"title": "🏆 Torneio Semanal Começou!",
		"body": "Novos desafios, novas recompensas. Suba na liga!",
		"icon": "res://assets/ui/icon.png",
		"channel_id": "tournaments",
		"channel_name": "Torneios",
		"channel_importance": 4,
		"trigger": {
			"type": "weekly",
			"day_of_week": day_of_week,
			"hour": hour,
			"minute": minute,
			"exact": true
		},
		"data": {"type": "weekly_tournament"}
	}
	_notification_manager.schedule_notification(notification_data)

func schedule_life_recovered_notification():
	if not _initialized:
		return
	
	var notification_data = {
		"id": _event_notification_id + 1,
		"title": "❤️ Vida Recuperada!",
		"body": "Você ganhou uma vida extra. Hora de jogar!",
		"icon": "res://assets/ui/icon.png",
		"channel_id": "game_events",
		"channel_name": "Eventos do Jogo",
		"channel_importance": 3,
		"trigger": {
			"type": "once",
			"delay_seconds": 300
		},
		"data": {"type": "life_recovered"}
	}
	_notification_manager.schedule_notification(notification_data)

func schedule_comeback_notification(days_inactive: int = 3):
	if not _initialized:
		return
	
	var messages = [
		"Sentimos sua falta! Volte para sua recompensa diária 🎁",
		"Novos desafios te esperam! 🧩",
		"Sua liga está te chamando! 🏆"
	]
	
	var notification_data = {
		"id": _event_notification_id + 2,
		"title": "Ei, tudo bem? 👋",
		"body": messages[randi() % messages.size()],
		"icon": "res://assets/ui/icon.png",
		"channel_id": "retention",
		"channel_name": "Retention",
		"channel_importance": 3,
		"trigger": {
			"type": "once",
			"delay_seconds": days_inactive * 86400
		},
		"data": {"type": "comeback"}
	}
	_notification_manager.schedule_notification(notification_data)

func cancel_all_notifications():
	if _initialized and _notification_manager:
		_notification_manager.cancel_all_notifications()
	else:
		_cancel_local_notifications()

func cancel_notification(notification_id: int):
	if _initialized and _notification_manager:
		_notification_manager.cancel_notification(notification_id)

var _enabled: bool = true

func set_enabled(enabled: bool):
	_enabled = enabled
	SaveManager.set_data("notifications_enabled", enabled)
	if not enabled:
		cancel_all_notifications()
	else:
		_schedule_local_notifications()

func is_enabled() -> bool:
	return _enabled

func _schedule_local_notifications():
	var now = Time.get_datetime_dict_from_system()
	var next_daily = Dictionary(now)
	next_daily["hour"] = 10
	next_daily["minute"] = 0
	next_daily["second"] = 0
	
	var now_time = Time.get_unix_time_from_system()
	var daily_time = Time.get_unix_time_from_datetime(next_daily)
	
	if daily_time <= now_time:
		daily_time += 86400
	
	var delay = daily_time - now_time
	_schedule_local_daily(10, 0)

func _schedule_local_daily(hour: int, minute: int):
	call_deferred("_show_local_daily_notification")

func _show_local_daily_notification():
	if OS.has_feature("android") or OS.has_feature("ios"):
		return
	print("NOTIFICAÇÃO LOCAL: Recompensa diária disponível!")

func _cancel_local_notifications():
	pass