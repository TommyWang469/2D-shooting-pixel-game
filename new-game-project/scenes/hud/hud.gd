extends CanvasLayer
## On-screen display: hearts (current/max HP), coin count, wave number, current
## weapon, and the game-over panel. Reads GameManager signals for economy/waves and
## binds to the player for HP/weapon updates.

var _heart_full: Texture2D
var _hp := 0
var _max_hp := 0

@onready var hearts_box: HBoxContainer = $HeartsBox
@onready var coin_label: Label = $CoinLabel
@onready var wave_label: Label = $WaveLabel
@onready var weapon_label: Label = $WeaponLabel
@onready var game_over_panel: Control = $GameOver
@onready var final_label: Label = $GameOver/Panel/Final


func _ready() -> void:
	_heart_full = load("res://assets/heart.png")
	game_over_panel.visible = false
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.game_over_triggered.connect(_on_game_over)
	_on_coins_changed(GameManager.coins)
	_on_wave_changed(GameManager.wave)


## Wire the HUD to a specific player instance and show its current state now.
func bind_player(player: Node) -> void:
	player.hp_changed.connect(_on_hp_changed)
	player.weapon_changed.connect(_on_weapon_changed)
	_on_hp_changed(player.hp, player.max_hp)
	if player.weapon:
		_on_weapon_changed(player.weapon.display_name)


func _on_hp_changed(current: int, maximum: int) -> void:
	_hp = current
	_max_hp = maximum
	_rebuild_hearts()


func _rebuild_hearts() -> void:
	for c in hearts_box.get_children():
		c.queue_free()
	for i in _max_hp:
		var tr := TextureRect.new()
		tr.texture = _heart_full
		tr.custom_minimum_size = Vector2(18, 18)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.modulate = Color.WHITE if i < _hp else Color(0.25, 0.18, 0.22, 1.0)
		hearts_box.add_child(tr)


func _on_coins_changed(total: int) -> void:
	coin_label.text = "Coins: %d" % total


func _on_wave_changed(wave: int) -> void:
	wave_label.text = "Wave %d" % wave


func _on_weapon_changed(display_name: String) -> void:
	weapon_label.text = display_name


func _on_game_over() -> void:
	final_label.text = "GAME OVER\n\nScore: %d\nWaves cleared: %d\n\nPress R to Restart" % [
		GameManager.score, max(0, GameManager.wave - 1)
	]
	game_over_panel.visible = true
