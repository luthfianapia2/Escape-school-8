extends DirectionalLight3D

var original_energy: float = 1.0
var timer: float = 0.0
var next_flicker_time: float = 0.4

func _ready() -> void:
	original_energy = light_energy

func _process(delta: float) -> void:
	timer += delta
	if timer >= next_flicker_time:
		timer = 0.0
		next_flicker_time = randf_range(0.3, 0.8)
		
		# Efek meredup perlahan lalu terang kembali
		if randf() < 0.3:
			light_energy = original_energy * 0.1
		else:
			light_energy = original_energy
