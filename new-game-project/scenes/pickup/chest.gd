extends Area2D
## Treasure chest. Walk into it to open it and switch to a new, more powerful weapon.
## A glow and bob draw the eye. If no weapon is preset, it rolls a reward based on the
## player's current weapon power.

const WEAPON_PICKUP := preload("res://scenes/pickup/weapon_pickup.tscn")

var _weapon: Weapon
var _opened := false
var _t := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow: Sprite2D = $Glow


func _ready() -> void:
	add_to_group("transient")
	sprite.texture = load("res://assets/chest.png")
	sprite.hframes = 2
	sprite.frame = 0
	if has_node("Shadow"):
		$Shadow.texture = load("res://assets/shadow.png")
	glow.texture = load("res://assets/glow.png")
	glow.modulate = Color(1.0, 0.85, 0.4, 0.5)
	body_entered.connect(_on_body_entered)


func set_weapon(w: Weapon) -> void:
	_weapon = w


func _process(delta: float) -> void:
	_t += delta
	if not _opened:
		var pulse := 0.9 + sin(_t * 3.0) * 0.15
		glow.scale = Vector2(pulse, pulse)
		glow.modulate.a = 0.35 + sin(_t * 3.0) * 0.15
	else:
		glow.modulate.a = maxf(glow.modulate.a - delta, 0.0)


func _on_body_entered(body: Node) -> void:
	if _opened or not body.is_in_group("player"):
		return
	_opened = true
	sprite.frame = 1
	Audio.play("upgrade", 0.1, -3.0)
	if _weapon == null:
		_weapon = Weapon.random_reward(body.weapon_power(), body.weapon_id())
	# Drop the reward on the ground so the player can choose to take it.
	var wp := WEAPON_PICKUP.instantiate()
	var world := get_tree().current_scene
	if world:
		world.add_child(wp)
		wp.global_position = global_position + Vector2(0, 20)
		wp.set_weapon(_weapon)
