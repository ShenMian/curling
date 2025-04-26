extends Node3D

@onready var third_person_camera: Camera3D = $ThirdPersonCamera
@onready var top_down_camera: Camera3D = $SubViewportContainer/SubViewport/TopDownCamera
@onready var sheet: Node3D = $Sheet
@onready var stone_group: Node = $Stones
@onready var scoreboard: CanvasLayer = $Scoreboard
@onready var house_origin_marker: Marker3D = $Sheet/HouseOriginMarker

var stone_scene: PackedScene = preload("res://scenes/stone.tscn")

var round: int = 0
var team_color: Color = Color.RED
var is_stone_shot: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	top_down_camera.position = house_origin_marker.global_position
	top_down_camera.position.y = 3.0
	next_round()

func _process(_delta: float) -> void:
	if is_stone_shot:
		calculate_score()

func _input(_event):
	if Input.is_key_pressed(KEY_SPACE):
		var stone = stone_group.get_children()[-1]
		stone.apply_force(Vector3(0.0, 0.0, -1000.0))
		stone.sleeping = false
		is_stone_shot = true

func _on_sheet_out_of_bounds(_stone: Node3D) -> void:
	print("stone out of bounds")

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
	stone_group.add_child(stone)

	third_person_camera.position = stone.position + third_person_camera.offset
	third_person_camera.target = stone
	
	assert(is_stone_shot)
	is_stone_shot = false

func calculate_score() -> void:
	var stones = stone_group.get_children()
	if stones.is_empty():
		return

	if is_stone_shot and stones[-1].sleeping:
		next_round()
	
	var stones_in_house = stones.filter(func(stone): return sheet.is_body_in_house(stone))
	if stones_in_house.is_empty():
		scoreboard.set_blue_score(0)
		scoreboard.set_red_score(0)
		return
	
	var house_origin = house_origin_marker.global_position
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
		scoreboard.set_red_score(score)
		scoreboard.set_blue_score(0)
	else:
		scoreboard.set_blue_score(score)
		scoreboard.set_red_score(0)
