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
signal victory_triggered

const KILLS_PER_LIFE := 10
const ROOMS_PER_CHAPTER := 4        ## room == ROOMS_PER_CHAPTER is the boss room
const FINAL_CHAPTER := 3            ## beating this chapter's boss wins the run
const VICTORY_BONUS := 500

var coins := 0
var kills := 0
var gems_run := 0              ## gems earned this run (banked to Save immediately)
var score := 0
var chapter := 1
var room := 1
var is_game_over := false
var has_won := false           ## victory reached this run (endless continues after)
var last_run_new_best := false ## set when the run ends; read by the game-over UI
var character_id := "gunner"   ## chosen on the select screen; persists across restarts


func reset_game() -> void:
	coins = 0
	kills = 0
	gems_run = 0
	score = 0
	chapter = 1
	room = 1
	is_game_over = false
	has_won = false
	last_run_new_best = false
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


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


func add_gems(amount: int) -> void:
	gems_run += amount
	score += amount * 5
	score_changed.emit(score)
	Save.add_gems(amount)


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
## Beating the FINAL_CHAPTER boss triggers victory once; play continues (endless).
func advance() -> void:
	if room >= ROOMS_PER_CHAPTER:
		if chapter >= FINAL_CHAPTER and not has_won:
			has_won = true
			add_score(VICTORY_BONUS)
			add_gems(12)
			victory_triggered.emit()
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
	last_run_new_best = Save.record_run(score, chapter, kills, has_won)
	game_over_triggered.emit()


## A run abandoned from the pause menu still counts toward lifetime stats.
func abandon_run() -> void:
	if not is_game_over and (kills > 0 or score > 0):
		last_run_new_best = Save.record_run(score, chapter, kills, has_won)
