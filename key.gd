extends StaticBody3D

# Fungsi ini akan dipanggil oleh karakter saat menembakkan RayCast ke kunci
func interaksi(ui_canvas = null) -> void:
	print("Kunci berhasil diambil!")
	
	# Tambahkan logika inventaris di sini jika ada, contoh:
	# if ui_canvas and ui_canvas.has_method("add_item"):
	#     ui_canvas.add_item("key")
	
	# Hapus objek kunci dari game
	queue_free()
