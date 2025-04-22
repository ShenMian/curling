extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Stone.get_node("RigidBody3D").apply_force(Vector3(-650.0, 0.0, -650.0))
