extends Node
## Persistence: settings (audio volumes, fullscreen, screen shake) and lifetime
## records (best score, totals, victories). Autoloaded as `Save`, stored as JSON at
## user://save.json. Settings are applied on boot and saved whenever they change.

const PATH := "user://save.json"

signal settings_applied
signal gems_changed(total: int)

## Permanent upgrade catalog: id -> tiers (cost + per-tier effect described in UI).
const UPGRADES := {
	"vitality": {"name": "Vitality", "desc": "+1 starting max HP", "costs": [25, 50, 90]},
	"power": {"name": "Power", "desc": "+10% weapon damage", "costs": [30, 60, 100]},
	"swiftness": {"name": "Swiftness", "desc": "+5% move speed", "costs": [20, 45]},
	"recovery": {"name": "Recovery", "desc": "-8% dash cooldown", "costs": [20, 45]},
	"fortune": {"name": "Fortune", "desc": "+20% coin drops", "costs": [25, 55]},
	"magnet": {"name": "Magnet", "desc": "+12px pickup magnet", "costs": [15, 35]},
}

# --- settings (0..1 volumes) ---
var master_volume := 1.0
var music_volume := 1.0
var sfx_volume := 1.0
var fullscreen := false
var screen_shake := true

# --- lifetime records ---
var best_score := 0
var best_chapter := 0
var total_runs := 0
var total_kills := 0
var victories := 0

# --- meta progression ---
var gems := 0
var upgrades := {}                     ## id -> owned tier (int)
var heroes := ["gunner"]               ## unlocked character ids


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	apply_settings()


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if not data is Dictionary:
		return
	master_volume = clampf(float(data.get("master_volume", 1.0)), 0.0, 1.0)
	music_volume = clampf(float(data.get("music_volume", 1.0)), 0.0, 1.0)
	sfx_volume = clampf(float(data.get("sfx_volume", 1.0)), 0.0, 1.0)
	fullscreen = bool(data.get("fullscreen", false))
	screen_shake = bool(data.get("screen_shake", true))
	best_score = int(data.get("best_score", 0))
	best_chapter = int(data.get("best_chapter", 0))
	total_runs = int(data.get("total_runs", 0))
	total_kills = int(data.get("total_kills", 0))
	victories = int(data.get("victories", 0))
	gems = int(data.get("gems", 0))
	var u: Variant = data.get("upgrades", {})
	upgrades = {}
	if u is Dictionary:
		for k in u:
			if UPGRADES.has(k):
				upgrades[k] = int(u[k])
	var h: Variant = data.get("heroes", ["gunner"])
	heroes = ["gunner"]
	if h is Array:
		for id in h:
			if not heroes.has(id):
				heroes.append(str(id))
	# Grandfather clause: saves from before the meta system keep all heroes.
	if not data.has("heroes") and int(data.get("total_runs", 0)) > 0:
		heroes = ["gunner", "knight", "rogue"]


func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Save: could not write %s" % PATH)
		return
	f.store_string(JSON.stringify({
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"fullscreen": fullscreen,
		"screen_shake": screen_shake,
		"best_score": best_score,
		"best_chapter": best_chapter,
		"total_runs": total_runs,
		"total_kills": total_kills,
		"victories": victories,
		"gems": gems,
		"upgrades": upgrades,
		"heroes": heroes,
	}, "  "))


## Push current settings into the engine (audio buses + window mode).
func apply_settings() -> void:
	_set_bus("Master", master_volume)
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)
	var mode := DisplayServer.window_get_mode()
	var is_fs := mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if fullscreen != is_fs and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED)
	settings_applied.emit()


func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(idx, linear <= 0.001)


# ================================================================ meta progression
func add_gems(amount: int) -> void:
	gems += amount
	gems_changed.emit(gems)
	save()


func upgrade_level(id: String) -> int:
	return int(upgrades.get(id, 0))


func upgrade_next_cost(id: String) -> int:
	## -1 when maxed.
	var costs: Array = UPGRADES[id]["costs"]
	var lvl := upgrade_level(id)
	return -1 if lvl >= costs.size() else int(costs[lvl])


func buy_upgrade(id: String) -> bool:
	var cost := upgrade_next_cost(id)
	if cost < 0 or gems < cost:
		return false
	gems -= cost
	upgrades[id] = upgrade_level(id) + 1
	gems_changed.emit(gems)
	save()
	return true


func is_hero_unlocked(id: String) -> bool:
	return heroes.has(id)


func unlock_hero(id: String, cost: int) -> bool:
	if heroes.has(id) or gems < cost:
		return false
	gems -= cost
	heroes.append(id)
	gems_changed.emit(gems)
	save()
	return true


## Record a finished run (death or quit-to-title mid-run). Returns true if the
## score is a new best.
func record_run(score: int, chapter: int, kills: int, won := false) -> bool:
	total_runs += 1
	total_kills += kills
	best_chapter = maxi(best_chapter, chapter)
	if won:
		victories += 1
	var new_best := score > best_score
	if new_best:
		best_score = score
	save()
	return new_best
