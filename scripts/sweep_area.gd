extends Node3D

var stone_friction: float

func _input(_event: InputEvent) -> void:
	var stone: Stone = self.get_parent()
	if Input.is_action_just_pressed("sweep"):
		_start_sweep(stone)
	if Input.is_action_just_released("sweep"):
		_stop_sweep(stone)


func _on_sweep_area_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	var stone: Stone = self.get_parent()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_start_sweep(stone)
		elif event.is_released():
			_stop_sweep(stone)


func _on_sweep_area_mouse_exited() -> void:
	var stone: Stone = self.get_parent()
	_stop_sweep(stone)


func _start_sweep(stone: Stone) -> void:
	for broom in stone.get_node("SweepArea/Brooms").get_children():
		broom.visible = true
		broom.start_sweep()
	stone_friction = stone.physics_material_override.friction
	stone.physics_material_override.friction = stone_friction * 0.6


func _stop_sweep(stone: Stone) -> void:
	for broom in stone.get_node("SweepArea/Brooms").get_children():
		broom.visible = false
		broom.stop_sweep()
	stone.physics_material_override.friction = stone_friction
