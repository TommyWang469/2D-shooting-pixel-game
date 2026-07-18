extends Node
## Global "game feel" helpers: camera screen-shake and hit-stop (brief time freeze).
## Autoloaded as `Juice`. Kept tiny and defensive so callers can fire and forget.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Add screen shake. amount ~0.2 small, ~0.5 medium, ~0.8 big.
func shake(amount: float) -> void:
	var cam := get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(amount)


## Briefly slow time for impact. Non-reentrant: ignores calls during an active stop.
func hitstop(scale := 0.06, dur := 0.06) -> void:
	if Engine.time_scale < 0.999:
		return
	Engine.time_scale = scale
	await get_tree().create_timer(dur, true, false, true).timeout
	Engine.time_scale = 1.0
