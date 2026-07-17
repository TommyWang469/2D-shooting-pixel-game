extends Area2D
## A projectile. Travels in a straight line, damages the first thing it hits that
## has take_damage(), and frees itself on any solid collision or when its life runs out.

var velocity := Vector2.ZERO
var damage := 1
var life := 1.5


func setup(dir: Vector2, speed: float, dmg: int) -> void:
	velocity = dir.normalized() * speed
	damage = dmg
	rotation = dir.angle()


func _ready() -> void:
	$Sprite2D.texture = load("res://assets/bullet.png")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
