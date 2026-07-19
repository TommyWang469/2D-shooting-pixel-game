extends Node2D
## Procedural themed rooms on a 40x24 tile grid, Soul Knight style. Every room is
## carved with a random silhouette (ellipse / cave blob / cross / lobed chambers /
## donut ring), gets theme-specific obstacles (pillars / rocks / ice shards), is
## connectivity-checked, then rendered from the grid and given merged wall colliders.
## Also exposes floor-aware spawn helpers used by the Dungeon for every placement.

const TILE := 16
const GW := 40
const GH := 24
const ROOM := Vector2(GW * TILE, GH * TILE)

var theme: Dictionary = {}
var grid: Array = []                     # grid[y][x] -> true = floor
var floor_tiles: Array[Vector2i] = []
var open_tiles: Array[Vector2i] = []     # floor whose 4 neighbours are floor too

var floor_tex: Texture2D
var floor_tex_b: Texture2D               ## hash-picked variant tile
var wall_tex: Texture2D
var _wall_body: StaticBody2D
var _torch_root: Node2D
var _decor_root: Node2D
var _ambient: CPUParticles2D

@onready var player: Node2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var canvas_modulate: CanvasModulate = $CanvasModulate


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	Input.set_custom_mouse_cursor(load("res://assets/crosshair.png"),
			Input.CURSOR_ARROW, Vector2(7, 7))
	GameManager.reset_game()
	hud.bind_player(player)
	GameManager.room_changed.connect(func(_r): _regen_room())
	_regen_room()
	player.global_position = spawn_pos()


# ================================================================ generation
func _regen_room() -> void:
	theme = DungeonTheme.for_chapter(GameManager.chapter)
	canvas_modulate.color = theme.ambient
	var tiles: String = theme.get("tiles", "stone")
	floor_tex = load("res://assets/floor_%s.png" % tiles)
	floor_tex_b = load("res://assets/floor_%s_b.png" % tiles)
	wall_tex = load("res://assets/wall_%s.png" % tiles)
	Audio.play_music("boss" if GameManager.is_boss_room() else theme.get("music", "stone"))
	_gen_grid(GameManager.is_boss_room())
	_build_collision()
	_place_torches()
	_place_decor(tiles)
	_make_ambient(tiles)
	queue_redraw()


func _gen_grid(boss_room: bool) -> void:
	_fill_walls()
	if boss_room:
		_carve_ellipse(GW / 2.0, GH / 2.0, 16.5, 9.8)
	else:
		var shape: String = theme.shapes[randi() % theme.shapes.size()]
		match shape:
			"ellipse":
				_carve_ellipse(GW / 2.0 + randf_range(-2, 2), GH / 2.0 + randf_range(-1, 1),
						randf_range(13.0, 16.0), randf_range(7.5, 9.5))
			"cross":
				var hw := randi_range(3, 5)
				var vw := randi_range(4, 6)
				_carve_rect(2, GH / 2 - hw, GW - 3, GH / 2 + hw)
				_carve_rect(GW / 2 - vw, 2, GW / 2 + vw, GH - 3)
			"blob":
				_carve_blob()
			"lobes":
				_carve_lobes()
			"donut":
				_carve_ellipse(GW / 2.0, GH / 2.0, 15.5, 9.3)
				_uncarve_ellipse(GW / 2.0, GH / 2.0, randf_range(5.0, 7.0), randf_range(2.8, 4.0))
			_:
				_carve_ellipse(GW / 2.0, GH / 2.0, 14.0, 8.5)
	_seal_border()
	_keep_largest_region()
	if not boss_room:
		_add_obstacles(str(theme.obstacles))
		_seal_border()
		_keep_largest_region()
	_collect_tiles()
	# Safety net: a degenerate roll falls back to a plain hall.
	if open_tiles.size() < 90:
		_fill_walls()
		_carve_ellipse(GW / 2.0, GH / 2.0, 15.0, 9.0)
		_seal_border()
		_keep_largest_region()
		_collect_tiles()


func _fill_walls() -> void:
	grid = []
	for y in GH:
		var row := []
		row.resize(GW)
		row.fill(false)
		grid.append(row)


func _carve_ellipse(cx: float, cy: float, rx: float, ry: float) -> void:
	for y in GH:
		for x in GW:
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				grid[y][x] = true


func _uncarve_ellipse(cx: float, cy: float, rx: float, ry: float) -> void:
	for y in GH:
		for x in GW:
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				grid[y][x] = false


func _carve_rect(x0: int, y0: int, x1: int, y1: int) -> void:
	for y in range(maxi(0, y0), mini(GH, y1 + 1)):
		for x in range(maxi(0, x0), mini(GW, x1 + 1)):
			grid[y][x] = true


func _carve_blob() -> void:
	# Cellular-automata cave: random seed then 4 smoothing passes.
	for y in range(2, GH - 2):
		for x in range(2, GW - 2):
			grid[y][x] = randf() < 0.58
	for _pass in 4:
		var next := []
		for y in GH:
			next.append(grid[y].duplicate())
		for y in range(1, GH - 1):
			for x in range(1, GW - 1):
				var n := 0
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						if (dx != 0 or dy != 0) and grid[y + dy][x + dx]:
							n += 1
				next[y][x] = n >= 5 if grid[y][x] else n >= 6
		grid = next


func _carve_lobes() -> void:
	var count := randi_range(2, 3)
	var centers: Array[Vector2] = []
	for i in count:
		var c := Vector2(randf_range(8, GW - 8), randf_range(6, GH - 6))
		centers.append(c)
		_carve_ellipse(c.x, c.y, randf_range(6.0, 9.0), randf_range(4.5, 6.5))
	# L-shaped corridors linking the lobes
	for i in range(1, centers.size()):
		var a := centers[i - 1]
		var b := centers[i]
		_carve_rect(int(minf(a.x, b.x)), int(a.y) - 1, int(maxf(a.x, b.x)), int(a.y) + 1)
		_carve_rect(int(b.x) - 1, int(minf(a.y, b.y)), int(b.x) + 1, int(maxf(a.y, b.y)))


func _seal_border() -> void:
	for x in GW:
		grid[0][x] = false
		grid[GH - 1][x] = false
	for y in GH:
		grid[y][0] = false
		grid[y][GW - 1] = false


func _keep_largest_region() -> void:
	var label := []
	for y in GH:
		var row := []
		row.resize(GW)
		row.fill(-1)
		label.append(row)
	var sizes := []
	for y in GH:
		for x in GW:
			if grid[y][x] and label[y][x] == -1:
				var id := sizes.size()
				var n := 0
				var stack: Array[Vector2i] = [Vector2i(x, y)]
				label[y][x] = id
				while not stack.is_empty():
					var t: Vector2i = stack.pop_back()
					n += 1
					for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						var q: Vector2i = t + d
						if q.x >= 0 and q.x < GW and q.y >= 0 and q.y < GH \
								and grid[q.y][q.x] and label[q.y][q.x] == -1:
							label[q.y][q.x] = id
							stack.append(q)
				sizes.append(n)
	if sizes.is_empty():
		return
	var best := 0
	for i in sizes.size():
		if sizes[i] > sizes[best]:
			best = i
	for y in GH:
		for x in GW:
			if grid[y][x] and label[y][x] != best:
				grid[y][x] = false


func _add_obstacles(style: String) -> void:
	var candidates: Array[Vector2i] = []
	var c := Vector2(GW / 2.0, GH / 2.0)
	for y in range(2, GH - 2):
		for x in range(2, GW - 2):
			if grid[y][x] and Vector2(x, y).distance_to(c) > 5.5:
				candidates.append(Vector2i(x, y))
	if candidates.is_empty():
		return
	match style:
		"pillars":
			for i in randi_range(3, 6):
				var t := candidates[randi() % candidates.size()]
				for dy in [0, 1]:
					for dx in [0, 1]:
						_set_wall(t.x + dx, t.y + dy)
		"rocks":
			for i in randi_range(5, 9):
				var t := candidates[randi() % candidates.size()]
				var cur := t
				for step in randi_range(2, 4):
					_set_wall(cur.x, cur.y)
					cur += [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)][randi() % 4]
		"ice":
			for i in randi_range(3, 6):
				var t := candidates[randi() % candidates.size()]
				var horiz := randf() < 0.5
				for step in randi_range(3, 5):
					_set_wall(t.x + (step if horiz else 0), t.y + (0 if horiz else step))


func _set_wall(x: int, y: int) -> void:
	if x > 0 and x < GW - 1 and y > 0 and y < GH - 1:
		grid[y][x] = false


func _collect_tiles() -> void:
	floor_tiles.clear()
	open_tiles.clear()
	for y in range(1, GH - 1):
		for x in range(1, GW - 1):
			if not grid[y][x]:
				continue
			floor_tiles.append(Vector2i(x, y))
			if grid[y - 1][x] and grid[y + 1][x] and grid[y][x - 1] and grid[y][x + 1]:
				open_tiles.append(Vector2i(x, y))
	if open_tiles.is_empty():
		open_tiles = floor_tiles.duplicate()


# ================================================================ world building
func _build_collision() -> void:
	if is_instance_valid(_wall_body):
		_wall_body.queue_free()
	_wall_body = StaticBody2D.new()
	_wall_body.collision_layer = 1
	_wall_body.collision_mask = 0
	add_child(_wall_body)
	# Merge horizontal runs of edge-walls into single rectangle shapes.
	for y in GH:
		var x := 0
		while x < GW:
			if _is_solid_wall(x, y):
				var x0 := x
				while x < GW and _is_solid_wall(x, y):
					x += 1
				var cs := CollisionShape2D.new()
				var shape := RectangleShape2D.new()
				shape.size = Vector2((x - x0) * TILE, TILE)
				cs.shape = shape
				cs.position = Vector2((x0 + (x - x0) * 0.5) * TILE, y * TILE + TILE * 0.5)
				_wall_body.add_child(cs)
			else:
				x += 1


func _is_solid_wall(x: int, y: int) -> bool:
	# Wall tiles that touch a floor tile (the reachable shell of the room).
	if grid[y][x]:
		return false
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var q := Vector2i(x + dx, y + dy)
			if q.x >= 0 and q.x < GW and q.y >= 0 and q.y < GH and grid[q.y][q.x]:
				return true
	return false


func _draw() -> void:
	if grid.is_empty():
		return
	var fcol: Color = theme.get("floor", Color.WHITE)
	var wcol: Color = theme.get("wall", Color.WHITE)
	for y in GH:
		for x in GW:
			var r := Rect2(x * TILE, y * TILE, TILE, TILE)
			if grid[y][x]:
				# deterministic sprinkle of the B variant breaks up repetition
				var tex := floor_tex_b if (x * 31 + y * 17) % 7 == 0 else floor_tex
				draw_texture_rect(tex, r, false, fcol)
			elif _is_solid_wall(x, y):
				draw_texture_rect(wall_tex, r, false, wcol)


func _place_torches() -> void:
	if is_instance_valid(_torch_root):
		_torch_root.queue_free()
	_torch_root = Node2D.new()
	add_child(_torch_root)
	for q in [Vector2(0.28, 0.28), Vector2(0.72, 0.28), Vector2(0.28, 0.72), Vector2(0.72, 0.72)]:
		_make_torch(nearest_floor_pos(Vector2(ROOM.x * q.x, ROOM.y * q.y)) + Vector2(0, -4))


func _make_torch(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	_torch_root.add_child(root)

	var glow := Sprite2D.new()
	glow.texture = load("res://assets/glow.png")
	glow.modulate = Color(1.0, 0.65, 0.3, 0.55)
	glow.scale = Vector2(1.6, 1.6)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.position = Vector2(0, -2)
	root.add_child(glow)

	var body := Sprite2D.new()
	body.texture = load("res://assets/torch.png")
	root.add_child(body)

	var flame := CPUParticles2D.new()
	flame.texture = load("res://assets/spark.png")
	flame.amount = 12
	flame.lifetime = 0.5
	flame.direction = Vector2(0, -1)
	flame.spread = 22.0
	flame.gravity = Vector2(0, -45)
	flame.initial_velocity_min = 12.0
	flame.initial_velocity_max = 32.0
	flame.scale_amount_min = 0.6
	flame.scale_amount_max = 1.4
	flame.color = Color(1.0, 0.6, 0.22)
	flame.position = Vector2(0, -6)
	root.add_child(flame)


## Scatter a few biome decals (bones, fissures, crystals…) on open floor tiles.
## Inserted before the Player in the tree so everything walks over them.
func _place_decor(tiles: String) -> void:
	if is_instance_valid(_decor_root):
		_decor_root.queue_free()
	_decor_root = Node2D.new()
	add_child(_decor_root)
	move_child(_decor_root, 1)   # after CanvasModulate, before Player
	var texs: Array = []
	for i in [1, 2, 3]:
		texs.append(load("res://assets/decor_%s_%d.png" % [tiles, i]))
	for i in randi_range(7, 13):
		var s := Sprite2D.new()
		s.texture = texs[randi() % texs.size()]
		s.position = tile_to_world(open_tiles[randi() % open_tiles.size()]) \
				+ Vector2(randf_range(-3, 3), randf_range(-3, 3))
		if randf() < 0.5:
			s.flip_h = true
		_decor_root.add_child(s)


## One ambient particle field per biome: dust motes / rising embers / snowfall.
func _make_ambient(tiles: String) -> void:
	if is_instance_valid(_ambient):
		_ambient.queue_free()
	_ambient = CPUParticles2D.new()
	_ambient.texture = load("res://assets/spark.png")
	_ambient.position = ROOM * 0.5
	_ambient.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_ambient.emission_rect_extents = ROOM * 0.5
	_ambient.spread = 180.0
	_ambient.z_index = 1
	match tiles:
		"ember":
			_ambient.amount = 18
			_ambient.lifetime = 3.0
			_ambient.direction = Vector2(0, -1)
			_ambient.gravity = Vector2(0, -14)
			_ambient.initial_velocity_min = 4.0
			_ambient.initial_velocity_max = 14.0
			_ambient.color = Color(1.0, 0.55, 0.2, 0.55)
			_ambient.scale_amount_min = 0.5
			_ambient.scale_amount_max = 1.0
		"frost":
			_ambient.amount = 26
			_ambient.lifetime = 5.0
			_ambient.direction = Vector2(0.3, 1)
			_ambient.gravity = Vector2(4, 10)
			_ambient.initial_velocity_min = 3.0
			_ambient.initial_velocity_max = 9.0
			_ambient.color = Color(0.95, 0.98, 1.0, 0.6)
			_ambient.scale_amount_min = 0.4
			_ambient.scale_amount_max = 0.9
		_:
			_ambient.amount = 10
			_ambient.lifetime = 4.5
			_ambient.direction = Vector2(0, -1)
			_ambient.gravity = Vector2(0, -3)
			_ambient.initial_velocity_min = 1.0
			_ambient.initial_velocity_max = 4.0
			_ambient.color = Color(0.8, 0.8, 0.9, 0.28)
			_ambient.scale_amount_min = 0.4
			_ambient.scale_amount_max = 0.8
	add_child(_ambient)


# ================================================================ spawn helpers
func tile_to_world(t: Vector2i) -> Vector2:
	return Vector2(t.x * TILE + TILE * 0.5, t.y * TILE + TILE * 0.5)


## Random open floor position, at least min_dist away from `avoid` when possible.
func random_floor_pos(avoid := Vector2.INF, min_dist := 0.0) -> Vector2:
	for i in 40:
		var p := tile_to_world(open_tiles[randi() % open_tiles.size()])
		if avoid == Vector2.INF or p.distance_to(avoid) >= min_dist:
			return p
	return tile_to_world(open_tiles[randi() % open_tiles.size()])


## Open floor position closest to a target point.
func nearest_floor_pos(target: Vector2) -> Vector2:
	var best := tile_to_world(open_tiles[0])
	var best_d := best.distance_squared_to(target)
	for t in open_tiles:
		var p := tile_to_world(t)
		var d := p.distance_squared_to(target)
		if d < best_d:
			best_d = d
			best = p
	return best


func spawn_pos() -> Vector2:
	return nearest_floor_pos(ROOM * 0.5 + Vector2(0, 44))


func center_pos() -> Vector2:
	return nearest_floor_pos(ROOM * 0.5)


func top_pos() -> Vector2:
	return nearest_floor_pos(Vector2(ROOM.x * 0.5, 56))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and GameManager.is_game_over:
		get_tree().paused = false
		get_tree().reload_current_scene()
