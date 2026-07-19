extends Node
## Cross-boot persistence driver (temporary autoload, dev only). Each boot banks
## 5 gems and prints before/after — running the game twice must show the second
## boot STARTING from the first boot's total. Proves gems accumulate across runs.


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var before := Save.gems
	Save.add_gems(5)
	print("PERSIST: booted_with=%d banked_5 now=%d" % [before, Save.gems])
	get_tree().quit(0)
