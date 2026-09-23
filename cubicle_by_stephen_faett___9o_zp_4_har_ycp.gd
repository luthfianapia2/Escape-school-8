extends StaticBody3D

@export var gambar_pop_up: Texture2D

func interaksi(ui: CanvasLayer):
	if gambar_pop_up and ui:
		ui.tampilkan_gambar(gambar_pop_up)
