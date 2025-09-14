extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer3D = $AudioPlayer

# Starts the sweeping animation and sound.
func start_sweep():
	animation_player.play("sweep")
	audio_player.play()


# Stops the sweeping animation and sound.
func stop_sweep():
	animation_player.stop()
	audio_player.stop()
