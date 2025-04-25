extends Node3D

signal out_of_bounds(node: Node3D)

func is_body_in_house(body: Node3D) -> bool:
	return $HouseArea.overlaps_body(body)

func _on_body_exited(body: Node3D) -> void:
	out_of_bounds.emit(body)
