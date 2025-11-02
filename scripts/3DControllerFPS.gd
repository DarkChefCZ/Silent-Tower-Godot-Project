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

@export_group("Walk Settings")
@export var SPEED = 5.0

@export_group("Jump Settings")
@export var jump_height : float = 100.0
@export var jump_time_to_peak : float = 0.5
@export var jump_time_to_descent : float = 0.4

@export_group("Physics Interaction Settings")
@export var interaction_controller: Node

# --- ---- ----

# ---- @onready variables ----
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) #CUSTOM ADDED
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) #CUSTOM ADDED
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) #CUSTOM ADDED

@onready var head: Node3D = $Head
@onready var camera_3d: Camera3D = $Head/Camera3D

# --- ---- ----

# ---- ACTUAL CODE ----
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

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
		var input_dir := Input.get_vector("m_Left", "m_Right", "m_Forward", "m_Backward")
		var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else: pass
	
	if EnableWalking == true or EnableJumping == true:
		move_and_slide()
	
