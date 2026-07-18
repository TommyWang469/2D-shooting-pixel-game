extends Node
## Headless organic-combat driver (temporary autoload, dev only). Holds the fire
## button and sweeps aim with the virtual joystick so real bullets kill real
## enemies (exercising physics-callback death/loot paths). PASS if kills happen
## and the run stays error-free.

var _t := 0.0
var _done := false


func _ready() -> void:
	await get_tree().process_frame
	var hero := get_tree().get_first_node_in_group("player")
	if hero:
		hero.max_hp = 999
		hero.hp = 999


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	Input.action_press("shoot")
	# sweep aim in a circle via the joystick actions the player reads
	var a := _t * 2.0
	Input.action_press("aim_right", maxf(cos(a), 0.0))
	Input.action_press("aim_left", maxf(-cos(a), 0.0))
	Input.action_press("aim_down", maxf(sin(a), 0.0))
	Input.action_press("aim_up", maxf(-sin(a), 0.0))
	# wander so enemies cross the line of fire
	Input.action_press("move_right" if int(_t) % 4 < 2 else "move_left")
	if _t >= 25.0:
		_done = true
		print("PASS: organic combat kills=", GameManager.kills) if GameManager.kills > 0 \
				else print("FAIL: no kills in organic combat")
		get_tree().quit(0 if GameManager.kills > 0 else 1)
