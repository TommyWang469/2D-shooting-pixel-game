extends Node2D
## Small combat text that rises and fades. Instantiate, add to scene, then call
## setup(text, color). Used for damage numbers, "+1" coins, weapon names, etc.

var life := 0.8
var _t := 0.0
var _rise := 24.0


func setup(text: String, color := Color.WHITE, rise := 24.0, size := 12) -> void:
	$Label.text = text
	$Label.modulate = color
	$Label.add_theme_font_size_override("font_size", size)
	_rise = rise


func _process(delta: float) -> void:
	_t += delta
	position.y -= _rise * delta
	modulate.a = clampf(1.0 - _t / life, 0.0, 1.0)
	if _t >= life:
		queue_free()
