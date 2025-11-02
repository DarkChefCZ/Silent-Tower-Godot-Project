extends Node

@onready var interaction_controller: Node = %InteractionController #References itself and is unique, sits on the CharacterBody3D
@onready var ray_cast_3d: RayCast3D = $"../Head/Camera3D/InteractionRaycast" #sits on the head/camer3d
@onready var hand: Marker3D = $"../Head/Camera3D/Hand" #sits on the head/camer3d
@onready var player_camera: Camera3D = $"../Head/Camera3D" #references the camera on the head

@export var InteractableDistance: float = -2.0 #negative z is where our camera is aiming at in the Player scene
@export var NameOfInteractionComponentNode: String #put here the name of the interaction component NODE that your rigid body 3D nodes have


var current_object: Object
var last_potential_object: Object
var interaction_component: Node

func _ready() -> void:
	ray_cast_3d.target_position.z = InteractableDistance
	hand.position.z = InteractableDistance

func _process(_delta: float) -> void:
	
	# if on previous frame, we were interacting with an object, lets keep interacting with that object
	if current_object:
		if hand.global_transform.origin.distance_to(current_object.global_transform.origin) > 2.0:
			if interaction_component:
				interaction_component.postInteract()
			current_object = null
		
		
		if Input.is_action_just_pressed("Secondary_mb"): # check if we are pressing the secondary/left mouse button - to throw
			if !interaction_component:
				return
			else:
				interaction_component.auxInteract()
				current_object = null
		elif Input.is_action_pressed("Primary_mb"): # check if we are still pressing the primary/left mouse button
			if !interaction_component:
				return
			else:
				interaction_component.interact()
		else:
			if !interaction_component:
				return
			else:
				interaction_component.postInteract()
				current_object = null
		
	else: # if we weren't interacting with something, lets see if we can
		var potential_object: Object = ray_cast_3d.get_collider()
		
		if potential_object and potential_object is Node:
			interaction_component = potential_object.get_node_or_null(NameOfInteractionComponentNode)
			if !interaction_component:
				return
			else:
				if interaction_component.can_interact == false:
					return
				
				last_potential_object = current_object
				
				if Input.is_action_just_pressed("Primary_mb"): # check if pressing the primary/left mouse button
					current_object = potential_object
					interaction_component.preInteract(hand)
					
					if interaction_component.interaction_type == interaction_component.InteractionType.DOOR:
						interaction_component.set_direction(current_object.to_local(ray_cast_3d.get_collision_point()))
	

func isCameraLocked() -> bool:
	if !interaction_component:
		return false
	else:
		if interaction_component.lock_camera and interaction_component.is_interacting:
			return true
	
	return false
