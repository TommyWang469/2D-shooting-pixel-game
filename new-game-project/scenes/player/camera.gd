extends Camera2D
## Trauma-based screen shake. Juice.shake() feeds trauma; shake magnitude scales
## with trauma squared for a punchy-then-quick-settle feel.

@export var decay := 6.0
@export var max_offset := 5.0
@export var max_roll := 0.05

var trauma := 0.0
var _t := 0.0


func _ready() -> void:
	add_to_group("camera")


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	_t += delta
	if trauma > 0.0:
		trauma = maxf(trauma - decay * delta, 0.0)
		var amt := trauma * trauma
		offset = Vector2(max_offset * amt * _n(_t * 34.0, 1.0),
						 max_offset * amt * _n(_t * 29.0, 7.3))
		rotation = max_roll * amt * _n(_t * 41.0, 3.1)
	elif offset != Vector2.ZERO or rotation != 0.0:
		offset = offset.lerp(Vector2.ZERO, 0.3)
		rotation = lerp(rotation, 0.0, 0.3)


func _n(t: float, s: float) -> float:
	return sin(t + s) * cos(t * 1.37 + s * 2.1)
