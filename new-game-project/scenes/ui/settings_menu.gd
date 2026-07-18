extends Control
## Settings overlay: volume sliders (Master/Music/SFX), fullscreen and screen-shake
## toggles. Built in code so it can be dropped over any screen (title or pause).
## Values live on the Save autoload and are applied + persisted immediately.

signal closed

var _back_btn: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 100

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(240, 0)
	add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	margin.add_child(vb)

	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	vb.add_child(title)

	vb.add_child(_slider_row("Master", Save.master_volume,
			func(v: float): Save.master_volume = v))
	vb.add_child(_slider_row("Music", Save.music_volume,
			func(v: float): Save.music_volume = v))
	vb.add_child(_slider_row("SFX", Save.sfx_volume,
			func(v: float): Save.sfx_volume = v))

	var fs := CheckBox.new()
	fs.text = "Fullscreen"
	fs.button_pressed = Save.fullscreen
	fs.add_theme_font_size_override("font_size", 12)
	fs.toggled.connect(func(on: bool):
		Save.fullscreen = on
		_apply())
	vb.add_child(fs)

	var shake := CheckBox.new()
	shake.text = "Screen shake"
	shake.button_pressed = Save.screen_shake
	shake.add_theme_font_size_override("font_size", 12)
	shake.toggled.connect(func(on: bool):
		Save.screen_shake = on
		_apply())
	vb.add_child(shake)

	_back_btn = Button.new()
	_back_btn.text = "Back"
	_back_btn.add_theme_font_size_override("font_size", 12)
	_back_btn.pressed.connect(_close)
	vb.add_child(_back_btn)
	_back_btn.grab_focus()


func _slider_row(label_text: String, value: float, setter: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var lab := Label.new()
	lab.text = label_text
	lab.custom_minimum_size = Vector2(52, 0)
	lab.add_theme_font_size_override("font_size", 12)
	row.add_child(lab)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(130, 14)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(v: float):
		setter.call(v)
		_apply()
		if label_text == "SFX":
			Audio.play("click", 0.0, -6.0))
	row.add_child(slider)
	return row


func _apply() -> void:
	Save.apply_settings()
	Save.save()


func _close() -> void:
	Audio.play("click")
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
