extends CharacterBody2D
class_name Enemy
## Base enemy: HP, hit-flash, contact damage to the player, death drops, and a small
## animation driver. Subclasses (Slime, Bat) override _ai(), _load_texture() and
## _animate() for their movement and looks.

const PICKUP := preload("res://scenes/pickup/pickup.tscn")

@export var max_hp := 3
@export var speed := 42.0
@export var contact_damage := 1
@export var contact_range := 12.0
@export var coin_min := 1
@export var coin_max := 2
@export var heart_chance := 0.12
@export var sheet_hframes := 4
@export var death_frame := 3

var hp := 3
var player: Node2D
var _hit_flash := 0.0
var _contact_cd := 0.0
var _anim_time := 0.0
var _frame := 0
var _dying := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	sprite.hframes = sheet_hframes
	_load_texture()
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if _dying:
		return
	if GameManager.is_game_over:
		velocity = Vector2.ZERO
		return
	if player and is_instance_valid(player):
		_ai(delta)
		move_and_slide()
	_tick(delta)


# --- overridable hooks -------------------------------------------------------
func _ai(_delta: float) -> void:
	pass


func _load_texture() -> void:
	pass


func _animate(_delta: float) -> void:
	pass


# --- shared per-frame logic --------------------------------------------------
func _tick(delta: float) -> void:
	if _contact_cd > 0.0:
		_contact_cd -= delta
	if player and is_instance_valid(player) and not GameManager.is_game_over:
		if global_position.distance_to(player.global_position) < contact_range and _contact_cd <= 0.0:
			if player.has_method("take_damage"):
				player.take_damage(contact_damage)
				_contact_cd = 0.5

	if _hit_flash > 0.0:
		_hit_flash -= delta
		sprite.modulate = Color(2.2, 2.2, 2.2)
	else:
		sprite.modulate = Color.WHITE

	_animate(delta)


func take_damage(amount: int) -> void:
	if _dying:
		return
	hp -= amount
	_hit_flash = 0.1
	if hp <= 0:
		_die()


func _die() -> void:
	_dying = true
	set_physics_process(false)
	remove_from_group("enemies")
	GameManager.register_kill()
	_drop_loot()
	velocity = Vector2.ZERO
	sprite.modulate = Color.WHITE
	sprite.frame = death_frame
	get_tree().create_timer(0.25).timeout.connect(queue_free)


func _drop_loot() -> void:
	var count := randi_range(coin_min, coin_max)
	for i in count:
		_spawn_pickup("coin", 1, Vector2(randf_range(-8, 8), randf_range(-8, 8)))
	if randf() < heart_chance:
		_spawn_pickup("heart", 1, Vector2.ZERO)


func _spawn_pickup(kind: String, value: int, offset: Vector2) -> void:
	var p := PICKUP.instantiate()
	p.kind = kind
	p.value = value
	var world := get_tree().current_scene
	if world:
		world.add_child(p)
		p.global_position = global_position + offset
