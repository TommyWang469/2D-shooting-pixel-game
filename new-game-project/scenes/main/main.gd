extends Node2D
## Builds the room (tiled floor + wall colliders), spawns the player, HUD and wave
## spawner, wires them together, and handles restart on game over.

const PLAYER := preload("res://scenes/player/player.tscn")
const HUD := preload("res://scenes/hud/hud.tscn")
const SPAWNER := preload("res://scenes/spawner/spawner.gd")

const ROOM := Vector2(640, 384)
const WALL_T := 16.0

var floor_tex: Texture2D
var wall_tex: Texture2D
var player: Node2D
var hud: CanvasLayer


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor_tex = load("res://assets/floor.png")
	wall_tex = load("res://assets/wall.png")
	GameManager.reset_game()
	_build_walls()
	_spawn_player()
	_add_hud()
	_add_spawner()
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(floor_tex, Rect2(Vector2.ZERO, ROOM), true)
	var w := ROOM.x
	var h := ROOM.y
	draw_texture_rect(wall_tex, Rect2(0, 0, w, WALL_T), true)
	draw_texture_rect(wall_tex, Rect2(0, h - WALL_T, w, WALL_T), true)
	draw_texture_rect(wall_tex, Rect2(0, 0, WALL_T, h), true)
	draw_texture_rect(wall_tex, Rect2(w - WALL_T, 0, WALL_T, h), true)


func _build_walls() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var w := ROOM.x
	var h := ROOM.y
	_add_wall(body, Rect2(0, 0, w, WALL_T))
	_add_wall(body, Rect2(0, h - WALL_T, w, WALL_T))
	_add_wall(body, Rect2(0, 0, WALL_T, h))
	_add_wall(body, Rect2(w - WALL_T, 0, WALL_T, h))


func _add_wall(body: StaticBody2D, rect: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	cs.position = rect.position + rect.size * 0.5
	body.add_child(cs)


func _spawn_player() -> void:
	player = PLAYER.instantiate()
	add_child(player)
	player.global_position = ROOM * 0.5


func _add_hud() -> void:
	hud = HUD.instantiate()
	add_child(hud)
	hud.bind_player(player)


func _add_spawner() -> void:
	var s := Node.new()
	s.set_script(SPAWNER)
	s.room_rect = Rect2(WALL_T, WALL_T, ROOM.x - 2.0 * WALL_T, ROOM.y - 2.0 * WALL_T)
	add_child(s)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and GameManager.is_game_over:
		get_tree().reload_current_scene()
