extends Node

var freq_here: float = 0.0
var amp_here: float = 0.0


func _process(_delta: float) -> void:
	update_shader()

func update_shader():
	var mat = $blockbench_export/SubViewport/ColorRect.material
	mat.set_shader_parameter("amplitude", amp_here)
	mat.set_shader_parameter("frequency", freq_here)


func _on_calculation_node_1_sin_amp(amp: float) -> void:
	amp_here = amp


func _on_calculation_node_1_sin_freq(freq: float) -> void:
	freq_here = freq
