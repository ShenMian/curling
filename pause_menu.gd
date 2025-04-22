extends CanvasLayer

func _input(event):
	if Input.is_key_pressed(KEY_ESCAPE):
		show()
		$BlurAnimation.play("start_pause")

func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	hide()

func _on_quit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
