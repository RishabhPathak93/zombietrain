class_name Armory
extends PanelContainer
## Upgrade shop: spend banked coins on permanent weapon & gear upgrades.

signal closed

var _coin_label: Label
var _rows: Dictionary = {}
var _weapon_rows: Dictionary = {}

func _ready() -> void:
	theme = UITheme.theme()
	custom_minimum_size = Vector2(720, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	box.add_child(header)
	var title := UITheme.title("ARMORY", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_coin_label = UITheme.label("", 28, UITheme.COL_ACCENT)
	header.add_child(_coin_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	var shop_header := UITheme.label("— NEW WEAPONS —", 20, UITheme.COL_DIM)
	shop_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(shop_header)
	for id in SaveGame.WEAPON_SHOP.keys():
		list.add_child(_weapon_row(id))
	var upgrade_header := UITheme.label("— UPGRADES —", 20, UITheme.COL_DIM)
	upgrade_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(upgrade_header)
	for key in SaveGame.UPGRADE_DEFS.keys():
		list.add_child(_row(key))
	var close_button := UITheme.button("DONE", 24, Vector2(200, 60))
	close_button.pressed.connect(func() -> void: closed.emit())
	var center := CenterContainer.new()
	center.add_child(close_button)
	box.add_child(center)
	_refresh()

func _row(key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var name_label := UITheme.label(String(SaveGame.UPGRADE_DEFS[key]["name"]), 22)
	name_label.custom_minimum_size = Vector2(300, 0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var pips := UITheme.label("", 22, UITheme.COL_ACCENT)
	pips.custom_minimum_size = Vector2(130, 0)
	row.add_child(pips)
	var buy_button := UITheme.button("", 20, Vector2(170, 54))
	buy_button.pressed.connect(func() -> void:
		if SaveGame.buy_upgrade(key):
			AudioMan.play("pickup_item")
		_refresh()
	)
	row.add_child(buy_button)
	_rows[key] = {"pips": pips, "button": buy_button}
	return row

func _weapon_row(id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var name_label := UITheme.label(String(SaveGame.WEAPON_SHOP[id]["name"]), 22)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var buy_button := UITheme.button("", 20, Vector2(170, 54))
	buy_button.pressed.connect(func() -> void:
		if SaveGame.buy_weapon(id):
			AudioMan.play("pickup_item")
		_refresh()
	)
	row.add_child(buy_button)
	_weapon_rows[id] = buy_button
	return row

func _refresh() -> void:
	_coin_label.text = "%d COINS" % SaveGame.coins()
	for id in _weapon_rows.keys():
		var buy_button: Button = _weapon_rows[id]
		if SaveGame.owns_weapon(id):
			buy_button.text = "OWNED"
			buy_button.disabled = true
		else:
			var cost := int(SaveGame.WEAPON_SHOP[id]["cost"])
			buy_button.text = "%d c" % cost
			buy_button.disabled = SaveGame.coins() < cost
	for key in _rows.keys():
		var level: int = SaveGame.upgrade_level(key)
		var pips: Label = _rows[key]["pips"]
		var button: Button = _rows[key]["button"]
		pips.text = "#".repeat(level) + "-".repeat(SaveGame.MAX_LEVEL - level)
		var cost := SaveGame.upgrade_cost(key)
		if cost < 0:
			button.text = "MAXED"
			button.disabled = true
		else:
			button.text = "%d c" % cost
			button.disabled = SaveGame.coins() < cost
