extends Area2D
## A floor pickup. `kind` decides behavior on touch:
##   "coin"  -> adds coins
##   "heart" -> heals the player
##   "crate" -> tries to buy the next weapon upgrade (costs coins)
## Set `kind` and `value` before adding to the tree.

@export var kind := "coin"
@export var value := 1

var _bob := 0.0
var _base_y := 0.0
var _spin := 0.0
var _frame := 0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_base_y = position.y
	match kind:
		"coin":
			sprite.texture = load("res://assets/coin.png")
			sprite.hframes = 4
		"heart":
			sprite.texture = load("res://assets/heart.png")
		"crate":
			sprite.texture = load("res://assets/crate.png")


func _process(delta: float) -> void:
	# gentle bob so pickups read clearly on the floor
	_bob += delta * 4.0
	position.y = _base_y + sin(_bob) * 1.5
	if kind == "coin":
		_spin += delta
		if _spin >= 0.12:
			_spin = 0.0
			_frame = (_frame + 1) % 4
			sprite.frame = _frame


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	match kind:
		"coin":
			GameManager.add_coins(value)
			queue_free()
		"heart":
			if body.has_method("heal"):
				body.heal(value)
			queue_free()
		"crate":
			if body.has_method("try_buy_upgrade") and body.try_buy_upgrade():
				queue_free()
