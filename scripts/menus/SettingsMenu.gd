extends Control

@onready var back_button: Button = %BackButton
@onready var music_slider: HSlider = %MusicSlider
@onready var music_value: Label = %MusicValue
@onready var sfx_slider: HSlider = %SFXSlider
@onready var sfx_value: Label = %SFXValue
@onready var mute_checkbox: CheckButton = %MuteCheckbox
@onready var vibration_checkbox: CheckButton = %VibrationCheckbox
@onready var auto_save_checkbox: CheckButton = %AutoSaveCheckbox
@onready var show_ghost_checkbox: CheckButton = %ShowGhostCheckbox
@onready var daily_notif_checkbox: CheckButton = %DailyNotifCheckbox
@onready var weekly_notif_checkbox: CheckButton = %WeeklyNotifCheckbox
@onready var life_notif_checkbox: CheckButton = %LifeNotifCheckbox
@onready var restore_purchases_button: Button = %RestorePurchasesButton
@onready var sync_progress_button: Button = %SyncProgressButton
@onready var delete_data_button: Button = %DeleteDataButton
@onready var privacy_button: Button = %PrivacyButton
@onready var terms_button: Button = %TermsButton
@onready var confirm_popup: ColorRect = %ConfirmPopup
@onready var confirm_title: Label = %ConfirmTitle
@onready var confirm_message: Label = %ConfirmMessage
@onready var confirm_yes: Button = %ConfirmYes
@onready var confirm_no: Button = %ConfirmNo

var _pending_action: String = ""

func _ready():
	AudioManager.music_volume_changed.connect(_on_music_volume_changed)
	AudioManager.sfx_volume_changed.connect(_on_sfx_volume_changed)
	
	_setup_controls()
	_setup_buttons()
	_load_settings()

func _setup_controls():
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	mute_checkbox.toggled.connect(_on_mute_toggled)
	vibration_checkbox.toggled.connect(_on_vibration_toggled)
	auto_save_checkbox.toggled.connect(_on_auto_save_toggled)
	show_ghost_checkbox.toggled.connect(_on_show_ghost_toggled)
	daily_notif_checkbox.toggled.connect(_on_daily_notif_toggled)
	weekly_notif_checkbox.toggled.connect(_on_weekly_notif_toggled)
	life_notif_checkbox.toggled.connect(_on_life_notif_toggled)

func _setup_buttons():
	back_button.pressed.connect(_on_back_pressed)
	restore_purchases_button.pressed.connect(_on_restore_purchases)
	sync_progress_button.pressed.connect(_on_sync_progress)
	delete_data_button.pressed.connect(_show_delete_confirmation)
	privacy_button.pressed.connect(_open_privacy_policy)
	terms_button.pressed.connect(_open_terms)
	confirm_yes.pressed.connect(_on_confirm_yes)
	confirm_no.pressed.connect(_on_confirm_no)

func _load_settings():
	music_slider.value = AudioManager.get_music_volume()
	sfx_slider.value = AudioManager.get_sfx_volume()
	mute_checkbox.button_pressed = AudioManager.is_muted()
	
	vibration_checkbox.button_pressed = SaveManager.get_data("vibration_enabled", true)
	auto_save_checkbox.button_pressed = SaveManager.get_data("auto_save_enabled", true)
	show_ghost_checkbox.button_pressed = SaveManager.get_data("show_ghost_enabled", true)
	
	daily_notif_checkbox.button_pressed = SaveManager.get_data("daily_notif_enabled", true)
	weekly_notif_checkbox.button_pressed = SaveManager.get_data("weekly_notif_enabled", true)
	life_notif_checkbox.button_pressed = SaveManager.get_data("life_notif_enabled", true)
	
	_update_labels()

func _update_labels():
	music_value.text = "%d%%" % (AudioManager.get_music_volume() * 100)
	sfx_value.text = "%d%%" % (AudioManager.get_sfx_volume() * 100)

func _on_back_pressed():
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")

func _on_music_slider_changed(value: float):
	AudioManager.set_music_volume(value)
	AudioManager.play_sfx("click", 0.5 + value * 0.5)

func _on_sfx_slider_changed(value: float):
	AudioManager.set_sfx_volume(value)

func _on_music_volume_changed(volume: float):
	music_slider.value = volume
	_update_labels()

func _on_sfx_volume_changed(volume: float):
	sfx_slider.value = volume
	_update_labels()

func _on_mute_toggled(pressed: bool):
	AudioManager.set_muted(pressed)
	AudioManager.play_sfx("click")

func _on_vibration_toggled(pressed: bool):
	SaveManager.set_data("vibration_enabled", pressed)

func _on_auto_save_toggled(pressed: bool):
	SaveManager.set_data("auto_save_enabled", pressed)

func _on_show_ghost_toggled(pressed: bool):
	SaveManager.set_data("show_ghost_enabled", pressed)

func _on_daily_notif_toggled(pressed: bool):
	SaveManager.set_data("daily_notif_enabled", pressed)
	if pressed:
		NotificationManager.schedule_daily_reward_notification()
	else:
		NotificationManager.cancel_notification(1001)

func _on_weekly_notif_toggled(pressed: bool):
	SaveManager.set_data("weekly_notif_enabled", pressed)
	if pressed:
		NotificationManager.schedule_weekly_tournament_notification()
	else:
		NotificationManager.cancel_notification(1002)

func _on_life_notif_toggled(pressed: bool):
	SaveManager.set_data("life_notif_enabled", pressed)

func _on_restore_purchases():
	AudioManager.play_sfx("click")
	MonetizationManager.restore_purchases()

func _on_sync_progress():
	AudioManager.play_sfx("click")
	# TODO: Implement cloud save sync
	_show_message("Sincronização", "Funcionalidade em desenvolvimento")

func _show_delete_confirmation():
	_pending_action = "delete_data"
	confirm_title.text = "⚠️ APAGAR DADOS"
	confirm_message.text = "Isso apagará TODO seu progresso, moedas, compras e conquistas. Esta ação NÃO PODE SER DESFEITA."
	confirm_yes.text = "APAGAR TUDO"
	confirm_yes.theme_override_colors/font_color = Color(1, 0.3, 0.3, 1)
	confirm_popup.show()

func _on_confirm_yes():
	if _pending_action == "delete_data":
		GameManager.reset_game_data()
		SaveManager.clear_save()
		_confirm_no()
		_show_message("Concluído", "Todos os dados foram apagados")
	_pending_action = ""

func _on_confirm_no():
	confirm_popup.hide()

func _open_privacy_policy():
	AudioManager.play_sfx("click")
	OS.shell_open("https://seusite.com/privacidade")

func _open_terms():
	AudioManager.play_sfx("click")
	OS.shell_open("https://seusite.com/termos")

func _show_message(title: String, message: String):
	confirm_title.text = title
	confirm_message.text = message
	confirm_yes.text = "OK"
	confirm_yes.theme_override_colors/font_color = Color(1, 1, 1, 1)
	confirm_no.hide()
	confirm_popup.show()
	
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 2.0
	timer.timeout.connect(_on_confirm_no)
	add_child(timer)
	timer.start()