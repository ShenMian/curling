extends Node3D

@export var indicator_color_curve: Curve

@onready var third_person_camera: Camera3D = $ThirdPersonCamera
@onready var top_down_camera: Camera3D = $SubViewportContainer/SubViewport/TopDownCamera

@onready var sheet: Node3D = $Sheet
@onready var stone_group: Node = $Stones

@onready var tee_line_marker: Marker3D = $Sheet/TeeLineMarker
@onready var house_origin_marker: Marker3D = $Sheet/HouseOriginMarker

@onready var impulse_indicator: Line3D = $ImpulseIndicator
@onready var scoreboard: CanvasLayer = $Scoreboard

var stone_scene: PackedScene = preload("res://scenes/stone.tscn")

var round: int = 0
var team_color: Color = Color.RED

var is_stone_shot: bool = false
var is_stone_drag: bool = false

var impulse_max: float = 150.0
var impulse_factor: float = 150.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	top_down_camera.position = house_origin_marker.global_position
	top_down_camera.position.y = 3.0
	next_round()

func _process(_delta: float) -> void:
	if is_stone_shot:
		calculate_score()

func calculate_clamped_impulse(from: Vector3, to: Vector3) -> Vector3:
	var impulse = (to - from) * impulse_factor
	var length = clamp(impulse.length(), 0.0, impulse_max)
	return impulse.normalized() * length

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var collision = mouse_ray_cast()
		if collision.is_empty():
			return

		var stone = stone_group.get_children()[-1]
		if not is_stone_drag and event.is_pressed() and collision.collider == stone:
			is_stone_drag = true
		elif is_stone_drag and event.is_released() and collision.collider == $Sheet/StaticBody:
			is_stone_drag = false
			impulse_indicator.clear()
			var impulse = calculate_clamped_impulse(collision.position, stone.position)
			stone.apply_central_impulse(impulse)
			stone.sleeping = false
			is_stone_shot = true
			print("stone shot, impulse: %v, length: %f" % [impulse, impulse.length() / impulse_max])
	
	if event is InputEventMouseMotion and is_stone_drag:
		var collision = mouse_ray_cast()
		if collision.is_empty():
			return

		var stone = stone_group.get_children()[-1]
		if is_stone_drag and collision.collider == $Sheet/StaticBody:
			var impulse = calculate_clamped_impulse(collision.position, stone.position)
			var factor = indicator_color_curve.sample(impulse.length() / impulse_max)
			impulse_indicator.color = (1.0 - factor) * Color.RED + factor * Color.GREEN
			impulse_indicator.points = PackedVector3Array([
				stone.position,
				stone.position - impulse / impulse_factor
			])
			impulse_indicator.points[0].y = 0.1
			impulse_indicator.points[1].y = 0.1
			impulse_indicator.rebuild()

func _on_sheet_out_of_bounds(_stone: Node3D) -> void:
	print("stone out of bounds")

func mouse_ray_cast() -> Dictionary:
		var mouse_position = get_viewport().get_mouse_position()
		var ray_origin = third_person_camera.project_ray_origin(mouse_position)
		var ray_end = ray_origin + third_person_camera.project_ray_normal(mouse_position) * 10.0

		var ray_query_params = PhysicsRayQueryParameters3D.new()
		ray_query_params.from = ray_origin
		ray_query_params.to = ray_end

		var space_state = get_world_3d().direct_space_state
		return space_state.intersect_ray(ray_query_params)

func next_round() -> void:
	round += 1
	if round >= 8:
		print("match over")
		return
	team_color = Color.RED if team_color == Color.BLUE else Color.BLUE
	spwan_stone(team_color)

func spwan_stone(color: Color) -> void:
	var stone = stone_scene.instantiate()
	stone.position = tee_line_marker.global_position
	stone.color = color
	stone.number = stone_group.get_children().size() + 1
	stone_group.add_child(stone)

	third_person_camera.position = stone.position + third_person_camera.offset
	third_person_camera.target = stone

func calculate_score() -> void:
	var stones = stone_group.get_children()
	if stones.is_empty():
		return

	if is_stone_shot and stones[-1].sleeping:
		is_stone_shot = false
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
