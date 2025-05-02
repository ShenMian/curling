extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer3D = $AudioPlayer

func start_sweep() -> void:
	animation_player.play("sweep")
	audio_player.play()

func stop_sweep() -> void:
	animation_player.stop()
	audio_player.stop()
