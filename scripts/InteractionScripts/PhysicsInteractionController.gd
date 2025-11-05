extends Node

@onready var interaction_controller: Node = %InteractionController
@onready var ray_cast_3d: RayCast3D = $"../Head/Camera3D/InteractionRaycast"
@onready var hand: Marker3D = $"../Head/Camera3D/Hand"
@onready var player_camera: Camera3D = $"../Head/Camera3D"
@onready var control: Control = $"../GUI/ReticleLayer/Control"
@onready var player: CharacterBody3D = $".."

# Note onready
@onready var note_hand: Marker3D = %NoteHand
@onready var note_storage: Node3D = $"../../TestNoteStorage"
@onready var note_text_overlay: Control = %NoteTextOverlay
@onready var note_content_display: RichTextLabel = %NoteContentDisplay

# Reticles
@onready var default_reticle: TextureRect = $"../GUI/ReticleLayer/Control/DefaultReticle"
@onready var can_interact_reticle: TextureRect = $"../GUI/ReticleLayer/Control/CanInteractReticle"
@onready var interacting_reticle: TextureRect = $"../GUI/ReticleLayer/Control/InteractingReticle"

# --- EXPORTS ---
@export var InteractableDistance: float = -2.0 #negative z is where our camera is aiming at in the Player scene
@export var NameOfInteractionComponentNode: String #put here the name of the interaction component NODE that your rigid body 3D nodes have
# --- --- ---

var current_object: Object
var last_potential_object: Object
var interaction_component: Node
var note_og_transform: Transform3D
var note_og_rotation_x: float
var is_note_overlay_display: bool = false



func _ready() -> void:
	ray_cast_3d.target_position.z = InteractableDistance
	hand.position.z = InteractableDistance
	
	default_reticle.position.x = get_viewport().size.x / 2 - default_reticle.texture.get_size().x / 2
	default_reticle.position.y = get_viewport().size.y / 2 - default_reticle.texture.get_size().y / 2
	
	can_interact_reticle.position.x = get_viewport().size.x / 2 - can_interact_reticle.texture.get_size().x / 2
	can_interact_reticle.position.y = get_viewport().size.y / 2 - can_interact_reticle.texture.get_size().y / 2
	
	interacting_reticle.position.x = get_viewport().size.x / 2 - interacting_reticle.texture.get_size().x / 2
	interacting_reticle.position.y = get_viewport().size.y / 2 - interacting_reticle.texture.get_size().y / 2

func _process(_delta: float) -> void:
	
	if interaction_component and interaction_component.is_interacting:
		changeReticle(interacting_reticle)
	
	# if on previous frame, we were interacting with an object, lets keep interacting with that object
	if current_object:
		if interaction_component:
			var maxInteractionDistance: float
			
			match interaction_component.interaction_type:
				interaction_component.InteractionType.DOOR:
					maxInteractionDistance = 3.0
				interaction_component.InteractionType.NOTE:
					maxInteractionDistance = 1.0
				_:
					maxInteractionDistance = 2.0
			
			if hand.global_transform.origin.distance_to(current_object.global_transform.origin) > maxInteractionDistance:
				interaction_component.postInteract()
				current_object = null
			
		
		
		
		if Input.is_action_just_pressed("Secondary_mb"): # check if we are pressing the secondary/left mouse button - to throw
			if !interaction_component:
				return
			else:
				interaction_component.auxInteract()
				current_object = null
				changeReticle(default_reticle)
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
				
				changeReticle(default_reticle)
		
	else: # if we weren't interacting with something, lets see if we can
		var potential_object: Object = ray_cast_3d.get_collider()
		
		if potential_object and potential_object is Node:
			interaction_component = potential_object.get_node_or_null(NameOfInteractionComponentNode)
			if !interaction_component:
				changeReticle(default_reticle)
				return
			else:
				if interaction_component.can_interact == false:
					changeReticle(default_reticle)
					return
				
				last_potential_object = current_object
				changeReticle(can_interact_reticle)
				
				if Input.is_action_just_pressed("Primary_mb"): # check if pressing the primary/left mouse button
					current_object = potential_object
					interaction_component.preInteract(hand)
					
					if interaction_component.interaction_type == interaction_component.InteractionType.NOTE:
						if not interaction_component.is_connected("note_collected", Callable(self, "_on_note_collected")):
							interaction_component.connect("note_collected", Callable(self, "_on_note_collected"))
						
					
					if interaction_component.interaction_type == interaction_component.InteractionType.DOOR:
						interaction_component.set_direction(current_object.to_local(ray_cast_3d.get_collision_point()))
		else:
			changeReticle(default_reticle)
	

func isCameraLocked() -> bool:
	if !interaction_component:
		return false
	else:
		if interaction_component.lock_camera and interaction_component.is_interacting:
			return true
	
	return false

func changeReticle(reticleToggleVis: TextureRect) -> void:
	for child in control.get_children():
		child.visible = false
	reticleToggleVis.visible = true

var ic: Node
func _on_note_collected(note: Node3D) -> void:
	note_og_transform = note.transform
	note_og_rotation_x = note.rotation_degrees.x
	note.get_parent().remove_child(note)
	note_hand.add_child(note)
	note.transform.origin = note_hand.transform.origin
	note.position = Vector3.ZERO
	note.rotation_degrees = Vector3(90.0, 15.0, 0.0)
	player.EnableWalking = false
	player.can_move_camera = false
	note_text_overlay.visible = true
	is_note_overlay_display = true
	ic = note.get_node_or_null(NameOfInteractionComponentNode)
	note_content_display.bbcode_enabled = true
	note_content_display.text = ic.note_content




func _input(_event: InputEvent) -> void:
	if is_note_overlay_display and Input.is_action_just_pressed("Secondary_mb"):
		ic.holding_note = false
		note_text_overlay.visible = false
		is_note_overlay_display = false
		var children = note_hand.get_children()
		for child in children:
			if ic.put_down_se:
				ic.secondary_audio_player.stream = ic.put_down_se
				ic.secondary_audio_player.play()
			child.get_parent().remove_child(child)
			note_storage.add_child(child)
			child.transform = note_og_transform
			child.rotation_degrees = Vector3(note_og_rotation_x, 0.0, 0.0)
			var mesh = child.find_child("MeshInstance3D", true, false)
			if mesh:
				mesh.layers &= ~(1 << 1)
				mesh.layers |= 1 << 0
		player.EnableWalking = true
		player.can_move_camera = true
		ic.can_interact = true
	
