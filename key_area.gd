extends Area3D

var player_near := false
var sudah_diambil := false


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	get_tree().current_scene.set_meta("key_obtained", false)


func _on_body_entered(body):
	if body.name == "Player":
		player_near = true
		print("KUNCI DEKAT - TEKAN E")


func _on_body_exited(body):
	if body.name == "Player":
		player_near = false


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_E:
			if player_near and not sudah_diambil:
				get_viewport().set_input_as_handled()
				ambil_kunci()


func ambil_kunci():
	if sudah_diambil:
		return

	sudah_diambil = true

	print("KUNCI DIDAPATKAN!")

	# Simpan status kunci
	get_tree().current_scene.set_meta("key_obtained", true)

	# Hilangkan tanda ? milik kunci jika ada
	var key_question_mark = get_parent().find_child("QuestionMark", true, false)

	if key_question_mark:
		key_question_mark.visible = false

	# Hilangkan objek kunci
	get_parent().visible = false

	# ==============================
	# TAMPILKAN MISI BARU
	# ==============================

	var mission_ui = get_tree().current_scene.get_node_or_null("MissionUI")
	var mission_label = get_tree().current_scene.find_child("MissionLabel", true, false)

	if mission_ui:
		mission_ui.visible = true

	if mission_label:
		mission_label.visible = true

		mission_label.text = "🔓 MISI DIPERBARUI\n\nKunci sudah kamu dapatkan.\nCari pintu keluar dari laboratorium."

		print("MISI PINTU KELUAR MUNCUL!")

		# Tampilkan selama 5 detik
		await get_tree().create_timer(5.0).timeout

	if mission_ui:
		mission_ui.visible = false

	if mission_label:
		mission_label.visible = false

	print("MISI PINTU KELUAR HILANG!")
