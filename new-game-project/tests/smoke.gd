extends Node
## Headless smoke driver (temporary autoload, dev only). Exercises the publish-pass
## features end to end: save round-trip, room progression, boss + victory arc,
## endless continue, pause/settings, death + run recording. Prints PASS/FAIL lines
## and quits with a nonzero exit code on failure. Restores the real save file.

var _fails := 0
var _save_backup := ""
var _had_save := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_backup_save()
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ", label)
	else:
		_fails += 1
		print("FAIL: ", label)


func _backup_save() -> void:
	_had_save = FileAccess.file_exists(Save.PATH)
	if _had_save:
		_save_backup = FileAccess.open(Save.PATH, FileAccess.READ).get_as_text()


func _restore_save() -> void:
	if _had_save:
		FileAccess.open(Save.PATH, FileAccess.WRITE).store_string(_save_backup)
	elif FileAccess.file_exists(Save.PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.PATH))


func _run() -> void:
	# Watchdog
	get_tree().create_timer(90.0, true, false, true).timeout.connect(func():
		print("FAIL: smoke test watchdog timeout")
		_finish(1))

	await _frames(5)
	var scene := get_tree().current_scene
	_check(scene != null and scene.name == "Main", "main scene loaded")

	# --- save round trip -----------------------------------------------------
	Save.master_volume = 0.5
	Save.screen_shake = false
	Save.save()
	var data: Variant = JSON.parse_string(
			FileAccess.open(Save.PATH, FileAccess.READ).get_as_text())
	_check(data is Dictionary and is_equal_approx(float(data["master_volume"]), 0.5)
			and data["screen_shake"] == false, "save file round-trips settings")
	Save.master_volume = 1.0
	Save.screen_shake = true
	Save.apply_settings()
	_check(AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("SFX") >= 0,
			"audio buses exist")

	# --- pause menu ----------------------------------------------------------
	var hud := get_tree().get_first_node_in_group("hud")
	_check(hud != null, "hud found")
	hud._toggle_pause()
	await _frames(2)
	_check(get_tree().paused and hud.pause_panel.visible, "pause opens")
	hud._open_settings()
	await _frames(2)
	_check(is_instance_valid(hud._settings), "settings overlay opens")
	hud._settings._close()
	await _frames(2)
	_check(not is_instance_valid(hud._settings), "settings overlay closes")
	hud._toggle_pause()
	await _frames(2)
	_check(not get_tree().paused, "pause closes")

	# --- fast-forward to the final boss room --------------------------------
	# Jump state to chapter 3 room 3, then clear the room to ride the real
	# portal -> boss -> victory pipeline. Player is made unkillable so stray
	# enemies can't end the run while the driver waits.
	var hero := get_tree().get_first_node_in_group("player")
	if hero:
		hero.max_hp = 999
		hero.hp = 999
	GameManager.chapter = 3
	GameManager.room = 3
	GameManager.room_changed.emit(GameManager.room)   # regenerates the room
	await _frames(5)
	await _clear_room_and_take_portal()
	_check(GameManager.is_boss_room(), "arrived in boss room (ch3)")

	# wait for the boss to spawn, then kill it
	var boss: Node = null
	for i in 40:
		await _frames(10)
		boss = get_tree().get_first_node_in_group("boss")
		if boss:
			break
	_check(boss != null, "chapter-3 boss spawned")
	if boss:
		var vic := [false]
		GameManager.victory_triggered.connect(func(): vic[0] = true)
		boss.take_damage(99999)
		await _frames(5)
		# ride the portal that appears after the boss dies
		await _take_portal_when_ready()
		await _frames(5)
		_check(vic[0], "victory triggered after final boss")
		_check(GameManager.has_won, "has_won set")
		_check(get_tree().paused, "victory screen pauses game")
		_check(hud.victory_panel.visible, "victory panel visible")
		hud._continue_endless()
		await _frames(2)
		_check(not get_tree().paused and not hud.victory_panel.visible,
				"endless mode continues")
		_check(GameManager.chapter == 4, "endless chapter 4 reached")

	# --- death + run recording ----------------------------------------------
	var player := get_tree().get_first_node_in_group("player")
	_check(player != null, "player alive before death test")
	if player:
		var runs_before: int = Save.total_runs
		while player.hp > 0:
			player._invincible = 0.0
			player.take_damage(999)
			await _frames(1)
		await _frames(3)
		_check(GameManager.is_game_over, "death triggers game over")
		_check(hud.game_over_panel.visible, "game-over panel visible")
		_check(Save.total_runs == runs_before + 1, "run recorded to save")
		_check(Save.victories >= 1, "victory recorded to save")
		_check(GameManager.last_run_new_best, "score recorded as best")

	_finish(1 if _fails > 0 else 0)


func _clear_room_and_take_portal() -> void:
	# Wait for the wave to actually spawn (the dungeon may be mid-transition)...
	for i in 60:
		await _frames(10)
		if not get_tree().get_nodes_in_group("enemies").is_empty():
			break
	# ...then keep killing until the room stays clear.
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


func _finish(code: int) -> void:
	_restore_save()
	print("SMOKE RESULT: ", "FAIL (%d)" % _fails if code != 0 else "ALL PASS")
	get_tree().quit(code)
