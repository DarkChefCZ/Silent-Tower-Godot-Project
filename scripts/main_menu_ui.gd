extends Node

func _ready() -> void:
	Fade.transitionFade("out")

func _process(_delta: float) -> void:
	if Fade.fade_in_finished == true:
		get_tree().change_scene_to_file("res://scenes/Levels/main_scene.tscn")
		Fade.play("fade_in")
		Fade.fade_in_finished = false

func _on_play_button_button_up() -> void:
	Fade.transitionFade("in")
