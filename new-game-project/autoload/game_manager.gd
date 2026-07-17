extends Node
## Global game state: economy, kills, waves, and the "gain a life every N kills"
## milestone. Autoloaded as `GameManager`. Systems talk to it through signals so
## they stay decoupled.

signal coins_changed(total: int)
signal kills_changed(total: int)
signal wave_changed(wave: int)
signal score_changed(score: int)
signal bonus_life                     ## emitted every KILLS_PER_LIFE kills
signal game_over_triggered

const KILLS_PER_LIFE := 10

var coins := 0
var kills := 0
var wave := 0
var score := 0
var is_game_over := false


func reset_game() -> void:
	coins = 0
	kills = 0
	wave = 0
	score = 0
	is_game_over = false
	coins_changed.emit(coins)
	kills_changed.emit(kills)
	wave_changed.emit(wave)
	score_changed.emit(score)


func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)


func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		coins_changed.emit(coins)
		return true
	return false


func register_kill() -> void:
	kills += 1
	score += 10
	kills_changed.emit(kills)
	score_changed.emit(score)
	if kills % KILLS_PER_LIFE == 0:
		bonus_life.emit()


func set_wave(n: int) -> void:
	wave = n
	wave_changed.emit(wave)


func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over_triggered.emit()
