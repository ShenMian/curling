extends RigidBody3D
class_name Stone

@export var color: Color
@export var number: int

@onready var number_label: Label3D = $NumberLabel

func _ready() -> void:
	$Meshes/Body.material_override.albedo_color = color
	number_label.text = str(number)

# Plays the impact sound when the stone collides with another stone.
func _on_body_entered(body: Node) -> void:
	if body is not Stone:
		return
	if $ImpactAudioPlayer.playing:
		return
	$ImpactAudioPlayer.play()
