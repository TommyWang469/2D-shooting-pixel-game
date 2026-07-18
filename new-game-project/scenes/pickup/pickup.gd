extends Area2D
## Floor pickup. "coin" adds coins, "heart" heals the player. Both bob for visibility
## and get vacuumed toward the player once they're close (magnet).

const FLOAT := preload("res://scenes/fx/floating_text.tscn")
const MAGNET_RADIUS := 44.0
const MAGNET_SPEED := 180.0

@export var kind := "coin"
@export var value := 1

var _bob := 0.0
var _base_y := 0.0
var _base_set := false
var _spin := 0.0
var _frame := 0
var _player: Node2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("transient")
	body_entered.connect(_on_body_entered)
	_player = get_tree().get_first_node_in_group("player")
	match kind:
		"coin":
			sprite.texture = load("res://assets/coin.png")
			sprite.hframes = 4
		"heart":
			sprite.texture = load("res://assets/heart.png")


func _process(delta: float) -> void:
	if not _base_set:
		_base_y = position.y   # capture after spawn code has set our position
		_base_set = true
	_bob += delta * 4.0
	if kind == "coin":
		_spin += delta
		if _spin >= 0.12:
			_spin = 0.0
			_frame = (_frame + 1) % 4
			sprite.frame = _frame
	if _player and is_instance_valid(_player):
		var d := global_position.distance_to(_player.global_position)
		if d < MAGNET_RADIUS:
			global_position = global_position.move_toward(_player.global_position, MAGNET_SPEED * delta)
			return
	position.y = _base_y + sin(_bob) * 1.5


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	match kind:
		"coin":
			GameManager.add_coins(value)
			Audio.play("coin", 0.14, -7.0)
			_float("+%d" % value, Color(1.0, 0.85, 0.35))
			queue_free()
		"heart":
			if body.has_method("heal"):
				body.heal(value)
			queue_free()


func _float(text: String, color: Color) -> void:
	var f := FLOAT.instantiate()
	var world := get_tree().current_scene
	if world:
		world.add_child(f)
		f.global_position = global_position
		f.setup(text, color, 20.0, 11)
