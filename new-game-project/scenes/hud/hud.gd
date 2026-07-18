extends CanvasLayer
## HUD: hearts, coins, weapon, dash meter, chapter/room, boss bar, room banners, a
## low-HP screen pulse, plus the game-over and pause overlays. Systems push data in
## via GameManager signals and the bound player.

var _heart_full: Texture2D
var _hp := 0
var _max_hp := 0
var _low := false
var _vig_t := 0.0

@onready var hearts_box: HBoxContainer = $HeartsBox
@onready var coin_icon: TextureRect = $CoinIcon
@onready var coin_label: Label = $CoinLabel
@onready var weapon_label: Label = $WeaponLabel
@onready var chapter_label: Label = $ChapterLabel
@onready var room_label: Label = $RoomLabel
@onready var dash_fill: ColorRect = $DashBar/Fill
@onready var boss_bar: Control = $BossBar
@onready var boss_fill: ColorRect = $BossBar/Fill
@onready var banner: Control = $Banner
@onready var banner_title: Label = $Banner/Title
@onready var banner_sub: Label = $Banner/Sub
@onready var vignette: ColorRect = $Vignette
@onready var game_over_panel: Control = $GameOver
@onready var final_label: Label = $GameOver/Panel/Final
@onready var pause_panel: Control = $Pause


func _ready() -> void:
	add_to_group("hud")
	_heart_full = load("res://assets/heart.png")
	coin_icon.texture = _atlas("res://assets/coin.png", Rect2(0, 0, 8, 8))
	game_over_panel.visible = false
	boss_bar.visible = false
	banner.visible = false
	pause_panel.visible = false
	vignette.modulate.a = 0.0
	GameManager.coins_changed.connect(_on_coins)
	GameManager.chapter_changed.connect(_on_chapter)
	GameManager.room_changed.connect(_on_room)
	GameManager.game_over_triggered.connect(_on_game_over)
	_on_coins(GameManager.coins)
	_on_chapter(GameManager.chapter)
	_on_room(GameManager.room)


func _process(delta: float) -> void:
	if _low and not GameManager.is_game_over:
		_vig_t += delta
		vignette.modulate.a = 0.12 + sin(_vig_t * 6.0) * 0.10
	elif vignette.modulate.a > 0.0:
		vignette.modulate.a = maxf(vignette.modulate.a - delta, 0.0)


func _atlas(path: String, region: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = load(path)
	a.region = region
	return a


func bind_player(player: Node) -> void:
	player.hp_changed.connect(_on_hp)
	player.weapons_changed.connect(_on_weapons)
	player.dash_changed.connect(_on_dash)
	_on_hp(player.hp, player.max_hp)
	if player.weapon:
		player._emit_weapons()


func _on_hp(current: int, maximum: int) -> void:
	_hp = current
	_max_hp = maximum
	_low = current <= 1 and current > 0
	_rebuild_hearts()


func _rebuild_hearts() -> void:
	for c in hearts_box.get_children():
		c.queue_free()
	for i in _max_hp:
		var tr := TextureRect.new()
		tr.texture = _heart_full
		tr.custom_minimum_size = Vector2(18, 18)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.modulate = Color.WHITE if i < _hp else Color(0.25, 0.18, 0.22, 1.0)
		hearts_box.add_child(tr)


func _on_coins(total: int) -> void:
	coin_label.text = "%d" % total


func _on_chapter(chapter: int) -> void:
	chapter_label.text = "Chapter %d" % chapter


func _on_room(room: int) -> void:
	room_label.text = "Boss" if room >= GameManager.ROOMS_PER_CHAPTER else "Room %d" % room


func _on_weapons(names: Array, index: int, slots: int) -> void:
	# Current weapon bracketed; empty slots shown as "--". Q/Tab cycles.
	var parts := []
	for i in names.size():
		parts.append(("[%s]" % names[i]) if i == index else str(names[i]))
	for i in range(names.size(), slots):
		parts.append("--")
	weapon_label.text = "  ·  ".join(parts)


func _on_dash(ratio: float) -> void:
	var r := clampf(ratio, 0.0, 1.0)
	dash_fill.size.x = 40.0 * r
	dash_fill.color = Color(0.5, 0.9, 1.0) if r >= 1.0 else Color(0.4, 0.5, 0.62)


func show_boss(current: int, maximum: int) -> void:
	boss_bar.visible = true
	boss_fill.size.x = 196.0 * (float(current) / maximum if maximum > 0 else 0.0)


func hide_boss() -> void:
	boss_bar.visible = false


func show_banner(title: String, subtitle: String, color: Color) -> void:
	banner_title.text = title
	banner_title.modulate = color
	banner_sub.text = subtitle
	banner.visible = true
	banner.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.1)
	tw.tween_property(banner, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func(): banner.visible = false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not GameManager.is_game_over:
		var p := not get_tree().paused
		get_tree().paused = p
		set_paused(p)
		Audio.play("click")


func set_paused(p: bool) -> void:
	pause_panel.visible = p


func _on_game_over() -> void:
	final_label.text = "GAME OVER\n\nChapter %d  ·  Room %d\nScore: %d\n\nPress R to Restart" % [
		GameManager.chapter, GameManager.room, GameManager.score
	]
	game_over_panel.visible = true
