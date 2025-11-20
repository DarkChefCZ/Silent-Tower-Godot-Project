extends CanvasLayer

var color_rect: ColorRect
var fade_animation_player: AnimationPlayer


func _ready() -> void:
	color_rect = get_tree().current_scene.find_child("FadeRect", true, true)
	fade_animation_player = get_tree().current_scene.find_child("FadeAnimationPlayer", true, true)
	
	color_rect.visible = true
	fade_animation_player.play("fade_out") 
	await fade_animation_player.animation_finished
	color_rect.visible = false

func fade_to_scene(scene_path: String) -> void:
	color_rect.visible = true
	fade_animation_player.play("fade_in") 
	await fade_animation_player.animation_finished
	
	get_tree().change_scene_to_file(scene_path)
	
	color_rect.visible = true
	fade_animation_player.play("fade_out")
	await fade_animation_player.animation_finished
	color_rect.visible = false

func _on_play_button_button_down() -> void:
	await fade_to_scene("res://scenes/Levels/main_scene.tscn")


func _on_quit_button_button_down() -> void:
	color_rect.visible = true
	fade_animation_player.play("fade_in") 
	await fade_animation_player.animation_finished
	get_tree().quit()
