
extends Area3D

var sudah_diambil: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if sudah_diambil:
		return

	if body.name != "PlayerClaire":
		return

	var scene_utama = get_tree().current_scene

	if not scene_utama.has_method("tambah_barang"):
		push_error("Fungsi tambah_barang() tidak ditemukan!")
		return

	sudah_diambil = true
	scene_utama.tambah_barang()

	print("Item ditemukan!")

	get_parent().hide()
