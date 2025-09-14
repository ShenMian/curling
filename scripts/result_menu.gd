extends CanvasLayer

@onready var label: Label = $Label
@onready var scoreboard: Scoreboard = $Scoreboard
@onready var blur_animation: AnimationPlayer = $BlurAnimation

func open():
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	get_tree().paused = true
	$VBoxContainer/RetryButton.grab_focus()
	
	var red_score = scoreboard.red_total_score()
	var blue_score = scoreboard.blue_total_score()
	var winner_color: Color
	var team_name: String
	if red_score > blue_score:
		winner_color = Color.RED
		team_name = "RED_TEAM_WINS"
	elif blue_score > red_score:
		winner_color = Color.BLUE
		team_name = "BLUE_TEAM_WINS"
	else:
		winner_color = Color.YELLOW
		team_name = "TWO_TEAMS_TIED"
	label.text = team_name
	label.add_theme_color_override("font_color", winner_color)
	
	show()
	blur_animation.play("start_pause")


func _on_joy_connection_changed(_device: int, connected: bool):
	if connected:
		$VBoxContainer/RetryButton.grab_focus()
	else:
		if Input.get_connected_joypads().is_empty():
			get_viewport().gui_release_focus()


func _on_retry_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")
