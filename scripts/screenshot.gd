extends Node

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('screenshot'):
		take_screenshot()

func take_screenshot() -> void:
	get_viewport().get_texture().get_image().save_png('C:/Users/kovar/Documents/GodotProjects/silent-tower/Silent-Tower-Godot-Project/image.png')
