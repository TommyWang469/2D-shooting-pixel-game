extends Enemy
## Frost biome: crystalline slime. Slow and tanky — and when it dies it shatters
## into two fast little shards that keep chasing. Shards don't split again.

const SELF_SCENE := "res://scenes/enemy/ice_slime.tscn"

@export var mini := false


func _ready() -> void:
	if mini:
		max_hp = 1
		speed = 92.0
		contact_damage = 1
		coin_chance = 0.25
		coin_min = 1
		coin_max = 1
		heart_chance = 0.02
		scale = Vector2(0.55, 0.55)
	else:
		max_hp = 5
		speed = 30.0
		contact_damage = 1
		coin_chance = 0.7
		coin_min = 2
		coin_max = 3
		heart_chance = 0.14
	sheet_hframes = 4
	death_frame = 3
	body_color = Color(0.6, 0.85, 0.95)
	super._ready()
	var d := GameManager.difficulty()
	max_hp = int(round(max_hp * (0.7 + d * 0.3)))
	hp = max_hp


func _load_texture() -> void:
	sprite.texture = load("res://assets/ice_slime.png")


func _ai_velocity(_delta: float) -> Vector2:
	return (player.global_position - global_position).normalized() * speed


func _animate(delta: float) -> void:
	_anim_time += delta
	if _anim_time >= 0.2 if not mini else _anim_time >= 0.1:
		_anim_time = 0.0
		_frame = (_frame + 1) % 3
	sprite.frame = _frame


func _die() -> void:
	var was_mini := mini
	var pos := global_position
	var tint := base_tint
	super._die()
	if was_mini:
		return
	# shatter into two chasing shards
	var world := get_tree().current_scene
	if world == null:
		return
	for offset in [Vector2(-10, 4), Vector2(10, -4)]:
		var shard = load(SELF_SCENE).instantiate()
		shard.mini = true
		world.add_child(shard)
		shard.global_position = pos + offset
		shard.apply_theme(tint, 1.0, 1.0)
