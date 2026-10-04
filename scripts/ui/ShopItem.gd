extends PanelContainer

signal purchase_requested(item_id: String, item_data: Dictionary)

var _item_data: Dictionary = {}
var _category: String = ""
var _owned: bool = false

@onready var icon_label: Label = %IconLabel
@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var price_label: Label = %PriceLabel
@onready var coins_price_label: Label = %CoinsPriceLabel
@onready var buy_button: Button = %BuyButton
@onready var popular_badge: Label = %PopularBadge
@onready var owned_badge: Label = %OwnedBadge

func _ready():
	buy_button.pressed.connect(_on_buy_pressed)

func setup(item_data: Dictionary, category: String):
	_item_data = item_data
	_category = category
	
	icon_label.text = item_data["icon"]
	name_label.text = item_data["name"]
	desc_label.text = item_data["desc"]
	price_label.text = item_data["price_brl"]
	
	popular_badge.visible = item_data.get("popular", false)
	
	if item_data.has("coins_price"):
		coins_price_label.text = "%d moedas" % item_data["coins_price"]
		coins_price_label.visible = true
	else:
		coins_price_label.visible = false
	
	_check_owned_state()

func _check_owned_state():
	if _category == "powerups":
		_owned = GameManager.owned_powerups.has(_item_data["id"])
		owned_badge.visible = _owned
		buy_button.disabled = _owned
		if _owned:
			buy_button.text = "ADQUIRIDO"
			modulate = Color(0.7, 1, 0.7, 1)
		else:
			buy_button.text = "COMPRAR"
			modulate = Color(1, 1, 1, 1)
	elif _category == "no_ads":
		if _item_data["id"] == "no_ads_permanent":
			_owned = GameManager.has_no_ads and GameManager.no_ads_expiry == 0
		else:
			_owned = GameManager.has_no_ads and GameManager.no_ads_expiry > Time.get_unix_time_from_system()
		owned_badge.visible = _owned
		buy_button.disabled = _owned
		if _owned:
			buy_button.text = "ATIVO"
			modulate = Color(0.7, 1, 0.7, 1)

func update_owned_state(owned: bool):
	_owned = owned
	_check_owned_state()

func _on_buy_pressed():
	if _owned:
		AudioManager.play_sfx("error")
		return
	purchase_requested.emit(_item_data["id"], _item_data)