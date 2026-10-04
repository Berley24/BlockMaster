extends Node

signal purchase_completed(product_id: String, is_subscription: bool)
signal purchase_failed(product_id: String, error: String)
signal ads_removed()
signal rewarded_ad_completed(reward_type: String, amount: int)
signal interstitial_closed()

var _payment: Object = null
var _admob: Object = null
var _initialized: bool = false
var _interstitial_loaded: bool = false
var _rewarded_loaded: bool = false
var _pending_reward: Dictionary = {}

const PRODUCT_IDS = {
	"no_ads_monthly": "no_ads_monthly",
	"no_ads_permanent": "no_ads_permanent",
	"coins_100": "coins_100",
	"coins_500": "coins_500",
	"coins_1200": "coins_1200",
	"coins_2500": "coins_2500",
	"powerup_bomb": "powerup_bomb",
	"powerup_shuffle": "powerup_shuffle",
	"powerup_undo": "powerup_undo",
	"powerup_color_clear": "powerup_color_clear"
}

const AD_UNITS = {
	"interstitial": "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX",
	"rewarded": "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX",
	"banner": "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX",
	"app_open": "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
}

func _ready():
	_init_payment()
	_init_admob()

func _init_payment():
	if Engine.has_singleton("GodotPayment"):
		_payment = Engine.get_singleton("GodotPayment")
		_payment.connect("on_purchase_success", _on_purchase_success)
		_payment.connect("on_purchase_failed", _on_purchase_failed)
		_payment.connect("on_subscription_updated", _on_subscription_updated)
		_payment.connect("on_products_loaded", _on_products_loaded)
		_payment.connect("on_restore_purchases_success", _on_restore_purchases_success)
		_payment.connect("on_restore_purchases_failed", _on_restore_purchases_failed)
		_initialized = true
		_payment.query_products(PRODUCT_IDS.values())
	else:
		push_warning("GodotPayment plugin not found. IAP disabled.")

func _init_admob():
	if Engine.has_singleton("GodotAdMob"):
		_admob = Engine.get_singleton("GodotAdMob")
		_admob.connect("on_ad_loaded", _on_ad_loaded)
		_admob.connect("on_ad_failed_to_load", _on_ad_failed_to_load)
		_admob.connect("on_ad_opened", _on_ad_opened)
		_admob.connect("on_ad_closed", _on_ad_closed)
		_admob.connect("on_rewarded_ad_rewarded", _on_rewarded_ad_rewarded)
		_admob.connect("on_ad_clicked", _on_ad_clicked)
		_admob.connect("on_ad_impression", _on_ad_impression)
		_admob.initialize()
		_load_interstitial()
		_load_rewarded_ad()
		_load_banner()
	else:
		push_warning("GodotAdMob plugin not found. Ads disabled.")

func _on_products_loaded(products: Array):
	for product in products:
		print("Product loaded: ", product.id, " - ", product.title, " - ", product.price)

func purchase_product(product_id: String) -> bool:
	if not _initialized or not _payment:
		purchase_failed.emit(product_id, "Payment not initialized")
		return false
	
	if product_id in PRODUCT_IDS:
		_payment.purchase(PRODUCT_IDS[product_id])
		return true
	purchase_failed.emit(product_id, "Invalid product ID")
	return false

func restore_purchases():
	if _initialized and _payment:
		_payment.restore_purchases()

func _on_purchase_success(product_id: String, is_subscription: bool, purchase_token: String):
	print("Purchase success: ", product_id, " subscription: ", is_subscription)
	purchase_completed.emit(product_id, is_subscription)
	
	if product_id == PRODUCT_IDS["no_ads_permanent"] or product_id == PRODUCT_IDS["no_ads_monthly"]:
		ads_removed.emit()

func _on_purchase_failed(product_id: String, error_code: int, error_message: String):
	print("Purchase failed: ", product_id, " - ", error_message)
	purchase_failed.emit(product_id, error_message)

func _on_subscription_updated(product_id: String, is_active: bool, expiry_time: int):
	print("Subscription updated: ", product_id, " active: ", is_active, " expiry: ", expiry_time)
	if product_id == PRODUCT_IDS["no_ads_monthly"]:
		if is_active:
			ads_removed.emit()
		else:
			GameManager.has_no_ads = false

func _on_restore_purchases_success(purchases: Array):
	print("Restored purchases: ", purchases)
	for purchase in purchases:
		_on_purchase_success(purchase.product_id, purchase.is_subscription, purchase.purchase_token)

func _on_restore_purchases_failed(error: String):
	print("Restore purchases failed: ", error)

func show_interstitial_ad():
	if not GameManager.has_no_ads and _interstitial_loaded and _admob:
		_admob.show_interstitial()
	elif not _interstitial_loaded:
		_load_interstitial()

func show_rewarded_ad(reward_type: String, amount: int):
	if _rewarded_loaded and _admob:
		_pending_reward = {"type": reward_type, "amount": amount}
		_admob.show_rewarded_ad()
	else:
		_load_rewarded_ad()
		rewarded_ad_completed.emit(reward_type, amount)

func show_banner(position: int = 1):
	if not GameManager.has_no_ads and _admob:
		_admob.show_banner(position)

func hide_banner():
	if _admob:
		_admob.hide_banner()

func show_app_open_ad():
	if not GameManager.has_no_ads and _admob:
		_admob.show_app_open_ad()

func _load_interstitial():
	if _admob:
		_admob.load_interstitial(AD_UNITS["interstitial"])

func _load_rewarded_ad():
	if _admob:
		_admob.load_rewarded_ad(AD_UNITS["rewarded"])

func _load_banner():
	if _admob:
		_admob.load_banner(AD_UNITS["banner"])

func _on_ad_loaded(ad_type: String):
	match ad_type:
		"interstitial":
			_interstitial_loaded = true
		"rewarded":
			_rewarded_loaded = true

func _on_ad_failed_to_load(ad_type: String, error_code: int, error_message: String):
	print("Ad failed to load: ", ad_type, " - ", error_message)
	match ad_type:
		"interstitial":
			_interstitial_loaded = false
			call_deferred("_load_interstitial")
		"rewarded":
			_rewarded_loaded = false
			call_deferred("_load_rewarded_ad")

func _on_ad_opened(ad_type: String):
	match ad_type:
		"interstitial":
			_interstitial_loaded = false

func _on_ad_closed(ad_type: String):
	match ad_type:
		"interstitial":
			interstitial_closed.emit()
			call_deferred("_load_interstitial")
		"rewarded":
			call_deferred("_load_rewarded_ad")

func _on_rewarded_ad_rewarded(reward_type: String, reward_amount: int):
	print("Rewarded ad completed: ", reward_type, " x", reward_amount)
	rewarded_ad_completed.emit(_pending_reward.type, _pending_reward.amount)
	_pending_reward = {}

func _on_ad_clicked(ad_type: String):
	print("Ad clicked: ", ad_type)

func _on_ad_impression(ad_type: String):
	print("Ad impression: ", ad_type)

var _personalized_ads: bool = true

func set_personalized_ads(enabled: bool):
	_personalized_ads = enabled
	if _admob:
		_admob.set_consent(enabled)

func is_personalized_ads() -> bool:
	return _personalized_ads

func is_ad_free() -> bool:
	return GameManager.has_no_ads

func get_product_price(product_id: String) -> String:
	if _payment and _initialized:
		var products = _payment.get_products()
		for product in products:
			if product.id == PRODUCT_IDS.get(product_id, ""):
				return product.price
	return "R$ 0,00"