extends Node
## Headless boss-variety driver (temporary autoload, dev only). Fights the boss of
## every chapter in sequence: asserts each biome fields its own kind + sprite, lets
## it attack in real time (async patterns included), verifies projectiles/adds
## appear, then kills it and rides the portal onward.

var _fails := 0


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ", label)
	else:
		_fails += 1
		print("FAIL: ", label)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _run() -> void:
	get_tree().create_timer(120.0, true, false, true).timeout.connect(func():
		print("FAIL: bosses test watchdog")
		get_tree().quit(1))
	await _frames(10)
	var player := get_tree().get_first_node_in_group("player")
	player.max_hp = 99999
	player.hp = 99999

	for expected in ["stone", "ember", "frost"]:
		# jump to the last combat room of the current chapter, clear it, portal in
		GameManager.room = 3
		GameManager.room_changed.emit(GameManager.room)
		await _frames(5)
		await _clear_room_and_take_portal()
		_check(GameManager.is_boss_room(), "%s: reached boss room" % expected)

		var boss: Node = null
		for i in 60:
			await _frames(10)
			boss = get_tree().get_first_node_in_group("boss")
			if boss:
				break
		_check(boss != null, "%s: boss spawned" % expected)
		if boss == null:
			continue
		_check(boss.kind == expected, "%s: boss kind correct" % expected)
		_check(boss.sprite.texture.resource_path.ends_with("boss_%s.png" % expected),
				"%s: unique sprite (%s)" % [expected, boss.sprite.texture.resource_path.get_file()])

		# let it fight in real time so async patterns (quake/eruption/spiral) run
		var t0 := Time.get_ticks_msec()
		var fired := false
		var adds := false
		while Time.get_ticks_msec() - t0 < 6000:
			await _frames(3)
			# force a rapid cadence so every pattern in the kit gets rolled
			boss._attack_cd = minf(boss._attack_cd, 0.2)
			if _enemy_bullets() > 0:
				fired = true
			if get_tree().get_nodes_in_group("enemies").size() > 1:
				adds = true
			player._invincible = 0.5   # stay alive, keep patterns coming
		_check(fired, "%s: boss fired projectiles" % expected)
		if expected != "ember":   # stone summons, frost spawns shards
			_check(adds, "%s: boss spawned adds" % expected)

		boss.take_damage(999999)
		await _frames(5)
		for e in get_tree().get_nodes_in_group("enemies"):
			e.take_damage(999999)
		if expected == "frost":
			break   # ch3 portal triggers the victory flow, tested elsewhere
		await _take_portal_when_ready()
		await _frames(10)

	print("BOSSES RESULT: ", "ALL PASS" if _fails == 0 else "FAIL (%d)" % _fails)
	get_tree().quit(0 if _fails == 0 else 1)


func _enemy_bullets() -> int:
	var n := 0
	for c in get_tree().current_scene.get_children():
		if c.get_script() and str(c.get_script().resource_path).ends_with("enemy_bullet.gd"):
			n += 1
	return n


func _clear_room_and_take_portal() -> void:
	for i in 60:
		await _frames(10)
		if not get_tree().get_nodes_in_group("enemies").is_empty():
			break
	for i in 30:
		var enemies := get_tree().get_nodes_in_group("enemies")
		if enemies.is_empty():
			break
		for e in enemies:
			if is_instance_valid(e) and e.has_method("take_damage"):
				e.take_damage(99999)
		await _frames(10)
	await _take_portal_when_ready()


func _take_portal_when_ready() -> void:
	var player := get_tree().get_first_node_in_group("player")
	for i in 60:
		await _frames(10)
		var portals := get_tree().get_nodes_in_group("portal")
		if not portals.is_empty() and is_instance_valid(player):
			player.global_position = portals[0].global_position
			await _frames(10)
			return


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
