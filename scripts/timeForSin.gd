extends ColorRect

func _process(_delta):
	material.set("shader_parameter/time", Time.get_ticks_msec() / 500.0)
