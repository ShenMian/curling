extends CanvasLayer

@onready var blur_animation: AnimationPlayer = $BlurAnimation

func open():
	get_tree().paused = true
	show()
	blur_animation.play("start_pause")

func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
