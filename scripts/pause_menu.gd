extends CanvasLayer

@onready var blur_animation: AnimationPlayer = $BlurAnimation

func open():
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	get_tree().paused = true
	show()
	blur_animation.play("start_pause")


func close():
	hide()
	get_viewport().gui_release_focus()
	get_tree().paused = false


func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if connected:
		$VBoxContainer/ResumeButton.grab_focus()
	else:
		if Input.get_connected_joypads().is_empty():
			get_viewport().gui_release_focus()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_released("pause"):
		get_viewport().set_input_as_handled()
		close()


func _on_resume_button_pressed() -> void:
	close()


func _on_retry_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")
