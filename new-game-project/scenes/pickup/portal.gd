extends Area2D
## Exit portal. Appears when a room is cleared; stepping into it advances to the next
## room (or chapter). Animated swirl + gentle pulse.

signal entered

var _anim := 0.0
var _frame := 0
var _t := 0.0
var _used := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("transient")
	sprite.texture = load("res://assets/portal.png")
	sprite.hframes = 4
	scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_anim += delta
	if _anim >= 0.12:
		_anim = 0.0
		_frame = (_frame + 1) % 4
		sprite.frame = _frame
	_t += delta
	sprite.rotation = _t * 1.5


func _on_body_entered(body: Node) -> void:
	if _used or not body.is_in_group("player"):
		return
	_used = true
	Audio.play("upgrade", 0.1, -3.0)
	entered.emit()
