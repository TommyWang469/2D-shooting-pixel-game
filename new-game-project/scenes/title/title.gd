extends Control
## Title screen. Shows the name, a bobbing hero, and a "press any key" prompt. Any
## key or click starts a new run. Also resets pause/time-scale in case we came back
## from a finished run.

var _t := 0.0


func _ready() -> void:
	GameManager.is_game_over = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	$Glow.texture = load("res://assets/glow.png")
	$Glow.modulate = Color(0.5, 0.4, 0.9, 0.5)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	$Glow.material = mat
	$Hero.texture = load("res://assets/player.png")
	$Hero.hframes = 8
	Audio.play_music()


func _process(delta: float) -> void:
	_t += delta
	$Sub.modulate.a = 0.5 + sin(_t * 4.0) * 0.5
	$Hero.frame = 4 + int(_t * 6.0) % 4
	$Hero.position.y = 150.0 + sin(_t * 2.0) * 4.0
	$Glow.scale = Vector2.ONE * (3.0 + sin(_t * 1.5) * 0.3)


func _unhandled_input(event: InputEvent) -> void:
	var start := false
	if event is InputEventKey and event.pressed and not event.echo:
		start = true
	elif event is InputEventMouseButton and event.pressed:
		start = true
	if start:
		Audio.play("click")
		get_tree().change_scene_to_file("res://scenes/title/char_select.tscn")
