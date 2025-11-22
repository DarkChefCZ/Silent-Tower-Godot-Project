extends Node3D

@export var text: RichTextLabel
@export var audio: AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(3.5).timeout
	audio.playing = true
	await get_tree().create_timer(1.0).timeout
	textShow("Holy Signal", 6.0)
	await get_tree().create_timer(7.0).timeout
	textShow("Game by AK-8", 6.0)
	await get_tree().create_timer(7.0).timeout
	textShow("Made for Game Off 2025", 6.0)
	await get_tree().create_timer(7.0).timeout
	textShow("Special thanks to Buckleworth for help with development", 7.0)
	await get_tree().create_timer(8.0).timeout
	textShow("Thank you for playing", 6.0)

func textShow(message: String, messageDuration: float) -> void:
	
	
	text.text = ""
	
	
	for i in message.length():
		text.text += message[i]
		await get_tree().create_timer(0.01).timeout
	
	var timer = get_tree().create_timer(messageDuration)
	await timer.timeout
	
	text.text = ""


func _on_audio_stream_player_3d_finished() -> void:
	get_tree().change_scene_to_file("res://scenes/Levels/main_menu.tscn")
