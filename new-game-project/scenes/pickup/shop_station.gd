extends Area2D
## Boss-room shop station. "life" sells +1 max HP (heals fully); "forge" sells a new,
## stronger weapon (dropped as a ground pickup to choose). Cost rises each purchase.
## Press interact when near to buy.

const WEAPON_PICKUP := preload("res://scenes/pickup/weapon_pickup.tscn")
const FLOAT := preload("res://scenes/fx/floating_text.tscn")
const BURST := preload("res://scenes/fx/burst.tscn")

@export var kind := "life"          # "life" or "forge"
@export var cost := 20

var _player_near := false
var _t := 0.0

@onready var icon: Sprite2D = $Icon
@onready var glow: Sprite2D = $Glow
@onready var name_label: Label = $Name
@onready var hint: Label = $Hint


func _ready() -> void:
	add_to_group("transient")
	add_to_group("interactables")
	if has_node("Shadow"):
		$Shadow.texture = load("res://assets/shadow.png")
	glow.texture = load("res://assets/glow.png")
	if kind == "life":
		icon.texture = load("res://assets/heart.png")
		icon.scale = Vector2(2, 2)
		glow.modulate = Color(1.0, 0.4, 0.5, 0.5)
	else:
		icon.texture = load("res://assets/crate.png")
		glow.modulate = Color(1.0, 0.8, 0.4, 0.5)
	hint.visible = false
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	_refresh()


func _refresh() -> void:
	if not name_label:
		return
	name_label.text = ("Buy Life  %d" % cost) if kind == "life" else ("New Weapon  %d" % cost)


func _process(delta: float) -> void:
	_t += delta
	var p := 1.4 + sin(_t * 3.0) * 0.2
	glow.scale = Vector2(p, p)


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
	if GameManager.coins < cost:
		_deny()
		return
	GameManager.spend_coins(cost)
	Audio.play("upgrade")
	_buy_pop()
	if kind == "life":
		if player.has_method("gain_max_hp"):
			player.gain_max_hp()
		cost += 10
	else:
		var w := Weapon.random_reward(player.weapon_power(), player.weapon_id())
		var wp := WEAPON_PICKUP.instantiate()
		get_tree().current_scene.add_child(wp)
		wp.global_position = global_position + Vector2(0, 22)
		wp.set_weapon(w)
		cost += 15
	_refresh()


func _buy_pop() -> void:
	var b := BURST.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = global_position
	b.burst(Color(1.0, 0.5, 0.6) if kind == "life" else Color(1.0, 0.8, 0.4), 16, 100.0)
	var base := icon.scale
	var tw := icon.create_tween()
	tw.tween_property(icon, "scale", base * 1.4, 0.08)
	tw.tween_property(icon, "scale", base, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _deny() -> void:
	Audio.play("hurt", 0.1, -8.0)
	var f := FLOAT.instantiate()
	get_tree().current_scene.add_child(f)
	f.global_position = global_position + Vector2(0, -14)
	f.setup("Need %d coins" % cost, Color(1.0, 0.5, 0.5), 20.0, 11)
