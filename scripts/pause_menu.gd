extends CanvasLayer

func _ready() -> void:
	hide()

func _input(event):
	if visible:
		return
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().paused = true
		show()
		$BlurAnimation.play("start_pause")

func _on_resume_button_pressed() -> void:
	hide()
	get_tree().paused = false

func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")
