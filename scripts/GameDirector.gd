extends Node

var time: float
@export var player: CharacterBody3D
@export var intercom: Node3D
@export var crossHighlight: Node3D
@export var originalHighlight: Node3D

@export_group("PrePanelLights")
@export var zeroControlPanelArea: Area3D
@export var preControlPanelHighlight: Node3D
@export var Speakers: Array[Node3D] = []

@export_group("FirstPanelLighting+Objects")
@export var firstControlPanelArea: Area3D
@export var firstControlPanelHighlight: Node3D
@export var SwitchLockIn1: Node3D
@export var ObjectsToDisable: Array[Node3D] = []
@export var IndicationLight: OmniLight3D
@export var FirstPanelVoice: AudioStreamWAV

@export_group("PreSecondPanel")
@export var InstallationSound: AudioStreamPlayer3D
@export var InstallationArea: Area3D

@export_group("SecondPanelLighting+Objects")
@export var secondControlPanelHighlight: Node3D
@export var SwitchLockIn2: Node3D
@export var ObjectsToDisableGroup: Node3D
@export var Sound2Trigger: Area3D
@export var Sound2MetalStream: AudioStreamPlayer3D
@export var Panel_Screen_Symbols: Node3D
@export var IndicationLight2: OmniLight3D
@export var SecondPanelVoice: AudioStreamWAV

@export_group("ThirdPanelLighting+Objects")
@export var SwitchLockIn0: Node3D
@export var WeakLight0: Node3D
@export var SwitchLockIn3: Node3D
@export var ThirdPanelVoice: AudioStreamOggVorbis

@export_group("Extra")
@export var servers: Node3D
@export var tables: Node3D

var icontrol: Node
var waveReady: bool = false

var ic0: Node

var ic1: Node
var freq_here: float = 0.0
var amp_here: float = 0.0
var resetting_switch: bool = false
var LightChildren1

var LightChildren2
var ic2
var secondPanelInteractionObjects
var secondPanelSymbols

var SmallLightChildren
var LightChildren0a
var LightChildren0b
var ic3

var RaptureAudioPlayer

signal firstPanelComplete
signal secondPanelComplete
signal endingSequence

func _ready() -> void:
	ic0 = SwitchLockIn0.find_child("InteractionComponent", true, true)
	
	ic1 = SwitchLockIn1.find_child("InteractionComponent", true, true)
	icontrol = player.find_child("InteractionController", true, true)
	
	originalHighlight.find_child("AudioStreamPlayer3D", true, true).playing = false
	preControlPanelHighlight.visible = false
	crossHighlight.visible = false
	
	SmallLightChildren = WeakLight0.find_children("*", "OmniLight3D", true, false)
	LightChildren0a = originalHighlight.find_children("*", "OmniLight3D", true, false)
	LightChildren0b = originalHighlight.find_children("*", "SpotLight3D", true, true)
	LightChildren1 = firstControlPanelHighlight.find_children("*", "OmniLight3D", true, false)
	LightChildren2 = secondControlPanelHighlight.find_children("*", "OmniLight3D", true, false)
	for light in SmallLightChildren:
			light.light_energy = 0.015
	for light in LightChildren0a:
			light.visible = false
	for light in LightChildren0b:
			light.visible = false
	for light in LightChildren1:
			light.visible = false
	for light in LightChildren2:
			light.visible = false
	
	SwitchLockIn2.find_child("HeavySwitch", true, false).visible = false
	
	ic2 = SwitchLockIn2.find_child("InteractionComponent", true, true)
	ic2.can_interact = false
	secondPanelInteractionObjects = ObjectsToDisableGroup.find_children("zero_one_switch*", "Node3D", true, true)
	for object in secondPanelInteractionObjects:
		object.find_child("InteractionComponent", true, true).can_interact = false
	Sound2Trigger.monitoring = false
	
	secondPanelSymbols = Panel_Screen_Symbols.find_children("*", "TextureRect", true, true)
	
	ic3 = SwitchLockIn3.find_child("InteractionComponent", true, true)
	ic3.can_interact = false

var t: float = 0.0
func _process(delta: float) -> void:
	
	
	if resetting_switch == true:
		if ic1.rotate_on_x == true:
			ic1.object_ref.rotation.x = lerp_angle(ic1.object_ref.rotation.x, ic1.starting_rotation, delta * ic1.switch_lerp_speed)
			if abs(ic1.object_ref.rotation.x - ic1.starting_rotation) < 0.01:
				ic1.object_ref.rotation.x = ic1.starting_rotation
				resetting_switch = false
		else:
			ic1.object_ref.rotation.z = lerp_angle(ic1.object_ref.rotation.z, ic1.starting_rotation, delta * ic1.switch_lerp_speed)
			if abs(ic1.object_ref.rotation.z - ic1.starting_rotation) < 0.01:
				ic1.object_ref.rotation.z = ic1.starting_rotation
				resetting_switch = false
		
		if ic2.rotate_on_x == true:
			ic2.object_ref.rotation.x = lerp_angle(ic2.object_ref.rotation.x, ic2.starting_rotation, delta * ic2.switch_lerp_speed)
			if abs(ic2.object_ref.rotation.x - ic2.starting_rotation) < 0.01:
				ic2.object_ref.rotation.x = ic2.starting_rotation
				resetting_switch = false
		else:
			ic2.object_ref.rotation.z = lerp_angle(ic2.object_ref.rotation.z, ic2.starting_rotation, delta * ic2.switch_lerp_speed)
			if abs(ic2.object_ref.rotation.z - ic2.starting_rotation) < 0.01:
				ic2.object_ref.rotation.z = ic2.starting_rotation
				resetting_switch = false
		
		if ic3.rotate_on_x == true:
			ic3.object_ref.rotation.x = lerp_angle(ic3.object_ref.rotation.x, ic3.starting_rotation, delta * ic3.switch_lerp_speed)
			if abs(ic3.object_ref.rotation.x - ic3.starting_rotation) < 0.01:
				ic3.object_ref.rotation.x = ic3.starting_rotation
				resetting_switch = false
		else:
			ic3.object_ref.rotation.z = lerp_angle(ic3.object_ref.rotation.z, ic3.starting_rotation, delta * ic3.switch_lerp_speed)
			if abs(ic3.object_ref.rotation.z - ic3.starting_rotation) < 0.01:
				ic3.object_ref.rotation.z = ic3.starting_rotation
				resetting_switch = false
	
	
	

func _on_panel_0_trigger_area_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		preControlPanelHighlight.visible = true
		preControlPanelHighlight.find_child("AudioStreamPlayerOn", true, true).playing = true
		preControlPanelHighlight.find_child("AudioStreamPlayer3D", true, true).playing = true
		crossHighlight.visible = true
		crossHighlight.find_child("AudioStreamPlayer3D", true, true).playing = true
		for speaker in Speakers:
			speaker.find_child("AudioStreamPlayer3D", true, true).playing = true
		zeroControlPanelArea.queue_free()
	else:
		return

func _on_panel_1_trigger_area_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		for light in LightChildren1:
			light.visible = true
		
		firstControlPanelHighlight.find_child("AudioStreamPlayer3D", true, false).playing = true
		firstControlPanelArea.queue_free()
	else:
		return

func execute(percentage, switchType) -> void:
	if switchType == "ZeroPanel":
		if percentage > 0.99:
			icontrol.changeReticle(icontrol.default_reticle)
			for light in SmallLightChildren:
				light.visible = false
			for light in LightChildren0a:
				light.visible = true
			for light in LightChildren0b:
				light.visible = true
			originalHighlight.find_child("AudioStreamPlayer3D", true, true).playing = true
			
			if originalHighlight.find_child("AudioStreamPlayerOn", true, true).playing == false:
				originalHighlight.find_child("AudioStreamPlayerOn", true, true).playing = true
			ic0.is_interacting = false
			ic0.can_interact = false
		
	elif switchType == "FirstPanel":
		if percentage > 0.99:
			if amp_here == 0.3 and freq_here == 0.33:
				for node in ObjectsToDisable:
					node.find_child("InteractionComponent", true, false).can_interact = false
					node.find_child("InteractionComponent", true, false).is_interacting = false
				icontrol.changeReticle(icontrol.default_reticle)
				IndicationLight.light_color = Color("#0a6100")
				emit_signal("firstPanelComplete")
			else:
				if ic1.is_interacting == false and ic1.is_switch_snapping == false:
					resetting_switch = true
	elif switchType == "SecondPanel":
		if percentage > 0.99:
			var symbols_on:Array[String] = []
			for symbol in secondPanelSymbols:
				if symbol.visible == true:
					symbols_on.append(symbol.name)
			if "ArrowUp" in symbols_on and "TriangleDown" in symbols_on and "ArrowsCenter" in symbols_on:
				for object in secondPanelInteractionObjects:
					object.find_child("InteractionComponent", true, true).is_interacting = false
					object.find_child("InteractionComponent", true, true).can_interact = false
				ic2.can_interact = false
				icontrol.changeReticle(icontrol.default_reticle)
				IndicationLight2.light_color = Color("#0a6100")
				emit_signal("secondPanelComplete")
			else:
				if ic2.is_interacting == false and ic2.is_switch_snapping == false:
					resetting_switch = true
	elif switchType == "ThirdPanel":
		if percentage > 0.99:
			if waveReady:
				emit_signal("endingSequence")
			else:
				if ic3.is_interacting == false and ic3.is_switch_snapping == false:
					resetting_switch = true

func _on_calculation_node_1_sin_amp(amp: float) -> void:
	amp_here = amp


func _on_calculation_node_1_sin_freq(freq: float) -> void:
	freq_here = freq


func _on_intercom_finished() -> void:
	if intercom.stream == FirstPanelVoice:
		await get_tree().create_timer(1.0).timeout
		for light in LightChildren2:
			light.visible = true
		secondControlPanelHighlight.find_child("AudioStreamPlayer3D", true, false).playing = true
		Sound2Trigger.monitoring = true
	elif intercom.stream == SecondPanelVoice:
		ic3.can_interact = true
		await get_tree().create_timer(1.75).timeout
		ic0.primary_audio_player.playing = true
		for light in LightChildren0a:
			light.visible = false
		for light in LightChildren0b:
			light.visible = false
		waveReady = true
	elif intercom.stream == ThirdPanelVoice:
		preControlPanelHighlight.queue_free()
		firstControlPanelHighlight.queue_free()
		secondControlPanelHighlight.queue_free()
		servers.queue_free()
		tables.queue_free()
		for speaker in Speakers:
			speaker.find_child("AudioStreamPlayer3D", true, true).playing = false
			speaker.queue_free()


func _on_first_panel_complete() -> void:
	if ic1.can_interact == false and ic1.is_switch_snapping == false:
		await get_tree().create_timer(0.2).timeout
		intercom.stream = FirstPanelVoice
		intercom.playing = true
		for object in secondPanelInteractionObjects:
			object.find_child("InteractionComponent", true, true).can_interact = true


func _on_sound_2_trigger_area_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		Sound2MetalStream.playing = true
		await get_tree().create_timer(0.4).timeout
		Sound2MetalStream.playing = true
		Sound2Trigger.queue_free()


func _on_second_panel_complete() -> void:
	await get_tree().create_timer(0.2).timeout
	intercom.stream = SecondPanelVoice
	intercom.playing = true


func _on_heavy_switch_placement_area_body_exited(body: Node3D) -> void:
	if body.name == "Heavy_switch_body":
		InstallationSound.playing = true
		body.queue_free()
		SwitchLockIn2.find_child("HeavySwitch", true, false).visible = true
		ic2.can_interact = true
		InstallationArea.set_deferred("monitoring", false)


func _on_ending_sequence() -> void:
	await get_tree().create_timer(0.2).timeout
	intercom.stream = ThirdPanelVoice
	intercom.playing = true
