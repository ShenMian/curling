extends Node3D

var stone_scene: PackedScene = preload("res://scenes/stone.tscn")

var round: int = 0
var team_color: Color = Color.RED
var is_stone_shot: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	next_round()

func next_round() -> void:
	round += 1
	if round >= 8:
		print("match over")
		return
	team_color = Color.RED if team_color == Color.BLUE else Color.BLUE
	spwan_stone(team_color)

func spwan_stone(color: Color) -> void:
	var stone = stone_scene.instantiate()
	stone.position = Vector3(0.0, 0.0, 27.3)
	stone.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	stone.color = color
	$Stones.add_child(stone)

	var camera = $ThirdPersonCamera
	camera.position = stone.position + camera.offset
	camera.target = stone
	
	assert(is_stone_shot)
	is_stone_shot = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var stones = $Stones.get_children()
	if stones.is_empty():
		return

	var last_stone = $Stones.get_children()[-1]
	if is_stone_shot and last_stone.sleeping:
		next_round()

	var top_down_camera = $SubViewportContainer/SubViewport/TopDownCamera
	var camera_position = Vector2(top_down_camera.position.x, top_down_camera.position.z)
	var house_origin = Vector3(top_down_camera.position.x, 0.0, top_down_camera.position.z)
	
	var stones_in_house = stones.filter(func(stone): return $Sheet.is_body_in_house(stone))
	if stones_in_house.is_empty():
		$Score.set_blue_score(0)
		$Score.set_red_score(0)
		return
	
	var sorted_stones = stones_in_house.duplicate()
	sorted_stones.sort_custom(func(a, b):
		return a.position.distance_to(house_origin) < b.position.distance_to(house_origin)
	)
	var winning_color = sorted_stones[0].color

	var score = 0
	for stone in sorted_stones:
		if stone.color == winning_color:
			score += 1
		else:
			break
	
	if winning_color == Color.RED:
		$Score.set_red_score(score)
		$Score.set_blue_score(0)
	else:
		$Score.set_blue_score(score)
		$Score.set_red_score(0)

func _input(_event):
	if Input.is_key_pressed(KEY_SPACE):
		var stone = $Stones.get_children()[-1]
		stone.apply_force(Vector3(0.0, 0.0, -1000.0))
		stone.sleeping = false
		is_stone_shot = true

func _on_sheet_out_of_bounds(_stone: Node3D) -> void:
	print("stone out of bounds")
