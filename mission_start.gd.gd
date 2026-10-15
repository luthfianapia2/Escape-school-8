extends Area3D

var player_near := false
var sudah_dimulai := false


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var mission_ui = get_tree().current_scene.get_node_or_null("MissionUI")

	if mission_ui:
		mission_ui.visible = false


func _on_body_entered(body):
	if body.name == "Player":
		player_near = true
		print("MISI DEKAT - TEKAN E")


func _on_body_exited(body):
	if body.name == "Player":
		player_near = false


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_E:

			if player_near and not sudah_dimulai:
				get_viewport().set_input_as_handled()
				mulai_misi()


func mulai_misi():
	sudah_dimulai = true

	print("MISI DIMULAI!")

	# Hilangkan tanda ?
	var tanda_tanya = get_parent().get_node_or_null("MissionQuestion")

	if tanda_tanya:
		tanda_tanya.visible = false

	var mission_ui = get_tree().current_scene.get_node_or_null("MissionUI")
	var mission_label = get_tree().current_scene.find_child("MissionLabel", true, false)

	# Tampilkan MissionUI
	if mission_ui:
		mission_ui.visible = true

	# Tampilkan teks misi
	if mission_label:
		mission_label.visible = true
		mission_label.text = "MISI\n\nCari 2 buku, 2 rak, dan 3 botol."

		print("TEKS MISI MUNCUL!")
	else:
		print("ERROR: MissionLabel TIDAK DITEMUKAN!")

	# Tunggu 5 detik
	await get_tree().create_timer(5.0).timeout

	# Setelah 5 detik, ambil angka dari MissionManager
	var manager = get_tree().current_scene.get_node_or_null("MissionManager")

	if manager:
		manager.update_ui()
		print("PROGRESS MISI MUNCUL!")
	else:
		print("ERROR: MissionManager TIDAK DITEMUKAN!")

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
