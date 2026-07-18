extends Node
## Runs the dungeon: spawns each room's enemies (or the chapter boss), detects
## clears, then drops rewards and the exit portal. All placement is floor-aware —
## it asks the Main room generator for valid tiles — and every spawn is themed to
## the current biome (tint, stats, boss attack pattern).

const SLIME := preload("res://scenes/enemy/slime.tscn")
const BAT := preload("res://scenes/enemy/bat.tscn")
const MAGE := preload("res://scenes/enemy/mage.tscn")
const BOSS := preload("res://scenes/enemy/boss.tscn")
const CHEST := preload("res://scenes/pickup/chest.tscn")
const PORTAL := preload("res://scenes/pickup/portal.tscn")
const SHOP := preload("res://scenes/pickup/shop_station.tscn")
const PICKUP := preload("res://scenes/pickup/pickup.tscn")

var _state := "idle"          # idle / combat / boss / transition
var _hud: Node
var _player: Node2D


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_hud = get_tree().get_first_node_in_group("hud")
	_start_after(1.2)


func _main() -> Node:
	return get_parent()


func _theme() -> Dictionary:
	return DungeonTheme.for_chapter(GameManager.chapter)


func _process(_delta: float) -> void:
	if GameManager.is_game_over:
		return
	if _state == "combat" and get_tree().get_nodes_in_group("enemies").is_empty():
		_room_cleared(false)


func _start_after(delay: float) -> void:
	_state = "transition"
	await get_tree().create_timer(delay).timeout
	if GameManager.is_game_over or not is_inside_tree():
		return
	_begin_room()


func _begin_room() -> void:
	if _hud and _hud.has_method("hide_boss"):
		_hud.hide_boss()
	var biome: String = _theme().name
	if GameManager.is_boss_room():
		_banner("CHAPTER %d" % GameManager.chapter, "%s  ·  BOSS" % biome, Color(1.0, 0.5, 0.5))
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
	var total := 3 + int(round(d * 2.5))
	for i in total:
		var r := randf()
		var scene := SLIME
		if d > 1.3 and r < 0.22:
			scene = MAGE
		elif r < 0.5:
			scene = BAT
		_spawn(scene)
	_scatter_loot()


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
		e.queue_free()


func _clear_field() -> void:
	_clear_enemies()
	for n in get_tree().get_nodes_in_group("transient"):
		n.queue_free()
