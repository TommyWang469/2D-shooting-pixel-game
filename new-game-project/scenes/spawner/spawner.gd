extends Node
## Drives escalating waves. Spawns a mix of slimes and bats away from the player,
## then waits for the room to be cleared before starting the next, harder wave.

signal wave_started(wave: int)

const SLIME := preload("res://scenes/enemy/slime.tscn")
const BAT := preload("res://scenes/enemy/bat.tscn")

@export var room_rect := Rect2(16, 16, 608, 352)

var _between := true          # true while waiting between waves / before first


func _ready() -> void:
	_start_next_wave_after(1.0)


func _process(_delta: float) -> void:
	if GameManager.is_game_over or _between:
		return
	if get_tree().get_nodes_in_group("enemies").is_empty():
		_between = true
		_start_next_wave_after(2.0)


func _start_next_wave_after(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if GameManager.is_game_over or not is_inside_tree():
		return
	_spawn_wave()
	_between = false


func _spawn_wave() -> void:
	var wave := GameManager.wave + 1
	GameManager.set_wave(wave)
	wave_started.emit(wave)

	var count := 3 + wave * 2
	var bats := int(count * clampf(0.2 + wave * 0.06, 0.2, 0.6))
	var slimes := count - bats
	var player := get_tree().get_first_node_in_group("player")
	for i in slimes:
		_spawn(SLIME, player)
	for i in bats:
		_spawn(BAT, player)


func _spawn(scene: PackedScene, player: Node2D) -> void:
	var e := scene.instantiate()
	var world := get_tree().current_scene
	if world == null:
		return
	world.add_child(e)
	e.global_position = _random_spawn_pos(player)


func _random_spawn_pos(player: Node2D) -> Vector2:
	for _attempt in 20:
		var p := Vector2(
			randf_range(room_rect.position.x, room_rect.end.x),
			randf_range(room_rect.position.y, room_rect.end.y)
		)
		if player == null or p.distance_to(player.global_position) > 90.0:
			return p
	return room_rect.get_center()
