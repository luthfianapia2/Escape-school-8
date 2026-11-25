extends Node3D

# Slot di Inspector untuk memasukkan gambar (seperti Pinhead nightmare.jpg)
@export var gambar_pop_up: Texture2D

# Fungsi ini dipanggil saat pemain menekan 'E' pada objek
func interaksi(ui: CanvasLayer):
	if gambar_pop_up and ui:
		ui.tampilkan_gambar(gambar_pop_up)
