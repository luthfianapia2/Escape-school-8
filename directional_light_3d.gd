extends DirectionalLight3D

var original_energy: float = 1.0
var timer: float = 0.0
var next_flicker_time: float = 0.05

func _ready() -> void:
	original_energy = light_energy

func _process(delta: float) -> void:
	timer += delta
	if timer >= next_flicker_time:
		timer = 0.0
		next_flicker_time = randf_range(0.02, 0.15)
		
		# Sering mati total sebentar-sebentar
		if randf() < 0.5:
			light_energy = 0.0
		else:
			light_energy = original_energy * randf_range(0.1, 0.9)
