extends Camera3D

# The target node that the camera will follow
@export var target: Node3D

# The offset position from the target
@export var offset = Vector3.ZERO

# How quickly the camera interpolates to the target position (higher = faster)
@export var lerp_factor = 3.0

func _physics_process(delta):
	if !target:
		return

	var target_transform = target.global_transform.rotated_local(Vector3.UP, -target.rotation.y)
	target_transform = target_transform.translated_local(offset)
	global_transform = global_transform.interpolate_with(target_transform, lerp_factor * delta)

	look_at(target.global_transform.origin, target.transform.basis.y)
