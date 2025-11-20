extends Node

@export var transition_screen: CanvasLayer

func _ready() -> void:
	transition_screen.transitionFade("out")

func _process(_delta: float) -> void:
	if transition_screen.fade_in_finished == true:
		get_tree().change_scene_to_file("res://scenes/Levels/main_menu.tscn")
