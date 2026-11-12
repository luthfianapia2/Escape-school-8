extends DirectionalLight3D

var original_energy: float = 1.0
var timer: float = 0.0
var next_flicker_time: float = 0.2

func _ready() -> void:
	original_energy = light_energy

func _process(delta: float) -> void:
	timer += delta
	if timer >= next_flicker_time:
		timer = 0.0
		next_flicker_time = randf_range(0.1, 0.4)
		
		var chance = randf()
		if chance < 0.15:
			light_energy = 0.0       # Padam
		elif chance < 0.4:
			light_energy = original_energy * 1.5 # Berkedip lebih terang (menyala tajam)
		else:
			light_energy = original_energy # Normal
