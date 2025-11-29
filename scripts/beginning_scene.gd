extends Node3D

@export var text: RichTextLabel
@export var transitionLayer: CanvasLayer
@export var typingSound: AudioStreamPlayer3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await get_tree().create_timer(1.0).timeout
	textShow("I ran as fast as I could")
	await get_tree().create_timer(6.5).timeout
	textShow("They tried to stop me, but He didn't let them")
	await get_tree().create_timer(6.5).timeout
	textShow("He is a divine being, do they not see that?")
	await get_tree().create_timer(6.5).timeout
	textShow("I will fulfil my purpose")
	await get_tree().create_timer(5.5).timeout
	transitionLayer.color_rect.visible = true
	transitionLayer.fade_animation_player.play("fade_in") 
	await transitionLayer.fade_animation_player.animation_finished
	get_tree().change_scene_to_file("res://scenes/Levels/main_scene.tscn")

func textShow(message: String) -> void:
	
	
	text.text = ""
	
	
	for i in message.length():
		text.text += message[i]
		typingSound.play()
		await get_tree().create_timer(0.02).timeout
	
	
