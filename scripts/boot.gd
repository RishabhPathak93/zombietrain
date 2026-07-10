extends Node
## Entry point: profile is loaded by autoloads; route to the main menu.

func _ready() -> void:
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	await get_tree().process_frame
	Router.go("res://scenes/main_menu.tscn", 0.2)
