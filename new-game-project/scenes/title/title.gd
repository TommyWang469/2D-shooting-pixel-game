extends Control
## Title screen. Shows the name, a bobbing hero, best-score line and a "press any
## key" prompt. Any key or click starts a new run; S opens settings; Esc quits.
## Also resets pause/time-scale in case we came back from a finished run.

const SETTINGS_MENU := preload("res://scenes/ui/settings_menu.gd")

var _t := 0.0
var _settings: Control


func _ready() -> void:
	GameManager.is_game_over = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	Input.set_custom_mouse_cursor(null)   # menus use the normal cursor
	$Glow.texture = load("res://assets/glow.png")
	$Glow.modulate = Color(0.5, 0.4, 0.9, 0.5)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	$Glow.material = mat
	$Hero.texture = load("res://assets/player.png")
	$Hero.hframes = 8
	$Version.text = "v" + str(ProjectSettings.get_setting("application/config/version", "1.0"))
	_refresh_best()
	Audio.play_music("stone")


func _refresh_best() -> void:
	if Save.best_score > 0:
		var wins := "  ·  %d win%s" % [Save.victories, "" if Save.victories == 1 else "s"] \
				if Save.victories > 0 else ""
		$Best.text = "Best score %d  ·  Chapter %d%s" % [Save.best_score, Save.best_chapter, wins]
	else:
		$Best.text = ""


func _process(delta: float) -> void:
	_t += delta
	$Sub.modulate.a = 0.5 + sin(_t * 4.0) * 0.5
	$Hero.frame = 4 + int(_t * 6.0) % 4
	$Hero.position.y = 150.0 + sin(_t * 2.0) * 4.0
	$Glow.scale = Vector2.ONE * (3.0 + sin(_t * 1.5) * 0.3)


func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_settings):
		return   # settings overlay is open
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:
				get_tree().quit()
			KEY_S:
				_open_settings()
			_:
				_start()
	elif event is InputEventMouseButton and event.pressed:
		_start()
	elif event is InputEventJoypadButton and event.pressed:
		_start()


func _open_settings() -> void:
	Audio.play("click")
	_settings = SETTINGS_MENU.new()
	add_child(_settings)


func _start() -> void:
	Audio.play("click")
	get_tree().change_scene_to_file("res://scenes/title/char_select.tscn")
