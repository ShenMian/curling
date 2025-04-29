extends Camera3D

# Node the camera follows
@export var target: Node3D

# Camera's position offset relative to the target
@export var offset = Vector3.ZERO

# Interpolation speed for camera movement (higher = snappier)
@export var lerp_factor = 3.0

# Vertical adjustment for the camera's look-at target
@export var lookat_voffset: float

func _physics_process(delta):
	if !target:
		return

	var target_transform = target.global_transform.rotated_local(Vector3.UP, -target.rotation.y)
	target_transform = target_transform.translated_local(offset)
	global_transform = global_transform.interpolate_with(target_transform, lerp_factor * delta)

	var look_at_point = target.global_transform.origin + Vector3(0, lookat_voffset, 0)
	look_at(look_at_point, target.transform.basis.y)
