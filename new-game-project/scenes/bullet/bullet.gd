extends Area2D
## Player projectile. Straight-line travel, damages things with take_damage(), can
## pierce multiple enemies, applies knockback, and spits an impact spark on hit.

const BURST := preload("res://scenes/fx/burst.tscn")

var velocity := Vector2.ZERO
var damage := 1
var life := 1.4
var pierce := 0
var knockback := 0.0
var homing := 0.0                 ## rad/s steering toward the nearest enemy
var bounce := 0                   ## remaining wall ricochets
var slow := 0.0                   ## enemy speed factor applied on hit (0 = none)

var _color := Color.WHITE
var _scale := 1.0
var _tex := ""                    ## custom sprite path (pre-colored art)
var _hits := 0


func setup(dir: Vector2, speed: float, dmg: int, opts := {}) -> void:
	velocity = dir.normalized() * speed
	damage = dmg
	rotation = dir.angle()
	life = opts.get("life", 1.4)
	pierce = opts.get("pierce", 0)
	knockback = opts.get("knockback", 0.0)
	_color = opts.get("color", Color.WHITE)
	_scale = opts.get("scale", 1.0)
	homing = opts.get("homing", 0.0)
	bounce = opts.get("bounce", 0)
	slow = opts.get("slow", 0.0)
	_tex = opts.get("tex", "")


func _ready() -> void:
	add_to_group("transient")
	if _tex != "":
		$Sprite2D.texture = load(_tex)   # pre-colored custom projectile art
	else:
		$Sprite2D.texture = load("res://assets/bullet.png")
		$Sprite2D.modulate = _color
	scale = Vector2(_scale, _scale)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if homing > 0.0:
		_steer(delta)
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()


## Curve toward the nearest living enemy within range (Homing Wand).
func _steer(delta: float) -> void:
	var best: Node2D = null
	var best_d := 150.0 * 150.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	if best == null:
		return
	var want := (best.global_position - global_position).angle()
	var ang := rotate_toward(velocity.angle(), want, homing * delta)
	velocity = Vector2.RIGHT.rotated(ang) * velocity.length()
	rotation = ang


func _on_body_entered(body: Node) -> void:
	_spark()
	if body.has_method("take_damage"):
		body.take_damage(damage)
		if knockback > 0.0 and body.has_method("apply_knockback"):
			body.apply_knockback(velocity.normalized() * knockback)
		if slow > 0.0 and body.has_method("apply_slow"):
			body.apply_slow(slow, 1.4)
		_hits += 1
		if _hits > pierce:
			queue_free()
	elif bounce > 0:   # ricochet off the wall
		bounce -= 1
		_reflect()
	else:
		queue_free()   # hit a wall


## Reflect off room walls using the tile grid to guess the surface orientation.
func _reflect() -> void:
	var world := get_tree().current_scene
	var hit_x := _is_wall(world, global_position + Vector2(signf(velocity.x) * 7.0, 0))
	var hit_y := _is_wall(world, global_position + Vector2(0, signf(velocity.y) * 7.0))
	if hit_x:
		velocity.x = -velocity.x
	if hit_y:
		velocity.y = -velocity.y
	if not hit_x and not hit_y:
		velocity = -velocity
	rotation = velocity.angle()
	position += velocity.normalized() * 3.0


func _is_wall(world: Node, p: Vector2) -> bool:
	if world == null or not "grid" in world or world.grid.is_empty():
		return false
	var tx := int(p.x / 16.0)
	var ty := int(p.y / 16.0)
	if tx < 0 or tx >= world.GW or ty < 0 or ty >= world.GH:
		return true
	return not world.grid[ty][tx]


func _spark() -> void:
	var b := BURST.instantiate()
	var world := get_tree().current_scene
	if world:
		world.add_child(b)
		b.global_position = global_position
		b.burst(_color, 5, 60.0)
