extends Node
## Headless anti-stall driver (temporary autoload, dev only). Reproduces the
## "2 enemies left but nowhere to be found" report: kills the wave down to one
## far-away stationary spitter, never attacks it, and checks the failsafe
## teleports it next to the player within the stall window.

const SPITTER := preload("res://scenes/enemy/spitter.tscn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _run() -> void:
	get_tree().create_timer(60.0, true, false, true).timeout.connect(func():
		print("FAIL: stall test watchdog")
		get_tree().quit(1))
	await _frames(10)
	var player := get_tree().get_first_node_in_group("player")
	player.max_hp = 999
	player.hp = 999

	# wait for the wave, then clear it except for one planted far spitter
	for i in 60:
		await _frames(10)
		if not get_tree().get_nodes_in_group("enemies").is_empty():
			break
	var main := get_tree().current_scene
	var far := SPITTER.instantiate()
	main.add_child(far)
	# plant it as far from the player as the floor allows
	var best: Vector2 = main.random_floor_pos()
	for i in 60:
		var p: Vector2 = main.random_floor_pos()
		if p.distance_to(player.global_position) > best.distance_to(player.global_position):
			best = p
	far.global_position = best
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != far:
			e.take_damage(99999)
	await _frames(5)
	var d0: float = far.global_position.distance_to(player.global_position)
	print("planted spitter at distance ", int(d0))

	# Do not touch it; the failsafe should relocate it within STALL_SECONDS + slack.
	# (Wait in real time — headless frames run faster than 60fps.)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 14000:
		await _frames(5)
		if not is_instance_valid(far):
			break
		if far.global_position.distance_to(player.global_position) < 150.0:
			print("PASS: stall failsafe teleported straggler (%.1fs)"
					% ((Time.get_ticks_msec() - t0) / 1000.0))
			get_tree().quit(0)
			return
	print("FAIL: straggler never relocated")
	get_tree().quit(1)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
