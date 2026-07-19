extends CanvasLayer
## HUD: hearts, coins, score, weapon, dash meter, chapter/room, boss bar, room
## banners, a low-HP screen pulse — plus the pause menu (with settings), game-over
## and victory overlays. Systems push data in via GameManager signals and the bound
## player.

const SETTINGS_MENU := preload("res://scenes/ui/settings_menu.gd")

var _heart_full: Texture2D
var _hp := 0
var _max_hp := 0
var _low := false
var _vig_t := 0.0
var _settings: Control
var _map_tex: ImageTexture         ## minimap floor silhouette, rebuilt per room
var _map_scale := 2.0

@onready var hearts_box: HBoxContainer = $HeartsBox
@onready var coin_icon: TextureRect = $CoinIcon
@onready var coin_label: Label = $CoinLabel
@onready var score_label: Label = $ScoreLabel
@onready var weapon_label: Label = $WeaponLabel
@onready var chapter_label: Label = $ChapterLabel
@onready var room_label: Label = $RoomLabel
@onready var enemies_label: Label = $EnemiesLabel
@onready var dash_fill: ColorRect = $DashBar/Fill
@onready var boss_bar: Control = $BossBar
@onready var boss_fill: ColorRect = $BossBar/Fill
@onready var boss_name: Label = $BossBar/Name
@onready var banner: Control = $Banner
@onready var banner_title: Label = $Banner/Title
@onready var banner_sub: Label = $Banner/Sub
@onready var vignette: ColorRect = $Vignette
@onready var game_over_panel: Control = $GameOver
@onready var final_label: Label = $GameOver/Panel/Final
@onready var victory_panel: Control = $Victory
@onready var victory_label: Label = $Victory/Panel/Text
@onready var pause_panel: Control = $Pause
@onready var pause_resume: Button = $Pause/Panel/VBox/ResumeBtn
@onready var gem_icon: TextureRect = $GemIcon
@onready var gem_label: Label = $GemLabel
@onready var minimap: Control = $Minimap
@onready var fade: ColorRect = $Fade


func _ready() -> void:
	add_to_group("hud")
	_heart_full = load("res://assets/heart.png")
	coin_icon.texture = _atlas("res://assets/coin.png", Rect2(0, 0, 8, 8))
	game_over_panel.visible = false
	victory_panel.visible = false
	boss_bar.visible = false
	banner.visible = false
	pause_panel.visible = false
	vignette.modulate.a = 0.0
	GameManager.coins_changed.connect(_on_coins)
	GameManager.score_changed.connect(_on_score)
	GameManager.chapter_changed.connect(_on_chapter)
	GameManager.room_changed.connect(_on_room)
	GameManager.game_over_triggered.connect(_on_game_over)
	GameManager.victory_triggered.connect(_on_victory)
	Save.gems_changed.connect(_on_gems)
	gem_icon.texture = _atlas("res://assets/gem.png", Rect2(0, 0, 8, 8))
	_on_gems(Save.gems)
	minimap.draw.connect(_draw_minimap)
	_on_coins(GameManager.coins)
	_on_score(GameManager.score)
	_on_chapter(GameManager.chapter)
	_on_room(GameManager.room)
	_run_fade()
	# pause menu
	pause_resume.pressed.connect(_toggle_pause)
	$Pause/Panel/VBox/SettingsBtn.pressed.connect(_open_settings)
	$Pause/Panel/VBox/RestartBtn.pressed.connect(_restart)
	$Pause/Panel/VBox/QuitBtn.pressed.connect(_quit_to_title)
	# game over
	$GameOver/Panel/Buttons/RestartBtn.pressed.connect(_restart)
	$GameOver/Panel/Buttons/TitleBtn.pressed.connect(_quit_to_title)
	# victory
	$Victory/Panel/Buttons/ContinueBtn.pressed.connect(_continue_endless)
	$Victory/Panel/Buttons/VTitleBtn.pressed.connect(_quit_to_title)


func _process(delta: float) -> void:
	var n := get_tree().get_nodes_in_group("enemies").size()
	if n <= 0:
		enemies_label.text = ""
	elif n == 1:
		enemies_label.text = "1 enemy left"
	else:
		enemies_label.text = "%d enemies left" % n
	if _low and not GameManager.is_game_over:
		_vig_t += delta
		vignette.modulate.a = 0.12 + sin(_vig_t * 6.0) * 0.10
	elif vignette.modulate.a > 0.0:
		vignette.modulate.a = maxf(vignette.modulate.a - delta, 0.0)
	minimap.queue_redraw()


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


func _on_score(score: int) -> void:
	score_label.text = "Score %d" % score


func _on_chapter(chapter: int) -> void:
	chapter_label.text = "Chapter %d" % chapter


func _on_room(room: int) -> void:
	room_label.text = "Boss" if room >= GameManager.ROOMS_PER_CHAPTER else "Room %d" % room
	# Deferred: Main regenerates its grid in this same signal emission.
	call_deferred("_rebuild_minimap")
	_run_fade()


func _on_gems(total: int) -> void:
	gem_label.text = "%d" % total


# ================================================================ minimap & fade
## Bake the room's floor silhouette into a tiny texture (1px per tile).
func _rebuild_minimap() -> void:
	var main := get_tree().current_scene
	if main == null or not "grid" in main or main.grid.is_empty():
		return
	var img := Image.create(main.GW, main.GH, false, Image.FORMAT_RGBA8)
	for y in main.GH:
		for x in main.GW:
			if main.grid[y][x]:
				img.set_pixel(x, y, Color(1, 1, 1, 0.30))
	_map_tex = ImageTexture.create_from_image(img)
	_map_scale = minimap.size.x / float(main.GW)


func _draw_minimap() -> void:
	if _map_tex == null or GameManager.is_game_over:
		return
	var main := get_tree().current_scene
	if main == null:
		return
	minimap.draw_texture_rect(_map_tex, Rect2(Vector2.ZERO, _map_tex.get_size() * _map_scale), false)
	var world_to_map := _map_scale / float(main.TILE)
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			var col := Color(1.0, 0.82, 0.3) if e.get("elite") else Color(1.0, 0.35, 0.35)
			minimap.draw_rect(Rect2(e.global_position * world_to_map - Vector2.ONE, Vector2(2, 2)), col)
	for p in get_tree().get_nodes_in_group("portal"):
		if is_instance_valid(p):
			minimap.draw_rect(Rect2(p.global_position * world_to_map - Vector2.ONE, Vector2(3, 3)),
					Color(0.75, 0.6, 1.0))
	var player := get_tree().get_first_node_in_group("player")
	if player:
		minimap.draw_rect(Rect2(player.global_position * world_to_map - Vector2.ONE, Vector2(2, 2)),
				Color.WHITE)


## Black dip that softens every room change (and the scene start).
func _run_fade() -> void:
	fade.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 0.0, 0.45)


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


func set_boss_name(bname: String) -> void:
	boss_name.text = bname


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


# ================================================================ pause & menus
func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_settings):
		return   # settings overlay handles its own input
	if victory_panel.visible:
		return
	if GameManager.is_game_over:
		if event.is_action_pressed("quit_to_title"):
			_quit_to_title()
		return
	if event.is_action_pressed("pause"):
		_toggle_pause()


func _toggle_pause() -> void:
	var p := not get_tree().paused
	get_tree().paused = p
	pause_panel.visible = p
	Audio.play("click")
	if p:
		pause_resume.grab_focus()


func _open_settings() -> void:
	Audio.play("click")
	_settings = SETTINGS_MENU.new()
	add_child(_settings)
	_settings.closed.connect(func(): pause_resume.grab_focus())


func _restart() -> void:
	Audio.play("click")
	get_tree().paused = false
	get_tree().reload_current_scene()


func _quit_to_title() -> void:
	Audio.play("click")
	GameManager.abandon_run()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title/title.tscn")


func _continue_endless() -> void:
	Audio.play("click")
	victory_panel.visible = false
	get_tree().paused = false


func _on_victory() -> void:
	get_tree().paused = true
	victory_panel.visible = true
	victory_label.text = "VICTORY!\n\nAll three depths conquered.\n\nScore: %d   (+%d bonus)\nKills: %d\n◆ +%d gems banked  (total %d)\n\nKeep descending in Endless Mode?" % [
		GameManager.score, GameManager.VICTORY_BONUS, GameManager.kills,
		GameManager.gems_run, Save.gems
	]
	$Victory/Panel/Buttons/ContinueBtn.grab_focus()
	Audio.play("upgrade", 0.0, 2.0)


func _on_game_over() -> void:
	var best_line := "NEW BEST SCORE!" if GameManager.last_run_new_best \
			else "Best: %d" % Save.best_score
	final_label.text = "GAME OVER\n\nChapter %d  ·  Room %d\nScore: %d\n%s\nKills: %d\n◆ +%d gems banked  (total %d)" % [
		GameManager.chapter, GameManager.room, GameManager.score,
		best_line, GameManager.kills, GameManager.gems_run, Save.gems
	]
	game_over_panel.visible = true
	$GameOver/Panel/Buttons/RestartBtn.grab_focus()
