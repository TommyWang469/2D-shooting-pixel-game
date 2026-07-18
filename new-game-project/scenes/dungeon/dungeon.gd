extends Node
## Runs the dungeon: spawns each room's enemies (or the chapter boss), detects
## clears, then drops rewards and the exit portal. All placement is floor-aware —
## it asks the Main room generator for valid tiles — and every spawn is themed to
## the current biome (tint, stats, boss attack pattern).

const BOSS := preload("res://scenes/enemy/boss.tscn")
const ENEMY_SCENES := {
	"slime": preload("res://scenes/enemy/slime.tscn"),
	"bat": preload("res://scenes/enemy/bat.tscn"),
	"mage": preload("res://scenes/enemy/mage.tscn"),
	"imp": preload("res://scenes/enemy/imp.tscn"),
	"spitter": preload("res://scenes/enemy/spitter.tscn"),
	"ghost": preload("res://scenes/enemy/ghost.tscn"),
	"ice_slime": preload("res://scenes/enemy/ice_slime.tscn"),
}
const CHEST := preload("res://scenes/pickup/chest.tscn")
const PORTAL := preload("res://scenes/pickup/portal.tscn")
const SHOP := preload("res://scenes/pickup/shop_station.tscn")
const PICKUP := preload("res://scenes/pickup/pickup.tscn")
const BURST := preload("res://scenes/fx/burst.tscn")

## Anti-stall failsafe: if only a few enemies remain and nothing has died for this
## long, they're hiding somewhere the player can't find (an off-screen spitter in a
## cave arm) — teleport them next to the player so the fight comes to you.
const STALL_SECONDS := 10.0
const STALL_MAX_ENEMIES := 3

var _state := "idle"          # idle / combat / boss / transition
var _hud: Node
var _player: Node2D
var _stall := 0.0


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_hud = get_tree().get_first_node_in_group("hud")
	GameManager.kills_changed.connect(func(_k): _stall = 0.0)
	_start_after(1.2)


func _main() -> Node:
	return get_parent()


func _theme() -> Dictionary:
	return DungeonTheme.for_chapter(GameManager.chapter)


func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return
	if _state == "combat":
		var enemies := get_tree().get_nodes_in_group("enemies")
		if enemies.is_empty():
			_room_cleared(false)
		else:
			_tick_stall(delta, enemies)


func _tick_stall(delta: float, enemies: Array) -> void:
	if enemies.size() > STALL_MAX_ENEMIES:
		_stall = 0.0
		return
	_stall += delta
	if _stall < STALL_SECONDS:
		return
	_stall = 0.0
	if _player == null or not is_instance_valid(_player):
		return
	for e in enemies:
		if not is_instance_valid(e) or e._dying:
			continue
		_puff(e.global_position)
		var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(60.0, 90.0)
		e.global_position = _main().nearest_floor_pos(_player.global_position + offset)
		_puff(e.global_position)
	Audio.play("wave", 0.1, -8.0)


func _puff(pos: Vector2) -> void:
	var b := BURST.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = pos
	b.burst(Color(0.8, 0.6, 1.0), 10, 80.0)


func _start_after(delay: float) -> void:
	_state = "transition"
	await get_tree().create_timer(delay).timeout
	if GameManager.is_game_over or not is_inside_tree():
		return
	_begin_room()


func _begin_room() -> void:
	_stall = 0.0
	if _hud and _hud.has_method("hide_boss"):
		_hud.hide_boss()
	var biome: String = _theme().name
	if GameManager.is_boss_room():
		var bname: String = _theme().get("boss_name", "BOSS")
		if _hud and _hud.has_method("set_boss_name"):
			_hud.set_boss_name(bname)
		_banner(bname, "%s  ·  Chapter %d" % [biome, GameManager.chapter], Color(1.0, 0.5, 0.5))
		Audio.play("wave", 0.05, 2.0)
		_spawn_boss()
		_state = "boss"
	else:
		_banner("CHAPTER %d" % GameManager.chapter,
				"%s  ·  Room %d" % [biome, GameManager.room], Color(0.8, 0.9, 1.0))
		Audio.play("wave", 0.08, -3.0)
		_spawn_combat()
		_state = "combat"


func _banner(title: String, subtitle: String, color: Color) -> void:
	if _hud and _hud.has_method("show_banner"):
		_hud.show_banner(title, subtitle, color)


func _spawn_combat() -> void:
	var d := GameManager.difficulty()
	var total := mini(3 + int(round(d * 2.5)), 16)   # cap keeps endless fair (and fast)
	var roster: Array = _theme().roster
	for i in total:
		_spawn(ENEMY_SCENES[_pick_from_roster(roster)])
	_scatter_loot()


func _pick_from_roster(roster: Array) -> String:
	var total := 0.0
	for entry in roster:
		total += entry[1]
	var r := randf() * total
	for entry in roster:
		r -= entry[1]
		if r <= 0.0:
			return entry[0]
	return roster[0][0]


func _scatter_loot() -> void:
	for i in randi_range(1, 3):
		_drop_pickup("coin", _rand_pos())
	if randf() < 0.35:
		_drop_pickup("heart", _rand_pos())


func _drop_pickup(kind: String, pos: Vector2) -> void:
	var p := PICKUP.instantiate()
	p.kind = kind
	p.value = 1
	get_tree().current_scene.add_child(p)
	p.global_position = pos


func _spawn_boss() -> void:
	var t := _theme()
	var b := BOSS.instantiate()
	var world := get_tree().current_scene
	world.add_child(b)
	b.global_position = _main().top_pos() + Vector2(0, 24)
	b.apply_theme(t.boss_tint, t.hp_mult, t.speed_mult)
	b.attack_weights = t.boss_weights
	if _hud and _hud.has_method("show_boss"):
		b.health_changed.connect(_hud.show_boss)
	b.died.connect(_on_boss_died)


func _spawn(scene: PackedScene) -> void:
	var t := _theme()
	var e := scene.instantiate()
	get_tree().current_scene.add_child(e)
	e.global_position = _rand_pos()
	e.apply_theme(t.enemy_tint, t.hp_mult, t.speed_mult)


func _rand_pos() -> Vector2:
	var avoid: Vector2 = _player.global_position if (_player and is_instance_valid(_player)) else Vector2.INF
	return _main().random_floor_pos(avoid, 95.0)


func _on_boss_died() -> void:
	if _state != "boss":
		return
	_clear_enemies()
	_room_cleared(true)


func _room_cleared(was_boss: bool) -> void:
	if _state == "transition":
		return
	_state = "transition"
	GameManager.add_score(150 if was_boss else 25)
	var give_chest := was_boss or randf() < 0.4
	await get_tree().create_timer(0.7).timeout
	if GameManager.is_game_over or not is_inside_tree():
		return
	var m := _main()
	var center: Vector2 = m.center_pos()
	if give_chest:
		var c := CHEST.instantiate()
		get_tree().current_scene.add_child(c)
		c.global_position = center
	if was_boss:
		# Spend your hoard before descending: shrine, forge and workshop.
		var life := SHOP.instantiate()
		life.kind = "life"
		life.cost = 20
		get_tree().current_scene.add_child(life)
		life.global_position = m.nearest_floor_pos(center + Vector2(-90, 40))
		var forge := SHOP.instantiate()
		forge.kind = "forge"
		forge.cost = 25
		get_tree().current_scene.add_child(forge)
		forge.global_position = m.nearest_floor_pos(center + Vector2(90, 40))
		var workshop := SHOP.instantiate()
		workshop.kind = "workshop"
		workshop.cost = 40
		get_tree().current_scene.add_child(workshop)
		workshop.global_position = m.nearest_floor_pos(center + Vector2(0, 90))
	var p := PORTAL.instantiate()
	get_tree().current_scene.add_child(p)
	p.global_position = m.top_pos()
	p.entered.connect(_on_portal)


func _on_portal() -> void:
	_clear_field()
	GameManager.advance()      # Main regenerates the room via room_changed
	if _player and is_instance_valid(_player):
		_player.global_position = _main().spawn_pos()
	_start_after(0.7)


func _clear_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not e._dying:
			e.queue_free()


func _clear_field() -> void:
	_clear_enemies()
	for n in get_tree().get_nodes_in_group("transient"):
		n.queue_free()
