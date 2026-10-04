extends Control

signal consent_given(personalized_ads: bool, analytics: bool, notifications: bool)

@onready var panel: PanelContainer = %Panel
@onready var title: Label = %Title
@onready var text: Label = %Text
@onready var personalized_ads_check: CheckButton = %PersonalizedAdsCheck
@onready var analytics_check: CheckButton = %AnalyticsCheck
@onready var notifications_check: CheckButton = %NotificationsCheck
@onready var accept_btn: Button = %AcceptBtn
@onready var customize_btn: Button = %CustomizeBtn
@onready var reject_btn: Button = %RejectBtn
@onready var privacy_link: LinkButton = %PrivacyLink
@onready var terms_link: LinkButton = %TermsLink
@onready var customize_panel: PanelContainer = %CustomizePanel
@onready var save_customize_btn: Button = %SaveCustomizeBtn
@onready var back_customize_btn: Button = %BackCustomizeBtn

var _showing_customize: bool = false

func _ready():
	privacy_link.pressed.connect(_open_privacy)
	terms_link.pressed.connect(_open_terms)
	accept_btn.pressed.connect(_on_accept_all)
	customize_btn.pressed.connect(_show_customize)
	reject_btn.pressed.connect(_on_reject_all)
	save_customize_btn.pressed.connect(_save_customize)
	back_customize_btn.pressed.connect(_hide_customize)
	
	_load_saved_consent()
	
	# Mostrar apenas se primeiro launch ou sem consentimento salvo
	if not SaveManager.get_data("consent_given", false):
		show()
	else:
		hide()

func _load_saved_consent():
	personalized_ads_check.button_pressed = SaveManager.get_data("consent_personalized_ads", true)
	analytics_check.button_pressed = SaveManager.get_data("consent_analytics", true)
	notifications_check.button_pressed = SaveManager.get_data("consent_notifications", true)

func _open_privacy():
	OS.shell_open("https://seusite.com/privacidade")
	AudioManager.play_sfx("click")

func _open_terms():
	OS.shell_open("https://seusite.com/termos")
	AudioManager.play_sfx("click")

func _on_accept_all():
	_save_consent(true, true, true)
	AudioManager.play_sfx("click")

func _on_reject_all():
	_save_consent(false, false, false)
	AudioManager.play_sfx("click")

func _show_customize():
	_showing_customize = true
	panel.visible = false
	customize_panel.visible = true
	AudioManager.play_sfx("click")

func _hide_customize():
	_showing_customize = false
	panel.visible = true
	customize_panel.visible = false
	AudioManager.play_sfx("click")

func _save_customize():
	_save_consent(
		personalized_ads_check.button_pressed,
		analytics_check.button_pressed,
		notifications_check.button_pressed
	)
	AudioManager.play_sfx("click")

func _save_consent(personalized_ads: bool, analytics: bool, notifications: bool):
	SaveManager.set_data("consent_given", true)
	SaveManager.set_data("consent_personalized_ads", personalized_ads)
	SaveManager.set_data("consent_analytics", analytics)
	SaveManager.set_data("consent_notifications", notifications)
	SaveManager.set_data("consent_date", Time.get_unix_time_from_system())
	
	# Aplicar imediatamente
	MonetizationManager.set_personalized_ads(personalized_ads)
	NotificationManager.set_enabled(notifications)
	
	consent_given.emit(personalized_ads, analytics, notifications)
	
	hide()

func show():
	visible = true
	panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1, 0.3)

func hide():
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0, 0.3)
	tween.finished.connect(func(): visible = false)