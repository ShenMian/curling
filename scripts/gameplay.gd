extends Node3D

signal shot_started(stone: Node3D)
signal shot_finished(stone: Node3D)

# Curve used to determine the color of the impulse indicator based on impulse strength
@export var indicator_color_curve: Curve

# Friction coefficient between the stone and the ice
@export_range(0.006, 0.016) var stone_friction: float = 0.016

# Number of ends in a match
@export_range(1, 10) var ends_per_match: int = 8

# Number of shots per end
@export_range(2, 16) var shots_per_end: int = 16

@onready var third_person_camera: Camera3D = $ThirdPersonCamera
@onready var top_down_camera: Camera3D = $MarginContainer/SubViewportContainer/SubViewport/TopDownCamera

@onready var stone_group: Node = $Stones

@onready var sheet: Node3D = $Sheet
@onready var sheet_body: StaticBody3D = $Sheet/StaticBody
@onready var tee_line_marker: Marker3D = $Sheet/TeeLineMarker
@onready var house_origin_marker: Marker3D = $Sheet/HouseOriginMarker
@onready var far_hog_line_marker: Marker3D = $Sheet/FarHogLineMarker

@onready var impulse_indicator: Line3D = $ImpulseIndicator
@onready var scoreboard: GridContainer = $Scoreboard

const STONE_SCENE: PackedScene = preload("res://scenes/stone.tscn")
const SWEEP_AREA_SCENE: PackedScene = preload("res://scenes/sweep_area.tscn")
const IMPULSE_MAX: float = 150.0

var ends: int = 1
var shots: int = 0
var team_color: Color = Color.RED

var is_stone_shot: bool = false
var is_stone_drag: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	top_down_camera.position = house_origin_marker.global_position
	top_down_camera.position.y = 3.0
	_next_shot()


func _process(_delta: float) -> void:
	if is_stone_shot:
		var stone: Stone = stone_group.get_child(-1)
		if stone.sleeping:
			shot_finished.emit(stone)
			return
		_update_scoreboard()


func _input(event):
	if Input.is_action_just_released("pause"):
		$PauseMenu.open()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if is_stone_shot:
			return
		
		var collision := _get_mouse_ray_collision()
		if collision.is_empty():
			return

		var stone: Stone = stone_group.get_child(-1)
		if not is_stone_drag and event.is_pressed() and collision.collider == stone:
			is_stone_drag = true
		elif is_stone_drag and event.is_released() and collision.collider == sheet_body:
			is_stone_drag = false
			impulse_indicator.clear()
			var impulse := _get_clamped_impulse(collision.position, stone.position)
			stone.apply_central_impulse(impulse)
			stone.sleeping = false
			print("Stone shot, impulse: %v, length: %f" % [impulse, impulse.length() / IMPULSE_MAX])
			shot_started.emit(stone)

	if event is InputEventMouseMotion and is_stone_drag:
		var collision := _get_mouse_ray_collision()
		if collision.is_empty():
			return

		var stone: Stone = stone_group.get_child(-1)
		if is_stone_drag and collision.collider == sheet_body:
			var impulse := _get_clamped_impulse(collision.position, stone.position)
			var factor := indicator_color_curve.sample(impulse.length() / IMPULSE_MAX)
			impulse_indicator.color = (1.0 - factor) * Color.RED + factor * Color.GREEN
			impulse_indicator.points = PackedVector3Array([
				stone.position,
				stone.position - impulse / IMPULSE_MAX
			])
			impulse_indicator.points[0].y = 0.1
			impulse_indicator.points[1].y = 0.1
			impulse_indicator.rebuild()


func _on_shot_started(stone: Node3D) -> void:
	is_stone_shot = true

	stone.get_node("SlideAudioPlayer").play()
	stone.add_child(SWEEP_AREA_SCENE.instantiate())


func _on_shot_finished(stone: Node3D) -> void:
	is_stone_shot = false

	stone.get_node("SlideAudioPlayer").stop()
	stone.remove_child(stone.get_node("SweepArea"))

	# Check if the stone is hogged
	if stone.position.z > far_hog_line_marker.global_position.z:
		_disable_stone(stone)

	await get_tree().create_timer(1.0).timeout

	_next_shot()


func _on_sheet_out_of_bounds(stone: Node3D) -> void:
	# Increase friction to stop the stone quickly
	stone.physics_material_override.friction = 1.0
	_disable_stone(stone)


func _disable_stone(stone: Node3D):
	# Disable collision with other stones
	stone.collision_layer = 0
	stone.collision_mask = 1 << 1

	# Make the stone semi-transparent
	for mesh in stone.get_node("Meshes").get_children():
		mesh.transparency = 0.3


func _get_clamped_impulse(from: Vector3, to: Vector3) -> Vector3:
	var impulse := (to - from) * IMPULSE_MAX
	impulse.z = min(impulse.z, 0.0)
	var length: float = clamp(impulse.length(), 0.0, IMPULSE_MAX)
	return impulse.normalized() * length


func _get_mouse_ray_collision() -> Dictionary:
	const RAY_LENGTH: float = 10.0

	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := third_person_camera.project_ray_origin(mouse_position)
	var ray_end := ray_origin + third_person_camera.project_ray_normal(mouse_position) * RAY_LENGTH

	var ray_query_params := PhysicsRayQueryParameters3D.new()
	ray_query_params.from = ray_origin
	ray_query_params.to = ray_end

	var space_state := get_world_3d().direct_space_state
	return space_state.intersect_ray(ray_query_params)


func _next_shot() -> void:
	if shots >= shots_per_end:
		_next_end()
	shots += 1
	team_color = Color.RED if team_color == Color.BLUE else Color.BLUE
	_spawn_stone(team_color)


func _next_end() -> void:
	shots = 0
	for stone in stone_group.get_children():
		stone.queue_free()
	ends += 1
	if ends >= ends_per_match + 1:
		$ResultMenu.open()
		return


func _spawn_stone(color: Color) -> void:
	var stone := STONE_SCENE.instantiate()
	stone.position = tee_line_marker.global_position
	stone.color = color
	stone.number = shots
	var material := PhysicsMaterial.new()
	material.friction = stone_friction
	stone.physics_material_override = material
	stone_group.add_child(stone)

	third_person_camera.position = stone.position + third_person_camera.offset
	third_person_camera.target = stone


func _update_scoreboard() -> void:
	var stones := stone_group.get_children()
	if stones.is_empty():
		return
	
	var stones_in_house := stones.filter(func(stone): return sheet.is_body_in_house(stone))
	if stones_in_house.is_empty():
		scoreboard.set_score(ends, 0, 0)
		return

	var house_origin := house_origin_marker.global_position
	stones_in_house.sort_custom(func(a, b):
		return a.position.distance_to(house_origin) < b.position.distance_to(house_origin)
	)
	var winner_color: Color = stones_in_house[0].color

	var score := 0
	for stone in stones_in_house:
		if stone.color == winner_color:
			score += 1
		else:
			break

	var red_score := 0
	var blue_score := 0
	if winner_color == Color.RED:
		red_score = score
	else:
		blue_score = score

	scoreboard.set_score(ends, red_score, blue_score)
