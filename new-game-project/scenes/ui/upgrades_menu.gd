extends Control
## Permanent-upgrades shop overlay (opened from character select with U). Spends
## banked gems on Save.UPGRADES tiers. Built in code, like the settings overlay.

signal closed

var _gems_label: Label
var _rows := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.7)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(320, 0)
	add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	margin.add_child(vb)

	var title := Label.new()
	title.text = "UPGRADES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
	vb.add_child(title)

	_gems_label = Label.new()
	_gems_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gems_label.add_theme_font_size_override("font_size", 12)
	_gems_label.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0))
	vb.add_child(_gems_label)

	for id in Save.UPGRADES:
		vb.add_child(_make_row(id))

	var back := Button.new()
	back.text = "Back"
	back.add_theme_font_size_override("font_size", 12)
	back.pressed.connect(_close)
	vb.add_child(back)
	back.grab_focus()
	_refresh()


func _make_row(id: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_l := Label.new()
	name_l.custom_minimum_size = Vector2(78, 0)
	name_l.add_theme_font_size_override("font_size", 11)
	row.add_child(name_l)

	var desc_l := Label.new()
	desc_l.custom_minimum_size = Vector2(126, 0)
	desc_l.add_theme_font_size_override("font_size", 10)
	desc_l.modulate = Color(0.8, 0.85, 0.95)
	desc_l.text = Save.UPGRADES[id]["desc"]
	row.add_child(desc_l)

	var buy := Button.new()
	buy.custom_minimum_size = Vector2(74, 0)
	buy.add_theme_font_size_override("font_size", 10)
	buy.pressed.connect(_buy.bind(id))
	row.add_child(buy)

	_rows[id] = {"name": name_l, "buy": buy}
	return row


func _refresh() -> void:
	_gems_label.text = "Gems: %d" % Save.gems
	for id in _rows:
		var lvl := Save.upgrade_level(id)
		var tiers: int = Save.UPGRADES[id]["costs"].size()
		var pips := "■".repeat(lvl) + "□".repeat(tiers - lvl)
		_rows[id]["name"].text = "%s %s" % [Save.UPGRADES[id]["name"], pips]
		var cost := Save.upgrade_next_cost(id)
		var buy: Button = _rows[id]["buy"]
		if cost < 0:
			buy.text = "MAXED"
			buy.disabled = true
		else:
			buy.text = "Buy  %d" % cost
			buy.disabled = false


func _buy(id: String) -> void:
	if Save.buy_upgrade(id):
		Audio.play("unlock", 0.05, -2.0)
	else:
		Audio.play("hurt", 0.1, -8.0)
	_refresh()


func _close() -> void:
	Audio.play("click")
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()
