extends Node2D
## Soul-Knight-style guide arrow orbiting the player. Points at the nearest enemy
## when only a few remain (find that last hiding spitter!), and at the exit portal
## once the room is clear.

const RADIUS := 26.0


func _ready() -> void:
	z_index = 20


func _process(_delta: float) -> void:
	var target := Vector2.INF
	var col := Color(1.0, 0.4, 0.4)
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.size() > 0 and enemies.size() <= 3:
		var best_d := 1.0e12
		for e in enemies:
			if not is_instance_valid(e):
				continue
			var d := global_position.distance_squared_to(e.global_position)
			if d < best_d:
				best_d = d
				target = e.global_position
	elif enemies.is_empty():
		for p in get_tree().get_nodes_in_group("portal"):
			if is_instance_valid(p):
				target = p.global_position
				col = Color(0.75, 0.6, 1.0)
				break
	if target == Vector2.INF or global_position.distance_to(target) < 40.0:
		visible = false
		return
	visible = true
	rotation = (target - global_position).angle()
	modulate = col


func _draw() -> void:
	# chevron pointing +X, orbiting at RADIUS
	draw_polygon(PackedVector2Array([
		Vector2(RADIUS + 7, 0), Vector2(RADIUS - 2, -5), Vector2(RADIUS - 2, 5),
	]), [Color.WHITE])
