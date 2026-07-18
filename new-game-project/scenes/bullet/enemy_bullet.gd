extends Area2D
## Enemy projectile. Damages the player, passes through other enemies, dies on walls.

var velocity := Vector2.ZERO
var damage := 1
var life := 4.0


func setup(dir: Vector2, speed: float, dmg: int) -> void:
	velocity = dir.normalized() * speed
	damage = dmg
	rotation = dir.angle()


func _ready() -> void:
	add_to_group("transient")
	$Sprite2D.texture = load("res://assets/enemy_bullet.png")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		queue_free()
	else:
		queue_free()   # wall
