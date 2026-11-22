extends "res://scenes/interactable.gd"
## Buku petunjuk di meja. Isinya berubah sesuai progres pemain; tidak dihitung sebagai barang.


func _ready() -> void:
	teks_prompt = "[E] Baca catatan di meja"
	super()


func _interaksi() -> void:
	Global.sfx("pickup", -10.0, 0.7)
	var n: int = Global.barang_ditemukan
	if not Global.has_door_code:
		if n == 0:
			Global.kartu("Catatan di Meja", "\"Tiga buku tersembunyi di ruangan ini, cahayanya nyaris tak terlihat - kamu harus mendekat. Susuri rak demi rak (matikan senter dengan F kalau cahaya buku sulit terlihat). Kumpulkan ketiganya, lalu jawab pertanyaan di meja kuis.\"", 6.0)
		elif n < 3:
			Global.kartu("Catatan di Meja", "\"Baru %d dari 3 buku.\"\n\n%s" % [n, _clue()], 9.0)
		else:
			Global.kartu("Catatan di Meja", "\"Semua buku sudah terkumpul. Pergilah ke meja kuis di tengah ruangan.\"", 6.0)
	elif not Global.has_key:
		Global.kartu("Catatan di Meja", "\"Cahaya keemasan di sisi timur... itulah kuncinya.\"", 6.0)
	else:
		Global.kartu("Catatan di Meja", "\"Pintu keluar ada di sudut barat. Cepat, tempat ini mulai runtuh!\"", 6.0)


func _clue() -> String:
	var sc: Node = get_tree().current_scene
	if sc != null and sc.has_method("teks_clue_tersisa"):
		return sc.teks_clue_tersisa()
	return ""
