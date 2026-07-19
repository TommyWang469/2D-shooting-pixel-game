extends Area2D
## A weapon lying on the ground. Shows its name and a "[E] Swap" prompt when the
## player is near. Pressing interact equips it and drops the player's old weapon here,
## so weapons are never lost — you can walk over and pick an old one back up.

var weapon: Weapon
var _player_near := false
var _bob := 0.0

@onready var icon: Sprite2D = $Icon
@onready var name_label: Label = $Name
@onready var hint: Label = $Hint


func _ready() -> void:
	add_to_group("transient")
	add_to_group("interactables")
	icon.texture = load("res://assets/weapon_icon.png")
	if has_node("Shadow"):
		$Shadow.texture = load("res://assets/shadow.png")
	hint.visible = false
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	_refresh()


func set_weapon(w: Weapon) -> void:
	weapon = w
	_refresh()


func _refresh() -> void:
	if weapon and name_label:
		name_label.text = weapon.display_name
		if weapon.icon != "":
			icon.texture = load(weapon.icon)   # unique pre-colored art
			icon.modulate = Color.WHITE
		else:
			icon.modulate = weapon.bullet_color


func _process(delta: float) -> void:
	_bob += delta * 3.0
	icon.position.y = -1.0 + sin(_bob) * 1.5


func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		hint.visible = true


func _on_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		hint.visible = false


func player_near() -> bool:
	return _player_near


func interact(player: Node) -> void:
	if player.has_method("take_weapon_from"):
		player.take_weapon_from(self)
