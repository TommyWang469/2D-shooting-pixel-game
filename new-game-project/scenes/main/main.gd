extends Node2D
## Room controller. Draws the tiled floor/walls (retinted per chapter), places
## atmospheric torches, binds the HUD to the player, starts music, and handles
## restart. The Player, Dungeon, HUD and Walls are authored as child nodes.

const ROOM := Vector2(640, 384)
const WALL_T := 16.0

# per-chapter mood tints (cycled)
const THEMES := [
	Color(0.85, 0.85, 1.0),   # blue stone
	Color(1.0, 0.9, 0.8),     # warm sandstone
	Color(0.85, 1.0, 0.88),   # mossy
	Color(1.0, 0.85, 0.95),   # crimson
]

var floor_tex: Texture2D
var wall_tex: Texture2D
var _tint := Color.WHITE

@onready var player: Node2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var canvas_modulate: CanvasModulate = $CanvasModulate


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor_tex = load("res://assets/floor.png")
	wall_tex = load("res://assets/wall.png")
	GameManager.reset_game()
	hud.bind_player(player)
	_add_torches()
	GameManager.chapter_changed.connect(_retint)
	_retint(GameManager.chapter)
	Audio.play_music()


func _retint(chapter: int) -> void:
	_tint = THEMES[(chapter - 1) % THEMES.size()]
	canvas_modulate.color = _tint.lerp(Color(0.86, 0.85, 0.95), 0.4)
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(floor_tex, Rect2(Vector2.ZERO, ROOM), true, _tint)
	var w := ROOM.x
	var h := ROOM.y
	var wt := _tint.darkened(0.05)
	draw_texture_rect(wall_tex, Rect2(0, 0, w, WALL_T), true, wt)
	draw_texture_rect(wall_tex, Rect2(0, h - WALL_T, w, WALL_T), true, wt)
	draw_texture_rect(wall_tex, Rect2(0, 0, WALL_T, h), true, wt)
	draw_texture_rect(wall_tex, Rect2(w - WALL_T, 0, WALL_T, h), true, wt)


func _add_torches() -> void:
	for pos in [Vector2(40, 46), Vector2(600, 46), Vector2(40, 340), Vector2(600, 340)]:
		_make_torch(pos)


func _make_torch(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	add_child(root)

	var glow := Sprite2D.new()
	glow.texture = load("res://assets/glow.png")
	glow.modulate = Color(1.0, 0.65, 0.3, 0.55)
	glow.scale = Vector2(1.6, 1.6)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.position = Vector2(0, -2)
	root.add_child(glow)

	var body := Sprite2D.new()
	body.texture = load("res://assets/torch.png")
	root.add_child(body)

	var flame := CPUParticles2D.new()
	flame.texture = load("res://assets/spark.png")
	flame.amount = 12
	flame.lifetime = 0.5
	flame.direction = Vector2(0, -1)
	flame.spread = 22.0
	flame.gravity = Vector2(0, -45)
	flame.initial_velocity_min = 12.0
	flame.initial_velocity_max = 32.0
	flame.scale_amount_min = 0.6
	flame.scale_amount_max = 1.4
	flame.color = Color(1.0, 0.6, 0.22)
	flame.position = Vector2(0, -6)
	root.add_child(flame)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and GameManager.is_game_over:
		get_tree().paused = false
		get_tree().reload_current_scene()
