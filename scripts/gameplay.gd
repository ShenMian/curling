extends Node3D

var stone_scene: PackedScene = preload("res://scenes/stone.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var stone = stone_scene.instantiate()
	stone.position = Vector3(0.0, 0.0, 0.3)
	stone.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	stone.color = Color.BLUE
	$Stones.add_child(stone)
	$ThirdPersonCamera.target = stone

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _input(_event):
	if Input.is_key_pressed(KEY_SPACE):
		var stone = $"Stones".get_children()[-1]
		stone.apply_force(Vector3(0.0, 0.0, -1000.0))

func _on_sheet_out_of_bounds(_stone: Node3D) -> void:
	print("stone out of bounds")
