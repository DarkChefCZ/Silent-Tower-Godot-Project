extends Node

enum InteractionType {
	DEFAULT,
	DOOR,
	SWITCH,
	WHEEL,
	NOTE,
	# BUTTON  Finish This one, not implemented + add dynamic sounds
}

var player_hand: Marker3D

# --- EXPORTS ---

@export var object_ref: Node3D
@export var interaction_type: InteractionType = InteractionType.DEFAULT

@export_group("Default object Settings")
@export var interaction_strength: float = 5
@export var throw_strength: float = 20
@export var impact_se: AudioStreamOggVorbis
@export var contact_velocity_threshold: float = 0.1

@export_group("Basic object settings")
@export var object_sensitivity: float = 0.001
@export var maxium_rotation: float = 90

@export_group("Additional Door object Settings")
@export var door_pivot_point: Node3D

@export_group("Switch-Wheel object Settings")
@export var nodes_that_switch_affects: Array[String]
@export var wheel_movement_sensitivity: float = 0.2

@export_group("Note object Settings")
@export var note_content: String
@export var pick_up_se: AudioStreamOggVorbis
@export var put_down_se: AudioStreamOggVorbis

# --- --- ---

# --- SIGNALS ---
signal note_collected(note: Node3D)
# --- --- ---

var can_interact: bool = true
var is_interacting: bool = false
var lock_camera: bool = false
var starting_rotation: float
var is_front: bool
var nodes_to_affect: Array[Node]
var camera: Camera3D
var previous_mouse_position: Vector2
var wheel_rotation: float = 0.0

var primary_audio_player: AudioStreamPlayer3D
var secondary_audio_player: AudioStreamPlayer3D
var last_velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	
	primary_audio_player = AudioStreamPlayer3D.new()
	add_child(primary_audio_player)
	secondary_audio_player = AudioStreamPlayer3D.new()
	add_child(secondary_audio_player)
	
	match interaction_type:
		InteractionType.DEFAULT:
			if object_ref.has_signal("body_entered"):
				object_ref.connect("body_entered", Callable(self, "_on_body_entered"))
				object_ref.contact_monitor = true
				object_ref.max_contacts_reported = 1
		InteractionType.SWITCH:
			for node in nodes_that_switch_affects:
				nodes_to_affect.append(get_tree().get_current_scene().find_child(str(node), true, false))
			
			starting_rotation = object_ref.rotation.z
			maxium_rotation = starting_rotation + deg_to_rad(maxium_rotation)
		InteractionType.DOOR:
			if door_pivot_point == null:
				return
			
			starting_rotation = door_pivot_point.rotation.x
			maxium_rotation = starting_rotation + deg_to_rad(maxium_rotation)
		InteractionType.WHEEL:
			for node in nodes_that_switch_affects:
				nodes_to_affect.append(get_tree().get_current_scene().find_child(str(node), true, false))
			
			starting_rotation = object_ref.rotation.z
			maxium_rotation = starting_rotation + deg_to_rad(maxium_rotation)
			camera = get_tree().get_current_scene().find_child("Camera3D", true, false)
		InteractionType.NOTE:
			note_content = note_content.replace("\\n", "\n")

func _physics_process(_delta: float) -> void:
	match interaction_type:
		InteractionType.DEFAULT:
			if object_ref:
				last_velocity = object_ref.linear_velocity


# Runs once when the player FIRST clicks on an object to interact with
func preInteract(hand: Marker3D) -> void:
	is_interacting = true
	match interaction_type:
		InteractionType.DEFAULT:
			player_hand = hand
		InteractionType.DOOR:
			lock_camera = true
		InteractionType.SWITCH:
			lock_camera = true
		InteractionType.WHEEL:
			lock_camera = true
			previous_mouse_position = get_viewport().get_mouse_position()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# Run every frame, perform some logic on this object
func interact() -> void:
	if !can_interact:
		return
	
	match interaction_type:
		InteractionType.DEFAULT:
			_default_interact()
		InteractionType.NOTE:
			_collect_note()
	

# Runs if we want to perform auxilart interaction on an object
func auxInteract() -> void:
	if !can_interact:
		return
	
	match interaction_type:
		InteractionType.DEFAULT:
			_default_throw()

# Run once when the player LAST interacts with an object
func postInteract() -> void:
	is_interacting = false
	lock_camera = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if is_interacting:
		match interaction_type:
			InteractionType.DOOR:
				if event is InputEventMouseMotion:
					if is_front:
						door_pivot_point.rotate_y(-event.relative.y * object_sensitivity)
					else:
						door_pivot_point.rotate_y(event.relative.y * object_sensitivity)
					
					door_pivot_point.rotation.y = clamp(door_pivot_point.rotation.y, starting_rotation, maxium_rotation)
			InteractionType.SWITCH:
				if event is InputEventMouseMotion:
					object_ref.rotate_z(event.relative.y * object_sensitivity)
					object_ref.rotation.z = clamp(object_ref.rotation.z, starting_rotation, maxium_rotation)
					var percentage: float = (object_ref.rotation.z - starting_rotation) / (maxium_rotation - starting_rotation)
					notify_nodes(percentage)
			InteractionType.WHEEL:
				if event is InputEventMouseMotion:
					var mouse_position: Vector2 = event.position
					if calculate_cross_product(mouse_position) > 0:
						wheel_rotation += wheel_movement_sensitivity
					else:
						wheel_rotation -= wheel_movement_sensitivity
					
					object_ref.rotation.z = wheel_rotation * 0.1
					object_ref.rotation.z = clamp(object_ref.rotation.z, starting_rotation, maxium_rotation)
					var percentage: float = (object_ref.rotation.z - starting_rotation) / (maxium_rotation - starting_rotation)
					previous_mouse_position = mouse_position
					
					var min_wheel_rotation = starting_rotation / 0.1
					var max_wheel_rotation = maxium_rotation / 0.1
					wheel_rotation = clamp(wheel_rotation, min_wheel_rotation, max_wheel_rotation)
					
					notify_nodes(percentage)

func _default_interact() -> void:
	var object_current_position: Vector3 = object_ref.global_transform.origin
	var player_hand_position: Vector3 = player_hand.global_transform.origin
	var object_distance: Vector3 = player_hand_position - object_current_position
	
	var rigid_body_3d: RigidBody3D = object_ref as RigidBody3D
	if rigid_body_3d == null:
		push_error(str(rigid_body_3d) + " is not a node type of RigidBody3D, therefor we can't perform physics interaction on it")
	else:
		rigid_body_3d.set_linear_velocity((object_distance)*(interaction_strength/rigid_body_3d.mass))

func _default_throw() -> void:
	var rigid_body_3d: RigidBody3D = object_ref as RigidBody3D
	if rigid_body_3d == null:
		push_error(str(rigid_body_3d) + " is not a node type of RigidBody3D, therefor we can't perform physics interaction on it")
	else:
		var throw_direction: Vector3 = -player_hand.global_transform.basis.z.normalized()
		var throw_strength_used = (throw_strength/rigid_body_3d.mass)
		rigid_body_3d.set_linear_velocity(throw_direction*throw_strength_used)
		can_interact = false
		await get_tree().create_timer(2.0).timeout
		can_interact = true

func set_direction(_normal: Vector3) -> void:
	if _normal.z > 0:
		is_front = true
	else:
		is_front = false

func notify_nodes(percentage: float) -> void:
	for node in nodes_to_affect:
		if node and node.has_method("execute"):
			node.call("execute", percentage)
		else:
			push_error(str(node.name) + " doesn't have the 'execute' function, therefore the switch affects nothing" )

func calculate_cross_product(_mouse_position: Vector2) -> float:
	var center_position = camera.unproject_position(object_ref.global_transform.origin)
	var vector_to_previous = previous_mouse_position - center_position
	var vector_to_current = _mouse_position - center_position
	var cross_product = vector_to_current.x * vector_to_previous.y - vector_to_current.y * vector_to_previous.x
	return cross_product

func _collect_note() -> void:
	var mesh = get_parent().find_child("MeshInstance3D", true, false)
	can_interact = false
	
	if mesh:
		mesh.layers &= ~(1 << 0)
		mesh.layers |= 1 << 1
	
	if pick_up_se:
		primary_audio_player.stream = pick_up_se
		primary_audio_player.play()
	emit_signal("note_collected", get_parent())

func _play_sound_effect(_visible: bool, _interact: bool) -> void:
	if impact_se:
		primary_audio_player.stream = impact_se
		primary_audio_player.play()

func _on_body_entered(_node: Node) -> void:
	var impact_strength = (last_velocity - object_ref.linear_velocity).length()
	if impact_strength > contact_velocity_threshold:
		_play_sound_effect(true, true)
