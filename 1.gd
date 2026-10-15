extends Area3D

var player_near := false
var sedang_membuka := false
var sudah_dibuka := false


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	monitoring = true
	monitorable = true


func _on_body_entered(body):
	if body.name == "Player":
		player_near = true
		print("BUKU PERTANYAAN DEKAT - TEKAN E")


func _on_body_exited(body):
	if body.name == "Player":
		player_near = false


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_E:

			if player_near and not sedang_membuka:
				get_viewport().set_input_as_handled()
				buka_buku()


func buka_buku():
	if sudah_dibuka:
		return

	var mission_manager = get_tree().current_scene.get_node_or_null("MissionManager")

	if mission_manager == null:
		print("ERROR: MissionManager TIDAK DITEMUKAN!")
		return

	if not mission_manager.misi_selesai:
		print("MISI BELUM SELESAI!")
		return

	sedang_membuka = true

	print("MEMBUKA BUKU PERTANYAAN...")

	# HILANGKAN TEKS MISI / ARAHAN
	var mission_ui = get_tree().current_scene.get_node_or_null("MissionUI")

	if mission_ui:
		mission_ui.visible = false

	# Animasi buku
	var buku = get_parent()

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.parallel().tween_property(
		buku,
		"position:y",
		buku.position.y + 0.15,
		0.4
	)

	tween.parallel().tween_property(
		buku,
		"rotation_degrees:z",
		buku.rotation_degrees.z + 5.0,
		0.4
	)

	await tween.finished

	sudah_dibuka = true
	sedang_membuka = false

	# Tampilkan QuestionUI
	var question_ui = get_tree().current_scene.get_node_or_null("QuestionUI")

	if question_ui:
		question_ui.mulai_soal()
		print("PERTANYAAN MUNCUL!")
	else:
		print("ERROR: QuestionUI TIDAK DITEMUKAN!")
