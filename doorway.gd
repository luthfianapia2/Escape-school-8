extends StaticBody3D

# Menghubungkan ke AnimationPlayer yang ada di node pintu
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# Fungsi ini otomatis dipanggil oleh script player saat tombol E ditekan & terkena raycast
func interaksi(_ui_canvas = null) -> void:
	print("Pintu diinteraksi!")
	
	if anim_player:
		# Cek apakah animasi "open" ada
		if anim_player.has_animation("open"):
			# Jika pintu sedang tidak dimainkan animasinya, putar
			if not anim_player.is_playing():
				anim_player.play("open")
				print("Pintu terbuka!")
		else:
			print("Error: Animasi bernama 'open' tidak ditemukan di AnimationPlayer!")
