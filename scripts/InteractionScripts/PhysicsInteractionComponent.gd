extends Node

enum InteractionType {
	DEFAULT,
	DOOR,
	SWITCH,
	WHEEL,
	NOTE,
}

var player_hand: Marker3D

# --- EXPORTS ---

@export var object_ref: Node3D
@export var interaction_type: InteractionType = InteractionType.DEFAULT
@export var volume_primary_audio_player: float = -8.0
@export var volume_secondary_audio_player: float = -8.0

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
@export var door_open_se: AudioStreamOggVorbis
@export var door_close_se: AudioStreamOggVorbis

@export_group("Switch-Wheel object Settings")
@export var rotate_on_x: bool = false
@export var turn_on_if_zero_one_switch: bool = false
@export var nodes_that_switch_affects: Array[String]
@export var switch_flip_se: AudioStreamOggVorbis
@export var wheel_movement_sensitivity: float = 0.2
@export var wheel_snap_interval_deg: float = 10.0
@export var sound_wheel_threshold_distance: float = 30
@export var wheel_snap_speed: float = 8.0
@export var wheel_turning_se: AudioStreamOggVorbis
@export var wheel_done_se: AudioStreamOggVorbis
@export var continuosu_sound: bool = false

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

# Sound and feedback switch variables
var switch_target_rotation: float = 0.0
var switch_lerp_speed: float = 8.0
var is_switch_snapping: bool = false
var switch_moved: bool = false
var switch_kickback_triggered: bool = false

# Sound door variables
var door_open: bool = false
var shut_angle_threshold = 0.05
var open_angle_treshold = 0.1
var last_door_rotation: Vector3

# Sound wheel variables
var last_wheel_angle: float
var has_wheel_sound_played: bool = true
var has_stopped_wheel_interact: bool = false

# Wheel snapping variables
var is_wheel_snapping: bool = false
var wheel_snap_target: float = 0.0

# Note specific vars
var holding_note: bool = false
var float_height: float = 0.075
var float_speed: float = 0.5
var start_y: float = 0.0
var float_progress: float = 0.0

var primary_audio_player: AudioStreamPlayer3D
var secondary_audio_player: AudioStreamPlayer3D
var last_velocity: Vector3 = Vector3.ZERO
var mesh: MeshInstance3D


func _ready() -> void:
	
	mesh = object_ref.find_child("MeshInstance3D", true, false)
	if mesh:
		start_y = mesh.position.y
	
	primary_audio_player = AudioStreamPlayer3D.new()
	add_child(primary_audio_player)
	primary_audio_player.global_position = primary_audio_player.get_parent().get_parent().global_position
	primary_audio_player.volume_db = volume_primary_audio_player
	secondary_audio_player = AudioStreamPlayer3D.new()
	add_child(secondary_audio_player)
	secondary_audio_player.global_position = secondary_audio_player.get_parent().get_parent().global_position
	secondary_audio_player.volume_db = volume_secondary_audio_player
	
	match interaction_type:
		InteractionType.DEFAULT:
			if object_ref.has_signal("body_entered"):
				primary_audio_player.stream = impact_se
				object_ref.connect("body_entered", Callable(self, "_on_body_entered"))
				object_ref.contact_monitor = true
				object_ref.max_contacts_reported = 1
		InteractionType.SWITCH:
			primary_audio_player.stream = switch_flip_se
			for node in nodes_that_switch_affects:
				nodes_to_affect.append(get_tree().get_current_scene().find_child(str(node), true, false))
			
			await get_tree().process_frame
			if rotate_on_x:
				starting_rotation = object_ref.rotation.x
			else:
				starting_rotation = object_ref.rotation.z
			
			maxium_rotation = starting_rotation + deg_to_rad(maxium_rotation)
			
		InteractionType.DOOR:
			last_door_rotation = door_pivot_point.rotation
			primary_audio_player.stream = door_open_se
			secondary_audio_player.stream = door_close_se
			if door_pivot_point == null:
				return
			
			starting_rotation = door_pivot_point.rotation.y
			maxium_rotation = starting_rotation + deg_to_rad(maxium_rotation)
		InteractionType.WHEEL:
			
			primary_audio_player.stream = wheel_turning_se
			secondary_audio_player.stream = wheel_done_se
			
			for node in nodes_that_switch_affects:
				nodes_to_affect.append(get_tree().get_current_scene().find_child(str(node), true, false))
			
			starting_rotation = object_ref.rotation.z
			maxium_rotation = starting_rotation + deg_to_rad(maxium_rotation)
			camera = get_tree().get_current_scene().find_child("Camera3D", true, false)
		InteractionType.NOTE:
			note_content = note_content.replace("\\n", "\n")

func _physics_process(delta: float) -> void:
	match interaction_type:
		InteractionType.DEFAULT:
			if object_ref:
				last_velocity = object_ref.linear_velocity
				primary_audio_player.global_position = primary_audio_player.get_parent().get_parent().global_position
		
		
	if object_ref and holding_note:
				float_progress += float_speed * delta
				float_progress = fmod(float_progress, 2.0)
				var t = float_progress
				if t > 1.0:
					t = 2.0 - t
				mesh.position.z = lerp(start_y - float_height, start_y + float_height, t)

func _process(delta: float) -> void:
	match interaction_type:
		InteractionType.SWITCH:
			if is_interacting:
				update_switch_sounds()
			if !is_interacting and !is_switch_snapping and !switch_moved:
				primary_audio_player.stop()
			
			
			if is_switch_snapping:
				var raw_percentage: float
				var percentage: float
				if not switch_kickback_triggered:
					switch_kickback_triggered = true
					if switch_flip_se and not primary_audio_player.playing:
						primary_audio_player.stop()
						primary_audio_player.volume_db = volume_primary_audio_player
						primary_audio_player.play()
				
				if rotate_on_x:
					object_ref.rotation.x = lerp_angle(object_ref.rotation.x, switch_target_rotation, delta * switch_lerp_speed)
					if abs(object_ref.rotation.x - switch_target_rotation) < 0.1:
						object_ref.rotation.x = switch_target_rotation
						is_switch_snapping = false
					raw_percentage = (object_ref.rotation.x - starting_rotation) / (maxium_rotation - starting_rotation)
				else:
					object_ref.rotation.z = lerp_angle(object_ref.rotation.z, switch_target_rotation, delta * switch_lerp_speed)
					if abs(object_ref.rotation.z - switch_target_rotation) < 0.1:
						object_ref.rotation.z = switch_target_rotation
						is_switch_snapping = false
					raw_percentage = (object_ref.rotation.z - starting_rotation) / (maxium_rotation - starting_rotation)
				
				percentage = raw_percentage
				
				notify_nodes(percentage)
			else:
				switch_kickback_triggered = false
		InteractionType.DOOR:
			if is_interacting:
				update_door_sounds()
			
		InteractionType.WHEEL:
				if is_interacting:
					update_wheel_sounds()
				elif is_wheel_snapping:
					object_ref.rotation.z = lerp_angle(object_ref.rotation.z, wheel_snap_target, delta * wheel_snap_speed)
					if abs(object_ref.rotation.z - wheel_snap_target) < deg_to_rad(0.5):
						object_ref.rotation.z = wheel_snap_target
						is_wheel_snapping = false
					# Optional: play a small “click” sound when snapping completes
						if wheel_done_se and not secondary_audio_player.playing:
							secondary_audio_player.volume_db = -6
							secondary_audio_player.play()
					# Update percentage for affected nodes as it snaps
					var percentage: float = (object_ref.rotation.z - starting_rotation) / (maxium_rotation - starting_rotation)
					notify_wheel_nodes(percentage)
				elif has_stopped_wheel_interact and !is_interacting:
					if wheel_done_se:
						secondary_audio_player.volume_db = -8
						secondary_audio_player.play()
					has_stopped_wheel_interact = false
			

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
			switch_moved = false
		InteractionType.WHEEL: 
			last_wheel_angle = object_ref.rotation.z
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
	
	match interaction_type:
		InteractionType.SWITCH:
			var percentage: float
			if rotate_on_x:
				percentage = (object_ref.rotation.x - starting_rotation) / (maxium_rotation - starting_rotation)
				
				if turn_on_if_zero_one_switch:
					if percentage < 0.5:
						switch_target_rotation = starting_rotation
						is_switch_snapping = true
					elif percentage > 0.5:
						switch_target_rotation = maxium_rotation
						is_switch_snapping = true
				else:
					if percentage < 0.2:
						switch_target_rotation = starting_rotation
						is_switch_snapping = true
					elif percentage > 0.8:
						switch_target_rotation = maxium_rotation
						is_switch_snapping = true
				
			else:
				percentage = (object_ref.rotation.z - starting_rotation) / (maxium_rotation - starting_rotation)
				if percentage < 0.2:
					switch_target_rotation = starting_rotation
					is_switch_snapping = true
				elif percentage > 0.8:
					switch_target_rotation = maxium_rotation
					is_switch_snapping = true
			
		InteractionType.WHEEL:
				has_stopped_wheel_interact = true
				if primary_audio_player.playing :
					primary_audio_player.stop()
				# Snap the wheel to the nearest interval when released
				var current_angle_deg = rad_to_deg(object_ref.rotation.z)
				var snapped_angle_deg = round(current_angle_deg / wheel_snap_interval_deg) * wheel_snap_interval_deg
				wheel_snap_target = deg_to_rad(snapped_angle_deg)
				is_wheel_snapping = true

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
				var raw_percentage: float
				var percentage: float
				if event is InputEventMouseMotion:
					if rotate_on_x:
						var prev_angle = object_ref.rotation.x
						if turn_on_if_zero_one_switch:
							object_ref.rotate_x(event.relative.y * object_sensitivity)
						else:
							object_ref.rotate_x(-event.relative.y * object_sensitivity)
						object_ref.rotation.x = clamp(object_ref.rotation.x, starting_rotation, maxium_rotation)
						raw_percentage = (object_ref.rotation.x - starting_rotation) / (maxium_rotation - starting_rotation)
						if abs(object_ref.rotation.x - prev_angle) > 0.01:
							switch_moved = true
					else:
						var prev_angle = object_ref.rotation.z
						object_ref.rotate_z(event.relative.y * object_sensitivity)
						object_ref.rotation.z = clamp(object_ref.rotation.z, starting_rotation, maxium_rotation)
						raw_percentage = (object_ref.rotation.z - starting_rotation) / (maxium_rotation - starting_rotation)
						if abs(object_ref.rotation.z - prev_angle) > 0.01:
							switch_moved = true
					
					percentage = raw_percentage
					
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
					
					notify_wheel_nodes(percentage)


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
	var switch_name = get_parent().get_parent().get_parent().name
	var zero_one_switch_name = get_parent().get_parent().name
	for node in nodes_to_affect:
		if node and node.has_method("execute"):
			if switch_name == "LockInPanel0":
				node.call("execute", percentage, "ZeroPanel")
			elif switch_name == "LockInPanel1":
				node.call("execute", percentage, "FirstPanel")
			elif switch_name == "LockInPanel2":
				node.call("execute", percentage, "SecondPanel")
			elif switch_name == "LockInPanel3":
				node.call("execute", percentage, "ThirdPanel")
			elif zero_one_switch_name.begins_with("zero_one_switch_"):
				node.call("execute", percentage, zero_one_switch_name)
		else:
			push_error(str(node.name) + " doesn't have the 'execute' function, therefore the switch affects nothing" )

func notify_wheel_nodes(percentage: float) -> void:
	var wheel_name = get_parent().get_parent().name  # or get_node("../").name if script is nested deeper
	for node in nodes_to_affect:
		if node:
			if wheel_name.begins_with("SinFreq"):
				node.call("execute", percentage, "SinFreq")
			elif wheel_name.begins_with("SinAmp"):
				node.call("execute", percentage, "SinAmp")
		else:
			push_error(str(node.name) + " doesn't have the 'execute' function, therefore the switch affects nothing" )

func calculate_cross_product(_mouse_position: Vector2) -> float:
	var center_position = camera.unproject_position(object_ref.global_transform.origin)
	var vector_to_previous = previous_mouse_position - center_position
	var vector_to_current = _mouse_position - center_position
	var cross_product = vector_to_current.x * vector_to_previous.y - vector_to_current.y * vector_to_previous.x
	return cross_product

func _collect_note() -> void:
	can_interact = false
	
	if mesh:
		mesh.layers &= ~(1 << 0)
		mesh.layers |= 1 << 1
	
	if pick_up_se:
		primary_audio_player.volume_db = volume_primary_audio_player
		primary_audio_player.stream = pick_up_se
		primary_audio_player.play()
	holding_note = true
	emit_signal("note_collected", get_parent())

func _play_sound_effect(_visible: bool, _interact: bool) -> void:
	if impact_se:
		primary_audio_player.play()

func _on_body_entered(_node: Node) -> void:
	var impact_strength = (last_velocity - object_ref.linear_velocity).length()
	if impact_strength > contact_velocity_threshold:
		_play_sound_effect(true, true)

func update_door_sounds() -> void:
	var is_rotating = last_door_rotation != door_pivot_point.rotation
	var door_angle = door_pivot_point.rotation.y
	if is_rotating and !door_open and abs(door_angle - starting_rotation) > open_angle_treshold:
		if not primary_audio_player.playing and door_open_se:
			secondary_audio_player.stop()
			primary_audio_player.volume_db = volume_primary_audio_player
			primary_audio_player.play()
			door_open = true
	last_door_rotation = door_pivot_point.rotation
	
	
	if door_open and abs(door_angle - starting_rotation) < shut_angle_threshold:
		if not secondary_audio_player.playing and door_close_se:
			primary_audio_player.stop()
			secondary_audio_player.volume_db = volume_secondary_audio_player
			secondary_audio_player.play()
		door_open = false

func update_switch_sounds() -> void:
	if !is_switch_snapping:
		if switch_moved and rotate_on_x:
			if abs(object_ref.rotation.x - maxium_rotation) < 0.01 or abs(object_ref.rotation.x - starting_rotation) < 0.01:
				if primary_audio_player and switch_flip_se:
					primary_audio_player.volume_db = volume_primary_audio_player
					primary_audio_player.play()
				switch_moved = false
		elif switch_moved and !rotate_on_x:
			if abs(object_ref.rotation.z - maxium_rotation) < 0.01 or abs(object_ref.rotation.z - starting_rotation) < 0.01:
				if primary_audio_player and switch_flip_se:
					primary_audio_player.volume_db = volume_primary_audio_player
					primary_audio_player.play()
				switch_moved = false

func update_wheel_sounds() -> void:
	var current_angle = rad_to_deg(object_ref.rotation.z)
	var angle_diff = abs(current_angle - last_wheel_angle)
	
	if angle_diff < sound_wheel_threshold_distance and continuosu_sound:
		primary_audio_player.stop()
	
	if angle_diff >= sound_wheel_threshold_distance:
		if not primary_audio_player.playing:
			primary_audio_player.volume_db = volume_primary_audio_player
			primary_audio_player.play()
		if current_angle > last_wheel_angle:
			last_wheel_angle += sound_wheel_threshold_distance * floor(angle_diff / sound_wheel_threshold_distance)
		else:
			last_wheel_angle -= sound_wheel_threshold_distance * floor(angle_diff / sound_wheel_threshold_distance)
