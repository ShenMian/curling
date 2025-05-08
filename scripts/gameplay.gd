extends Node3D

signal shot_started(stone: Stone)
signal shot_finished(stone: Stone)

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
@onready var house_origin: Marker3D = $Sheet/HouseOriginMarker
@onready var near_hog_line: Marker3D = $Sheet/NearHogLineMarker
@onready var far_hog_line: Marker3D = $Sheet/FarHogLineMarker

@onready var impulse_indicator: Line3D = $ImpulseIndicator
@onready var scoreboard: Scoreboard = $Scoreboard

const STONE_SCENE: PackedScene = preload("res://scenes/stone.tscn")
const SWEEP_AREA_SCENE: PackedScene = preload("res://scenes/sweep_area.tscn")
const IMPULSE_MAX: float = 150.0

# The number of ends played in the current match
var _ends: int = 1

# The number of shots taken in the current end
var _shots: int = 0

# The color of the team that is currently playing
var _team_color: Color = Color.RED

# If the stone is ready to be shot
var _is_stone_ready: bool = false

# If the stone is currently being dragged
var _is_stone_drag: bool = false

# If the stone is currently being shot
var _is_stone_shot: bool = false

func _ready() -> void:
	# Set the top-down camera position above the house
	top_down_camera.position = house_origin.global_position
	top_down_camera.position.y = 3.0

	_next_shot()


func _physics_process(delta: float) -> void:
	var stone: Stone = stone_group.get_child(-1)

	if _is_stone_shot:
		# Check if the stone has stopped moving
		if stone.sleeping:
			_is_stone_shot = false
			shot_finished.emit(stone)
			return
		_update_scoreboard()

	if _is_stone_ready && not _is_stone_drag:
		if Input.is_action_pressed("spin_stone_cw"):
			stone.rotate_y(-delta)
		if Input.is_action_pressed("spin_stone_ccw"):
			stone.rotate_y(delta)

		if Input.is_action_pressed("adjust_stone_left"):
			stone.global_translate(Vector3(-delta, 0, 0))
		if Input.is_action_pressed("adjust_stone_right"):
			stone.global_translate(Vector3(delta, 0, 0))

		# Clamp the stone's horizontal position to keep it within the allowed area of the sheet.
		# WARNING: Avoid continuously modifying position, as it may cause physics issues.
		var width = sheet.get_node("StaticBody/Mesh").mesh.size.x
		if stone.position.x < -width / 2 * 0.2 or stone.position.x > width / 2 * 0.2:
			stone.position.x = clamp(stone.position.x, -width / 2 * 0.2, width / 2 * 0.2)


func _input(event):
	if Input.is_action_just_released("pause"):
		$PauseMenu.open()
	
	if _is_stone_ready:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			var collision := _get_mouse_ray_collision()
			if collision.is_empty():
				return

			# Handles the stone dragging and releasing action.
			var stone: Stone = stone_group.get_child(-1)
			if not _is_stone_drag and event.is_pressed() and collision.collider == stone:
				_is_stone_drag = true
			elif _is_stone_drag and event.is_released():
				_is_stone_drag = false
				if collision.collider == sheet_body:
					# Applies the impulse to the stone.
					var impulse := _get_clamped_impulse(collision.position, stone.position)
					if impulse.length() < 0.01:
						return

					_is_stone_ready = false
					impulse_indicator.clear()
					stone.apply_central_impulse(impulse)
					stone.apply_torque_impulse(Vector3(0, -stone.rotation.y, 0))
					stone.sleeping = false
					print("Stone shot, impulse: %v, length: %f" % [impulse, impulse.length() / IMPULSE_MAX])
					shot_started.emit(stone)

		if event is InputEventMouseMotion and _is_stone_drag:
			var collision := _get_mouse_ray_collision()
			if collision.is_empty():
				return

			# Updates the impulse indicator during the stone dragging operation.
			var stone: Stone = stone_group.get_child(-1)
			if collision.collider == sheet_body:
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
			else:
				impulse_indicator.clear()


func _on_shot_started(stone: Stone) -> void:
	_is_stone_shot = true

	stone.get_node("SlideAudioPlayer").play()
	stone.add_child(SWEEP_AREA_SCENE.instantiate())


func _on_shot_finished(stone: Stone) -> void:
	stone.get_node("SlideAudioPlayer").stop()
	stone.remove_child(stone.get_node("SweepArea"))

	# Checks if the stone is hogged.
	if stone.position.z > far_hog_line.global_position.z:
		print("Stone was hogged")
		_disable_stone(stone)

	await get_tree().create_timer(1.0).timeout

	_next_shot()


func _on_stone_out_of_sheet(node: Node3D) -> void:
	if node is not Stone:
		return
	var stone: Stone = node

	# Increase friction to stop the stone quickly
	stone.physics_material_override.friction = 1.0
	_disable_stone(stone)


func _disable_stone(stone: Stone):
	# Disables collision detection between this stone and other stones.
	stone.collision_layer = 0
	stone.collision_mask = 1 << 1

	# Makes the stone semi-transparent
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
	if _shots >= shots_per_end:
		_next_end()
	_shots += 1
	_team_color = Color.RED if _team_color == Color.BLUE else Color.BLUE
	_spawn_stone(_team_color)


func _next_end() -> void:
	_shots = 0
	for stone in stone_group.get_children():
		stone.queue_free()
	_ends += 1
	if _ends >= ends_per_match + 1:
		$ResultMenu.open()
		return


# Spawns a new curling stone.
func _spawn_stone(color: Color) -> void:
	var stone := STONE_SCENE.instantiate()
	stone.position = near_hog_line.global_position
	stone.color = color
	stone.number = _shots
	var material := PhysicsMaterial.new()
	material.friction = stone_friction
	stone.physics_material_override = material
	stone_group.add_child(stone)

	third_person_camera.position = stone.position + third_person_camera.offset
	third_person_camera.target = stone

	_is_stone_ready = true


# Updates the scoreboard based on the current positions of the stones.
func _update_scoreboard() -> void:
	var stones := stone_group.get_children()
	if stones.is_empty():
		return
	
	var stones_in_house := stones.filter(func(stone): return sheet.is_body_in_house(stone))
	if stones_in_house.is_empty():
		_set_scoreboard(0, 0)
		return

	stones_in_house.sort_custom(func(a, b):
		return a.position.distance_to(house_origin.global_position) < b.position.distance_to(house_origin.global_position)
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

	_set_scoreboard(red_score, blue_score)

# Sets scoreboards with the current scores for red and blue teams.
func _set_scoreboard(red_score: int, blue_score: int) -> void:
	scoreboard.set_score(_ends, red_score, blue_score)
	$ResultMenu.get_node("Scoreboard").set_score(_ends, red_score, blue_score)
