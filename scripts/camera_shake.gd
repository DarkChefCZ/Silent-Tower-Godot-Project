extends Camera3D

@export var trauma_reduction := 1.0
@export var noise_speed := 30.0
@export var max_shake := Vector3(1, 1, 0.5)

var trauma := 0.0
var noise := FastNoiseLite.new()
var t := 0.0

func _ready():
	noise.seed = randi()

func _process(delta):
	if trauma > 0.0:
		t += delta * noise_speed
		var intensity = trauma * trauma
		# Shake offset from noise
		var shake_x = noise.get_noise_1d(t * 0.9) * max_shake.x * intensity
		var shake_y = noise.get_noise_1d(t * 1.3) * max_shake.y * intensity
		var shake_z = noise.get_noise_1d(t * 1.7) * max_shake.z * intensity
		rotation = rotation + Vector3(shake_x, shake_y, shake_z)
		trauma = max(trauma - delta * trauma_reduction, 0.0)
	else:
		rotation = rotation


func add_trauma(amount: float):
	trauma = clamp(trauma + amount, 0.0, 1.0)
