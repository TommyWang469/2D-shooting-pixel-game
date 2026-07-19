extends Control
## Character select. Arrow keys / A-D to move, Enter/Space/click to confirm. Builds a
## card per Character and starts a run with the chosen id. Locked heroes show their
## gem price — confirming an affordable one unlocks it. U opens the upgrades shop.

const UPGRADES_MENU := preload("res://scenes/ui/upgrades_menu.gd")

var _index := 0
var _cards: Array[Control] = []
var _overlay: Control

@onready var cards_box: HBoxContainer = $Cards
@onready var gems_label: Label = $Gems


func _ready() -> void:
	GameManager.is_game_over = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	Input.set_custom_mouse_cursor(null)
	Audio.play_music("stone")
	Save.gems_changed.connect(func(_g): _refresh_gems())
	_build_cards()
	_refresh_gems()


func _build_cards() -> void:
	for c in cards_box.get_children():
		c.queue_free()
	_cards.clear()
	for id in Character.ORDER:
		var card := _make_card(id, Character.get_data(id))
		cards_box.add_child(card)
		_cards.append(card)
		var idx := _cards.size() - 1
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(_on_card_input.bind(idx))
	_select(_index)


func _refresh_gems() -> void:
	gems_label.text = "◆ %d gems" % Save.gems


func _make_card(id: String, data: Dictionary) -> Control:
	var locked := not Save.is_hero_unlocked(id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 190)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vb)

	var hero := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = load(data.get("sprite", "res://assets/player.png"))
	atlas.region = Rect2(0, 0, 16, 16)
	hero.texture = atlas
	hero.custom_minimum_size = Vector2(64, 64)
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if locked:
		hero.modulate = Color(0.25, 0.25, 0.3)   # silhouette
	vb.add_child(hero)

	var name_l := Label.new()
	name_l.text = data["display_name"]
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 16)
	vb.add_child(name_l)

	var stats_l := Label.new()
	stats_l.text = "HP %d   SPD %d" % [data["max_hp"], int(data["speed"])]
	stats_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_l.add_theme_font_size_override("font_size", 11)
	stats_l.modulate = Color(0.8, 0.9, 1.0)
	vb.add_child(stats_l)

	var skill_l := Label.new()
	if locked:
		skill_l.text = "LOCKED\n◆ %d gems\nconfirm to unlock" % data.get("unlock_cost", 0)
		skill_l.modulate = Color(1.0, 0.85, 0.4)
	else:
		skill_l.text = data["skill"]
	skill_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_l.add_theme_font_size_override("font_size", 10)
	skill_l.custom_minimum_size = Vector2(134, 0)
	vb.add_child(skill_l)

	return panel


## Click a card to select it; click the selected card again to confirm/unlock.
func _on_card_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if _index == idx:
			_confirm()
		else:
			_select(idx)
			Audio.play("click")


func _select(i: int) -> void:
	_index = wrapi(i, 0, _cards.size())
	for j in _cards.size():
		var sel := j == _index
		_cards[j].modulate = Color.WHITE if sel else Color(0.55, 0.55, 0.6)
		_cards[j].scale = Vector2(1.08, 1.08) if sel else Vector2.ONE


func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_overlay):
		return
	if event.is_action_pressed("ui_cancel"):
		Audio.play("click")
		get_tree().change_scene_to_file("res://scenes/title/title.tscn")
	elif event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_U:
		_open_upgrades()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_select(_index + 1)
		Audio.play("click")
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_select(_index - 1)
		Audio.play("click")
	elif event.is_action_pressed("ui_accept") \
			or (event is InputEventMouseButton and event.pressed
				and event.button_index == MOUSE_BUTTON_LEFT):
		_confirm()


func _open_upgrades() -> void:
	Audio.play("click")
	_overlay = UPGRADES_MENU.new()
	add_child(_overlay)


func _confirm() -> void:
	var id: String = Character.ORDER[_index]
	if not Save.is_hero_unlocked(id):
		var cost: int = Character.get_data(id).get("unlock_cost", 0)
		if Save.unlock_hero(id, cost):
			Audio.play("unlock")
			_build_cards()   # re-render the card unlocked
		else:
			Audio.play("hurt", 0.1, -8.0)
		return
	GameManager.character_id = id
	Audio.play("upgrade")
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
