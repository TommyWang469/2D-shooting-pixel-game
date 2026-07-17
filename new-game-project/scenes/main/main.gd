extends Node2D
## Room controller. The Player, HUD, Spawner and Walls are authored as child nodes
## in main.tscn; this script draws the tiled floor/walls, wires the HUD to the
## Player, resets run state, and handles restart on game over.

const ROOM := Vector2(640, 384)
const WALL_T := 16.0

var floor_tex: Texture2D
var wall_tex: Texture2D

@onready var player: Node2D = $Player
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor_tex = load("res://assets/floor.png")
	wall_tex = load("res://assets/wall.png")
	GameManager.reset_game()
	hud.bind_player(player)
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(floor_tex, Rect2(Vector2.ZERO, ROOM), true)
	var w := ROOM.x
	var h := ROOM.y
	draw_texture_rect(wall_tex, Rect2(0, 0, w, WALL_T), true)
	draw_texture_rect(wall_tex, Rect2(0, h - WALL_T, w, WALL_T), true)
	draw_texture_rect(wall_tex, Rect2(0, 0, WALL_T, h), true)
	draw_texture_rect(wall_tex, Rect2(w - WALL_T, 0, WALL_T, h), true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and GameManager.is_game_over:
		get_tree().reload_current_scene()
