extends OmniLight3D

var timer := 0.0
var next_flicker := 0.0

func _ready():
	randomize()
	next_flicker = randf_range(1.0, 3.0)

func _process(delta):
	timer += delta

	if timer >= next_flicker:
		timer = 0.0
		next_flicker = randf_range(1.0, 4.0)

		# Kedip cepat beberapa kali
		for i in range(3):
			light_energy = 0.0
			await get_tree().create_timer(0.08).timeout

			light_energy = 1.2
			await get_tree().create_timer(0.12).timeout

		# Kembali normal
		light_energy = 1.2
