extends Control

@onready var back_button: Button = %BackButton
@onready var coins_label: Label = %CoinsLabel
@onready var tab_coins: TabButton = %TabCoins
@onready var tab_no_ads: TabButton = %TabNoAds
@onready var tab_powerups: TabButton = %TabPowerups
@onready var tab_lives: TabButton = %TabLives
@onready var coins_category: VBoxContainer = %CoinsCategory
@onready var no_ads_category: VBoxContainer = %NoAdsCategory
@onready var powerups_category: VBoxContainer = %PowerupsCategory
@onready var lives_category: VBoxContainer = %LivesCategory
@onready var purchase_popup: ColorRect = %PurchasePopup
@onready var purchase_title: Label = %PurchaseTitle
@onready var purchase_description: Label = %PurchaseDescription
@onready var purchase_price: Label = %PurchasePrice
@onready var purchase_confirm: Button = %PurchaseConfirm
@onready var purchase_cancel: Button = %PurchaseCancel

var _current_tab: int = 0
var _pending_purchase: String = ""

const SHOP_ITEMS = {
	"coins": [
		{"id": "coins_100", "name": "100 Moedas", "desc": "Pacote inicial", "price_brl": "R$ 4,99", "coins": 100, "icon": "💰", "popular": false},
		{"id": "coins_500", "name": "500 Moedas", "desc": "+10% bônus", "price_brl": "R$ 19,99", "coins": 550, "icon": "💰", "popular": true},
		{"id": "coins_1200", "name": "1.200 Moedas", "desc": "+16% bônus", "price_brl": "R$ 44,99", "coins": 1400, "icon": "💰", "popular": false},
		{"id": "coins_2500", "name": "2.500 Moedas", "desc": "+20% bônus", "price_brl": "R$ 89,99", "coins": 3000, "icon": "💰", "popular": false},
	],
	"no_ads": [
		{"id": "no_ads_monthly", "name": "Sem Anúncios (1 mês)", "desc": "Jogue sem interrupções por 30 dias", "price_brl": "R$ 14,99", "type": "subscription", "icon": "🚫", "popular": false},
		{"id": "no_ads_permanent", "name": "Sem Anúncios (Para Sempre)", "desc": "Nunca mais veja anúncios", "price_brl": "R$ 9,99", "type": "permanent", "icon": "🚫", "popular": true},
	],
	"powerups": [
		{"id": "powerup_bomb", "name": "Bomba 💣", "desc": "Limpa área 5x5 no centro", "price_brl": "R$ 7,99", "coins_price": 200, "icon": "💣", "permanent": true},
		{"id": "powerup_shuffle", "name": "Embaralhar 🔀", "desc": "Reorganiza todos os blocos", "price_brl": "R$ 5,99", "coins_price": 150, "icon": "🔀", "permanent": true},
		{"id": "powerup_undo", "name": "Desfazer ↩️", "desc": "Volta a última jogada", "price_brl": "R$ 3,99", "coins_price": 100, "icon": "↩️", "permanent": true},
		{"id": "powerup_color_clear", "name": "Limpar Cor 🎨", "desc": "Remove todos os blocos da cor mais comum", "price_brl": "R$ 11,99", "coins_price": 300, "icon": "🎨", "permanent": true},
	],
	"lives": [
		{"id": "life_1", "name": "1 Vida Extra", "desc": "Continua instantaneamente", "price_brl": "R$ 1,99", "coins_price": 50, "lives": 1, "icon": "❤️"},
		{"id": "life_5", "name": "5 Vidas", "desc": "Pacote de vidas", "price_brl": "R$ 7,99", "coins_price": 200, "lives": 5, "icon": "❤️"},
		{"id": "life_infinite", "name": "Vidas Infinitas (30 dias)", "desc": "Sem espera por vidas", "price_brl": "R$ 19,99", "type": "subscription", "icon": "♾️"},
	]
}

func _ready():
	GameManager.coins_changed.connect(_on_coins_changed)
	MonetizationManager.purchase_completed.connect(_on_purchase_completed)
	MonetizationManager.purchase_failed.connect(_on_purchase_failed)
	
	_setup_tabs()
	_setup_shop_items()
	_setup_buttons()
	_update_coins()
	_show_tab(0)

func _setup_tabs():
	var tabs = [tab_coins, tab_no_ads, tab_powerups, tab_lives]
	for i, tab in enumerate(tabs):
		tab.pressed.connect(_on_tab_pressed.bind(i))

func _setup_shop_items():
	_populate_category("coins", coins_category.find_child("CoinsGrid"))
	_populate_category("no_ads", no_ads_category.find_child("NoAdsGrid"))
	_populate_category("powerups", powerups_category.find_child("PowerupsGrid"))
	_populate_category("lives", lives_category.find_child("LivesGrid"))

func _populate_category(category: String, grid: GridContainer):
	if not grid:
		return
	
	for child in grid.get_children():
		if child is ShopItem:
			child.queue_free()
	
	for item_data in SHOP_ITEMS[category]:
		var item = ShopItem.new()
		item.setup(item_data, category)
		item.purchase_requested.connect(_on_purchase_requested)
		grid.add_child(item)

func _setup_buttons():
	back_button.pressed.connect(_on_back_pressed)
	purchase_confirm.pressed.connect(_on_purchase_confirm)
	purchase_cancel.pressed.connect(_on_purchase_cancel)

func _on_tab_pressed(tab_index: int):
	_show_tab(tab_index)
	AudioManager.play_sfx("click")

func _show_tab(index: int):
	_current_tab = index
	
	coins_category.visible = index == 0
	no_ads_category.visible = index == 1
	powerups_category.visible = index == 2
	lives_category.visible = index == 3
	
	var tabs = [tab_coins, tab_no_ads, tab_powerups, tab_lives]
	for i, tab in enumerate(tabs):
		tab.button_pressed = i == index

func _on_back_pressed():
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")

func _on_coins_changed(coins):
	coins_label.text = str(coins)

func _update_coins():
	coins_label.text = str(GameManager.coins)

func _on_purchase_requested(item_id: String, item_data: Dictionary):
	_pending_purchase = item_id
	purchase_title.text = item_data["name"]
	purchase_description.text = item_data["desc"]
	purchase_price.text = item_data["price_brl"]
	purchase_popup.show()
	AudioManager.play_sfx("click")

func _on_purchase_confirm():
	if _pending_purchase.is_empty():
		return
	
	AudioManager.play_sfx("coin")
	
	if _pending_purchase.begins_with("coins_") or _pending_purchase.begins_with("life_"):
		if MonetizationManager.buy_coin_pack(_pending_purchase):
			purchase_popup.hide()
			_pending_purchase = ""
		else:
			_show_error("Erro ao processar compra")
	elif _pending_purchase == "no_ads_monthly":
		if MonetizationManager.purchase_product("no_ads_monthly"):
			purchase_popup.hide()
			_pending_purchase = ""
	elif _pending_purchase == "no_ads_permanent":
		if MonetizationManager.purchase_product("no_ads_permanent"):
			purchase_popup.hide()
			_pending_purchase = ""
	elif _pending_purchase.begins_with("powerup_"):
		if MonetizationManager.purchase_product(_pending_purchase):
			purchase_popup.hide()
			_pending_purchase = ""
	else:
		_show_error("Item não reconhecido")

func _on_purchase_cancel():
	purchase_popup.hide()
	_pending_purchase = ""
	AudioManager.play_sfx("click")

func _on_purchase_completed(product_id: String, is_subscription: bool):
	AudioManager.play_sfx("coin")
	_show_success("Compra realizada com sucesso!")
	_update_coins()
	
	if product_id == "no_ads_permanent" or product_id == "no_ads_monthly":
		no_ads_category.find_child("NoAdsGrid").get_children()[1].update_owned_state(true)

func _on_purchase_failed(product_id: String, error: String):
	_show_error("Falha na compra: %s" % error)

func _show_error(message: String):
	purchase_title.text = "Erro"
	purchase_description.text = message
	purchase_price.text = ""
	purchase_confirm.text = "OK"
	purchase_confirm.disconnect("pressed", _on_purchase_confirm)
	purchase_confirm.pressed.connect(_on_error_ok)
	purchase_popup.show()

func _on_error_ok():
	purchase_confirm.text = "COMPRAR"
	purchase_confirm.disconnect("pressed", _on_error_ok)
	purchase_confirm.pressed.connect(_on_purchase_confirm)
	purchase_popup.hide()

func _show_success(message: String):
	purchase_title.text = "Sucesso!"
	purchase_description.text = message
	purchase_price.text = ""
	purchase_confirm.text = "OK"
	purchase_confirm.disconnect("pressed", _on_purchase_confirm)
	purchase_confirm.pressed.connect(_on_success_ok)
	purchase_popup.show()

func _on_success_ok():
	purchase_confirm.text = "COMPRAR"
	purchase_confirm.disconnect("pressed", _on_success_ok)
	purchase_confirm.pressed.connect(_on_purchase_confirm)
	purchase_popup.hide()