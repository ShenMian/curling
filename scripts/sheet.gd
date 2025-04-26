extends Node3D

signal body_entered_house(node: Node3D)
signal body_exited_house(node: Node3D)
signal out_of_bounds(node: Node3D)

@onready var house_area: Area3D = $HouseArea

func _on_house_area_body_entered(body: Node3D) -> void:
	body_entered_house.emit(body)

func _on_house_area_body_exited(body: Node3D) -> void:
	body_exited_house.emit(body)

func _on_body_exited(body: Node3D) -> void:
	out_of_bounds.emit(body)

func is_body_in_house(body: Node3D) -> bool:
	return $HouseArea.overlaps_body(body)
