extends Control
## Character select. Arrow keys / A-D to move, Enter/Space/click to confirm. Builds a
## card per Character and starts a run with the chosen id.

var _index := 0
var _cards: Array[Control] = []

@onready var cards_box: HBoxContainer = $Cards


func _ready() -> void:
	GameManager.is_game_over = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	Audio.play_music()
	for id in Character.ORDER:
		var card := _make_card(Character.get_data(id))
		cards_box.add_child(card)
		_cards.append(card)
	_select(0)


func _make_card(data: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 190)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vb)

	var hero := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/player.png")
	atlas.region = Rect2(0, 0, 16, 16)
	hero.texture = atlas
	hero.modulate = data["tint"]
	hero.custom_minimum_size = Vector2(64, 64)
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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
	skill_l.text = data["skill"]
	skill_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_l.add_theme_font_size_override("font_size", 10)
	skill_l.custom_minimum_size = Vector2(134, 0)
	vb.add_child(skill_l)

	return panel


func _select(i: int) -> void:
	_index = wrapi(i, 0, _cards.size())
	for j in _cards.size():
		var sel := j == _index
		_cards[j].modulate = Color.WHITE if sel else Color(0.55, 0.55, 0.6)
		_cards[j].scale = Vector2(1.08, 1.08) if sel else Vector2.ONE


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_select(_index + 1)
		Audio.play("click")
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_select(_index - 1)
		Audio.play("click")
	elif event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		_confirm()


func _confirm() -> void:
	GameManager.character_id = Character.ORDER[_index]
	Audio.play("upgrade")
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
