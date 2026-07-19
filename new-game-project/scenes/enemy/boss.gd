extends Enemy
## Chapter boss. Each biome fields a different boss: its own pixel art, stats and
## attack kit (set `kind` before add_child). Attacks speed up as health drops.
## Emits health_changed (boss bar) and died (dungeon advance).
##
##  stone — THE SUMMONER KING: bullet ring, add summons, staggered double-ring quake.
##  ember — THE MAGMA TYRANT: fast, aimed eruption volleys and relentless charges.
##  frost — THE FROZEN WARDEN: slow tank, rotating spiral barrage, ice-shard spawns.

signal health_changed(current: int, maximum: int)
signal died

const EBULLET := preload("res://scenes/bullet/enemy_bullet.tscn")
const SLIME := preload("res://scenes/enemy/slime.tscn")
const BAT := preload("res://scenes/enemy/bat.tscn")
const ICE_SLIME := preload("res://scenes/enemy/ice_slime.tscn")

const KINDS := {
	"stone": {
		"sprite": "res://assets/boss_stone.png",
		"hp": 42, "speed": 34.0, "contact_damage": 2,
		"attacks": [["_ring", 1.0], ["_summon", 1.4], ["_quake", 1.0], ["_charge", 0.5]],
	},
	"ember": {
		"sprite": "res://assets/boss_ember.png",
		"hp": 38, "speed": 42.0, "contact_damage": 2,
		"attacks": [["_eruption", 1.4], ["_charge", 1.6], ["_ring", 0.6]],
	},
	"frost": {
		"sprite": "res://assets/boss_frost.png",
		"hp": 54, "speed": 26.0, "contact_damage": 2,
		"attacks": [["_spiral", 1.4], ["_ring", 1.0], ["_shards", 1.0]],
	},
}

var kind := "stone"                 ## set by the dungeon BEFORE add_child

var _attack_cd := 2.5
var _state := "move"
var _attacking := false             ## an async attack pattern is running
var _charge_dir := Vector2.ZERO
var _charge_t := 0.0


func _ready() -> void:
	var cfg: Dictionary = KINDS.get(kind, KINDS["stone"])
	max_hp = cfg["hp"]
	speed = cfg["speed"]
	contact_damage = cfg["contact_damage"]
	contact_range = 20.0
	coin_chance = 1.0
	coin_min = 18
	coin_max = 28
	gem_min = 4
	gem_max = 6
	heart_chance = 1.0
	sheet_hframes = 4
	death_frame = 3
	body_color = Color(0.5, 0.9, 0.5)
	super._ready()
	max_hp = int(round(max_hp * GameManager.difficulty()))
	hp = max_hp
	add_to_group("boss")
	call_deferred("emit_signal", "health_changed", hp, max_hp)


func _load_texture() -> void:
	var cfg: Dictionary = KINDS.get(kind, KINDS["stone"])
	sprite.texture = load(cfg["sprite"])


func _ai_velocity(delta: float) -> Vector2:
	_attack_timer(delta)
	if _state == "charge":
		_charge_t -= delta
		if _charge_t <= 0.0:
			_state = "move"
		return _charge_dir * speed * 4.2
	return (player.global_position - global_position).normalized() * speed


func _attack_timer(delta: float) -> void:
	_attack_cd -= delta
	if _attack_cd <= 0.0 and not _attacking and _state == "move" \
			and not GameManager.is_game_over:
		_do_attack()
		var frac := float(hp) / float(max_hp)
		_attack_cd = lerpf(1.1, 2.8, frac)


func _do_attack() -> void:
	var attacks: Array = KINDS.get(kind, KINDS["stone"])["attacks"]
	var total := 0.0
	for a in attacks:
		total += a[1]
	var r := randf() * total
	for a in attacks:
		r -= a[1]
		if r <= 0.0:
			call(a[0])
			return


func _alive() -> bool:
	return not _dying and is_inside_tree() and not GameManager.is_game_over


func _shoot(dir: Vector2, spd: float) -> void:
	var world := get_tree().current_scene
	if world == null:
		return
	var b := EBULLET.instantiate()
	world.add_child(b)
	b.global_position = global_position
	b.setup(dir, spd, contact_damage)


# --- shared attacks ----------------------------------------------------------
func _ring() -> void:
	var n := 12
	for i in n:
		_shoot(Vector2.RIGHT.rotated(TAU * i / n), 125.0)
	Audio.play("shoot", 0.05, -2.0)
	sprite.frame = 2


func _charge() -> void:
	if player and is_instance_valid(player):
		_charge_dir = (player.global_position - global_position).normalized()
		_state = "charge"
		_charge_t = 0.5
		Juice.shake(0.2)


func _summon() -> void:
	var world := get_tree().current_scene
	if world == null:
		return
	for i in 2:
		var scene: PackedScene = SLIME if randf() < 0.5 else BAT
		var e := scene.instantiate()
		world.add_child(e)
		e.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))


# --- stone signature: two staggered rings, offset half a step ---------------
func _quake() -> void:
	_attacking = true
	sprite.frame = 2
	Juice.shake(0.3)
	var n := 8
	for i in n:
		_shoot(Vector2.RIGHT.rotated(TAU * i / n), 105.0)
	Audio.play("shoot", 0.05, -2.0)
	await get_tree().create_timer(0.35, false).timeout
	if _alive():
		for i in n:
			_shoot(Vector2.RIGHT.rotated(TAU * (i + 0.5) / n), 145.0)
		Audio.play("shoot", 0.05, -1.0)
	_attacking = false


# --- ember signature: three aimed 5-way volleys ------------------------------
func _eruption() -> void:
	_attacking = true
	sprite.frame = 2
	for volley in 3:
		if not _alive() or player == null or not is_instance_valid(player):
			break
		var dir := (player.global_position - global_position).normalized()
		for a in [-0.5, -0.25, 0.0, 0.25, 0.5]:
			_shoot(dir.rotated(a), 150.0)
		Audio.play("shoot", 0.1, -3.0)
		Juice.shake(0.12)
		await get_tree().create_timer(0.24, false).timeout
	_attacking = false


# --- frost signature: rotating spiral barrage --------------------------------
func _spiral() -> void:
	_attacking = true
	sprite.frame = 2
	var base := randf() * TAU
	for i in 14:
		if not _alive():
			break
		_shoot(Vector2.RIGHT.rotated(base + TAU * i * 2.0 / 14.0), 115.0)
		if i % 3 == 0:
			Audio.play("shoot", 0.08, -6.0)
		await get_tree().create_timer(0.07, false).timeout
	_attacking = false


# --- frost signature: spawn chasing ice shards -------------------------------
func _shards() -> void:
	var world := get_tree().current_scene
	if world == null:
		return
	sprite.frame = 2
	for offset in [Vector2(-22, 8), Vector2(22, -8)]:
		var shard := ICE_SLIME.instantiate()
		shard.mini = true
		world.add_child(shard)
		shard.global_position = global_position + offset
		shard.apply_theme(base_tint, 1.0, 1.0)
	Audio.play("wave", 0.1, -6.0)


func _animate(delta: float) -> void:
	_anim_time += delta
	if _anim_time >= 0.25:
		_anim_time = 0.0
		_frame = (_frame + 1) % 2
	if _state != "charge" and not _attacking:
		sprite.frame = _frame


func take_damage(amount: int) -> void:
	if _dying:
		return
	super.take_damage(amount)
	health_changed.emit(maxi(hp, 0), max_hp)


func _die() -> void:
	# Run the base death first: it removes us from the "enemies" group, so the
	# dungeon's _clear_enemies() (triggered by died) can't double-free the boss.
	Juice.shake(0.9)
	Juice.hitstop(0.12, 0.12)
	_spawn_burst(body_color, 40, 170.0)
	super._die()
	died.emit()
