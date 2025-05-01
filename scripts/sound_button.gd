extends Button
class_name SoundButton

@onready var press_audio_player: AudioStreamPlayer = UiSound.get_node("PressAudioPlayer")
@onready var hover_audio_player: AudioStreamPlayer = UiSound.get_node("HoverAudioPlayer")

func _ready() -> void:
	self.pressed.connect(_on_pressed)
	self.mouse_entered.connect(_on_hovered)

func _on_pressed() -> void:
	press_audio_player.play()

func _on_hovered() -> void:
	hover_audio_player.play()
