extends Node3D

@export var text: RichTextLabel
@export var audio: AudioStreamPlayer3D
@export var typingSound: AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await get_tree().create_timer(3.5).timeout
	audio.playing = true
	await get_tree().create_timer(1.0).timeout
	textShow("Holy Signal")
	await get_tree().create_timer(7.0).timeout
	textShow("Game by AK-8")
	await get_tree().create_timer(7.0).timeout
	textShow("Made for Game Off 2025")
	await get_tree().create_timer(7.0).timeout
	textShow("Special thanks to Buckleworth for help with development")
	await get_tree().create_timer(8.0).timeout
	textShow("Thank you for playing")

func textShow(message: String) -> void:
	
	
	text.text = ""
	
	
	for i in message.length():
		text.text += message[i]
		typingSound.play()
		await get_tree().create_timer(0.02).timeout


func _on_audio_stream_player_3d_finished() -> void:
	get_tree().change_scene_to_file("res://scenes/Levels/main_menu.tscn")
