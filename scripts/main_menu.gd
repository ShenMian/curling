extends CanvasLayer

func _ready() -> void:
	$Options/StartButton.grab_focus()


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()
