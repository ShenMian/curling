extends CanvasLayer

func _ready():
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")


func _on_exit_button_pressed():
	get_tree().quit()


func _on_joy_connection_changed(_device: int, connected: bool):
	if connected:
		$Options/StartButton.grab_focus()
	else:
		if Input.get_connected_joypads().is_empty():
			get_viewport().gui_release_focus()
