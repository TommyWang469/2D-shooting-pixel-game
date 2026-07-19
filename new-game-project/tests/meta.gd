extends Node
## Headless meta-progression driver (temporary autoload, dev only). Verifies the
## commercial-pass systems: gem economy (elite/boss drops -> bank), permanent
## upgrades (buy + applied to a fresh player), hero unlocks, new weapons, minimap.
## Backs up and restores the real save file.

const SLIME := preload("res://scenes/enemy/slime.tscn")

var _fails := 0
var _save_backup := ""
var _had_save := false


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ", label)
	else:
		_fails += 1
		print("FAIL: ", label)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_had_save = FileAccess.file_exists(Save.PATH)
	if _had_save:
		_save_backup = FileAccess.open(Save.PATH, FileAccess.READ).get_as_text()
	_run.call_deferred()


func _restore_save() -> void:
	if _had_save:
		FileAccess.open(Save.PATH, FileAccess.WRITE).store_string(_save_backup)
	elif FileAccess.file_exists(Save.PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.PATH))


func _run() -> void:
	get_tree().create_timer(90.0, true, false, true).timeout.connect(func():
		print("FAIL: meta test watchdog")
		_finish(1))
	await _frames(10)
	var player := get_tree().get_first_node_in_group("player")
	player.max_hp = 999
	player.hp = 999

	# --- upgrade + unlock API round trip ------------------------------------
	Save.gems = 0
	Save.upgrades = {}
	Save.heroes = ["gunner"]
	_check(not Save.buy_upgrade("vitality"), "cannot buy upgrade broke")
	Save.gems = 200
	_check(Save.buy_upgrade("vitality"), "buy vitality tier 1")
	_check(Save.upgrade_level("vitality") == 1, "vitality level recorded")
	_check(Save.gems == 175, "gems deducted (25)")
	_check(Save.buy_upgrade("vitality") and Save.upgrade_level("vitality") == 2,
			"buy vitality tier 2")
	_check(Save.upgrade_next_cost("magnet") == 15, "next-cost API")
	_check(not Save.is_hero_unlocked("knight"), "knight starts locked")
	_check(Save.unlock_hero("knight", 60), "unlock knight")
	_check(Save.gems == 200 - 25 - 50 - 60, "gems after unlock")
	_check(not Save.unlock_hero("knight", 60), "double unlock refused")

	# --- upgrades apply to a fresh player -----------------------------------
	var base_hp: int = Character.get_data("gunner")["max_hp"]
	player._apply_character()
	_check(player.max_hp == base_hp + 2, "vitality applied on spawn (+2)")

	# --- new weapons ---------------------------------------------------------
	var wand := Weapon.by_id("wand")
	_check(wand.homing > 0.0 and wand.bullet_options()["homing"] > 0.0,
			"homing wand exists with homing option")
	_check(Weapon.by_id("railgun").pierce >= 99, "railgun pierces everything")
	var pool_ok := true
	for wid in Weapon.CHEST_POOL:
		var w := Weapon.by_id(wid)
		if w.id != wid or w.display_name == "" or w.shot_angles().is_empty():
			pool_ok = false
	_check(pool_ok and Weapon.CHEST_POOL.size() == 12, "all 12 pool weapons build (13 with blaster)")
	_check(Weapon.by_id("ricochet").bullet_options()["bounce"] == 3, "ricochet bounces")
	_check(Weapon.by_id("frostbow").bullet_options()["slow"] > 0.0, "frost bow chills")
	# slow actually caps enemy movement
	var chill := SLIME.instantiate()
	get_tree().current_scene.add_child(chill)
	chill.global_position = player.global_position + Vector2(400, 0)
	chill.apply_slow(0.5, 1.0)
	_check(chill._slow_t > 0.0 and chill._slow_mult == 0.5, "apply_slow takes effect")
	chill.queue_free()

	# --- elite enemies -------------------------------------------------------
	var e := SLIME.instantiate()
	get_tree().current_scene.add_child(e)
	e.global_position = player.global_position + Vector2(300, 0)
	var hp_before: int = e.max_hp
	e.apply_theme(Color.WHITE, 1.0, 1.0)
	e.make_elite()
	_check(e.elite and e.max_hp >= int(hp_before * 2), "elite is tanky")
	_check(e.gem_min >= 1, "elite guarantees gems")
	# elite death drops gem pickups that bank when collected
	var gems_before: int = Save.gems
	e.take_damage(99999)
	await _frames(10)
	var gem_nodes := []
	for c in get_tree().current_scene.get_children():
		if c.get("kind") == "gem":
			gem_nodes.append(c)
	_check(gem_nodes.size() >= 1, "elite dropped gem pickup(s)")
	for g in gem_nodes:
		if not is_instance_valid(g):
			continue   # magnet already vacuumed it up
		player.global_position = g.global_position   # walk onto it
		await _frames(20)
	await _frames(10)
	_check(Save.gems > gems_before, "collected gems banked to save (%d -> %d)"
			% [gems_before, Save.gems])
	_check(GameManager.gems_run > 0, "run gem counter tracks")

	# --- boss gem config + minimap texture ----------------------------------
	var hud := get_tree().get_first_node_in_group("hud")
	_check(hud._map_tex != null, "minimap baked for room")
	var boss_scene := preload("res://scenes/enemy/boss.tscn")
	var b := boss_scene.instantiate()
	b.kind = "ember"
	get_tree().current_scene.add_child(b)
	_check(b.gem_min >= 4, "boss drops 4+ gems")
	b.take_damage(9999999)
	await _frames(5)

	_finish(1 if _fails > 0 else 0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _finish(code: int) -> void:
	_restore_save()
	print("META RESULT: ", "ALL PASS" if code == 0 else "FAIL (%d)" % _fails)
	get_tree().quit(code)
