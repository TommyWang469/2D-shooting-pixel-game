extends Node
## Builds the game's UI look in code and installs it as the root Window theme so
## every Control (HUD panels, pause menu, shops, settings) picks it up at once:
## dark-violet panels with glowing borders, proper button hover/pressed states.
## Autoloaded as `UiTheme`.


func _ready() -> void:
	var t := Theme.new()

	var panel := _box(Color(0.09, 0.07, 0.15, 0.97), Color(0.42, 0.34, 0.68), 2, 5)
	panel.content_margin_left = 8
	panel.content_margin_right = 8
	panel.content_margin_top = 6
	panel.content_margin_bottom = 6
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("panel", "PanelContainer", panel)

	t.set_stylebox("normal", "Button", _box(Color(0.16, 0.13, 0.27), Color(0.45, 0.37, 0.72), 1, 3, 8, 3))
	t.set_stylebox("hover", "Button", _box(Color(0.23, 0.19, 0.38), Color(0.68, 0.58, 1.0), 1, 3, 8, 3))
	t.set_stylebox("pressed", "Button", _box(Color(0.30, 0.24, 0.50), Color(0.85, 0.75, 1.0), 1, 3, 8, 3))
	t.set_stylebox("disabled", "Button", _box(Color(0.12, 0.11, 0.18), Color(0.28, 0.26, 0.38), 1, 3, 8, 3))
	var focus := _box(Color(0, 0, 0, 0), Color(1.0, 0.85, 0.4), 2, 3)
	focus.draw_center = false
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", Color(0.92, 0.90, 1.0))
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color(1.0, 0.95, 0.75))
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.53, 0.65))

	get_window().theme = t


func _box(bg: Color, border: Color, bw: int, radius: int,
		h_margin := -1, v_margin := -1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	if h_margin >= 0:
		sb.content_margin_left = h_margin
		sb.content_margin_right = h_margin
	if v_margin >= 0:
		sb.content_margin_top = v_margin
		sb.content_margin_bottom = v_margin
	return sb
