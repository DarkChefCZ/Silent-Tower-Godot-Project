extends CharacterBody3D

# ---- Enabling logic ----
@export var EnableWalking: bool = false
@export var EnableJumping: bool = false
@export var EnablePhysicsInteraction: bool = false

# --- ---- ----

# ---- Settings of @export vars ----
@export_group("Camera Settings") #Is automatically enabled
@export var SENSITIVITY = 0.002
@export var CameraMaxLookY = 60
@export var CameraMinLookY = -40
@export var BOB_FREQ = 3.0
@export var BOB_AMP = 0.08
var t_bob = 0.0

@export_group("Walk Settings")
@export var SPEED = 5.0

@export_group("Jump Settings")
@export var jump_height : float = 100.0
@export var jump_time_to_peak : float = 0.5
@export var jump_time_to_descent : float = 0.4

@export_group("Physics Interaction Settings")
@export var interaction_controller: Node

@export_group("Sound Effects")
@export var footstep_ses_paths: Array[NodePath]

# --- ---- ----

# ---- @onready variables ----
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) #CUSTOM ADDED
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) #CUSTOM ADDED
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) #CUSTOM ADDED

@onready var head: Node3D = $Head
@onready var camera_3d: Camera3D = $Head/Camera3D
@onready var note_hand: Marker3D = %NoteHand

# --- ---- ----

var input_dir : Vector2

var last_bob_position_x: float = 0.0
var last_bob_direction: int = 0
var footstep_ses: Array = []

# ---- ACTUAL CODE ----
func _ready() -> void:
	randomize()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	for path in footstep_ses_paths:
		var node = get_node(path)  # get the node from the NodePath
		if node != null:
			footstep_ses.append(node)
	

func get_gravity_custom() -> float: #CUSTOM ADDED
	return jump_gravity if velocity.y < 0.0 else fall_gravity #CUSTOM ADDED

func _unhandled_input(event: InputEvent) -> void:
	if EnablePhysicsInteraction:
		if interaction_controller.isCameraLocked():
			return
	
	if event is InputEventMouseMotion:
			head.rotate_y(-event.relative.x * SENSITIVITY)
			camera_3d.rotate_x(-event.relative.y * SENSITIVITY)
			camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(CameraMinLookY), deg_to_rad(CameraMaxLookY))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		if EnableJumping == true:
			velocity.y += get_gravity_custom() * delta #CUSTOM ADDED
		else:
			velocity += get_gravity() * delta
	
	
	
	# Handle jump.
	if EnableJumping == true:
		if Input.is_action_just_pressed("Jump") and is_on_floor():
			velocity.y = jump_velocity #CUSTOM ADDED
	else: pass
	

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if EnableWalking == true:
		input_dir = Input.get_vector("m_Left", "m_Right", "m_Forward", "m_Backward")
		var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else: pass
	
	# Head bobbing
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera_3d.transform.origin = _headbob(t_bob)
	play_footsteps()
	
	if EnableWalking == true or EnableJumping == true:
		move_and_slide()
	


var pos = Vector3.ZERO
func _headbob(time) -> Vector3:
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func play_footsteps() -> void:
	if velocity.length() > 0.1 and is_on_floor():
		var bob_position_x = pos.x
		var bob_direction = sign(bob_position_x - last_bob_position_x)
		
		if bob_direction != 0 and bob_direction != last_bob_direction and last_bob_direction != 0:
			var index = pick_random_exclude_last(footstep_ses)
			var random_footstep = footstep_ses[index]
			random_footstep.play()
		last_bob_direction = bob_direction
		last_bob_position_x = bob_position_x
	else:
		last_bob_direction = 0
		last_bob_position_x = pos.x




var last_index: int = -1
func pick_random_exclude_last(array: Array) -> int:
	if array.size() <= 1:
		return 0  
	var index: int
	while true:
		index = randi() % array.size()
		if index != last_index:
			break
	last_index = index
	return index
