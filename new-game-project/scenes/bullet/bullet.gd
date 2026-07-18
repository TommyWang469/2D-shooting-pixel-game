extends Area2D
## Player projectile. Straight-line travel, damages things with take_damage(), can
## pierce multiple enemies, applies knockback, and spits an impact spark on hit.

const BURST := preload("res://scenes/fx/burst.tscn")

var velocity := Vector2.ZERO
var damage := 1
var life := 1.4
var pierce := 0
var knockback := 0.0

var _color := Color.WHITE
var _scale := 1.0
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


func _ready() -> void:
	add_to_group("transient")
	$Sprite2D.texture = load("res://assets/bullet.png")
	$Sprite2D.modulate = _color
	scale = Vector2(_scale, _scale)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	_spark()
	if body.has_method("take_damage"):
		body.take_damage(damage)
		if knockback > 0.0 and body.has_method("apply_knockback"):
			body.apply_knockback(velocity.normalized() * knockback)
		_hits += 1
		if _hits > pierce:
			queue_free()
	else:
		queue_free()   # hit a wall


func _spark() -> void:
	var b := BURST.instantiate()
	var world := get_tree().current_scene
	if world:
		world.add_child(b)
		b.global_position = global_position
		b.burst(_color, 5, 60.0)
