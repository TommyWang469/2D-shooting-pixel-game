extends RefCounted
class_name DungeonTheme
## Chapter themes, Soul Knight style: each biome changes the room shapes, obstacle
## style, colors/lighting, enemy stats+tint and the boss's favoured attacks.
## Chapters cycle through the catalog (1=Stone, 2=Ember, 3=Frost, 4=Stone...).

const CATALOG := [
	{
		"name": "Stone Halls",
		"ambient": Color(0.86, 0.85, 0.95),
		"floor": Color(0.85, 0.85, 1.0),
		"wall": Color(0.8, 0.78, 0.95),
		"enemy_tint": Color(1.0, 1.0, 1.0),
		"boss_tint": Color(1.0, 1.0, 1.0),
		"hp_mult": 1.0,
		"speed_mult": 1.0,
		"shapes": ["ellipse", "cross", "lobes"],
		"obstacles": "pillars",
		"boss_weights": [1.0, 1.5, 0.8],   # ring, summon, charge -> summoner king
		"roster": [["slime", 0.45], ["bat", 0.35], ["mage", 0.2]],
	},
	{
		"name": "Ember Depths",
		"ambient": Color(1.0, 0.84, 0.72),
		"floor": Color(1.0, 0.72, 0.55),
		"wall": Color(0.95, 0.55, 0.4),
		"enemy_tint": Color(1.0, 0.62, 0.5),
		"boss_tint": Color(1.0, 0.55, 0.45),
		"hp_mult": 1.1,
		"speed_mult": 1.18,
		"shapes": ["blob", "lobes", "donut"],
		"obstacles": "rocks",
		"boss_weights": [0.9, 0.7, 1.8],   # charge-mad magma king
		"roster": [["imp", 0.4], ["spitter", 0.25], ["bat", 0.35]],
	},
	{
		"name": "Frost Crypt",
		"ambient": Color(0.78, 0.88, 1.0),
		"floor": Color(0.72, 0.88, 1.0),
		"wall": Color(0.6, 0.78, 1.0),
		"enemy_tint": Color(0.62, 0.85, 1.0),
		"boss_tint": Color(0.6, 0.85, 1.0),
		"hp_mult": 1.35,
		"speed_mult": 0.88,
		"shapes": ["cross", "donut", "ellipse", "blob"],
		"obstacles": "ice",
		"boss_weights": [1.9, 0.8, 0.7],   # bullet-ring frost king
		"roster": [["ice_slime", 0.4], ["ghost", 0.35], ["mage", 0.25]],
	},
]


static func for_chapter(chapter: int) -> Dictionary:
	return CATALOG[(chapter - 1) % CATALOG.size()]
