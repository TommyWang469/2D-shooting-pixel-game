extends Node
## Global run state: economy, kills, and dungeon progression (chapters / rooms /
## boss). Autoloaded as `GameManager`. A chapter is ROOMS_PER_CHAPTER rooms; the
## last room of every chapter is a boss fight. Each chapter is harder.

signal coins_changed(total: int)
signal kills_changed(total: int)
signal score_changed(score: int)
signal chapter_changed(chapter: int)
signal room_changed(room: int)
signal bonus_life
signal game_over_triggered

const KILLS_PER_LIFE := 10
const ROOMS_PER_CHAPTER := 4        ## room == ROOMS_PER_CHAPTER is the boss room

var coins := 0
var kills := 0
var score := 0
var chapter := 1
var room := 1
var is_game_over := false


func reset_game() -> void:
	coins = 0
	kills = 0
	score = 0
	chapter = 1
	room = 1
	is_game_over = false
	Engine.time_scale = 1.0
	coins_changed.emit(coins)
	kills_changed.emit(kills)
	score_changed.emit(score)
	chapter_changed.emit(chapter)
	room_changed.emit(room)


func add_coins(amount: int) -> void:
	coins += amount
	score += amount
	coins_changed.emit(coins)
	score_changed.emit(score)


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


func is_boss_room() -> bool:
	return room >= ROOMS_PER_CHAPTER


## Move to the next room, rolling into a new (harder) chapter after the boss.
func advance() -> void:
	if room >= ROOMS_PER_CHAPTER:
		chapter += 1
		room = 1
		chapter_changed.emit(chapter)
		room_changed.emit(room)
	else:
		room += 1
		room_changed.emit(room)


## Difficulty multiplier used for enemy counts / HP / speed.
func difficulty() -> float:
	return 1.0 + (chapter - 1) * 0.65 + (room - 1) * 0.18


func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over_triggered.emit()
