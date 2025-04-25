extends RigidBody3D

@export var color: Color

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.2
	$Meshes/Body.set_material_override(material)
