extends Area3D

var player_near := false
var pintu_terbuka := false
var pesan_aktif := false


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Sembunyikan pesan pintu saat game baru dimulai
	var label = get_tree().current_scene.find_child("DoorMessage", true, false)

	if label:
		label.visible = false


func _on_body_entered(body):
	if body.name == "Player":
		player_near = true
		print("PINTU DEKAT - TEKAN E")


func _on_body_exited(body):
	if body.name == "Player":
		player_near = false


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_E:
			if player_near:
				coba_buka_pintu()


func coba_buka_pintu():
	if pintu_terbuka:
		return

	var sudah_punya_kunci = get_tree().current_scene.get_meta("key_obtained", false)

	if not sudah_punya_kunci:
		tampilkan_peringatan()
		return

	print("KUNCI SUDAH DIDAPATKAN - PINTU TERBUKA!")

	pintu_terbuka = true

	var door_pivot = get_parent()

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		door_pivot,
		"rotation_degrees:y",
		90.0,
		1.0
	)


func tampilkan_peringatan():
	if pesan_aktif:
		return

	pesan_aktif = true

	print("PINTU TERKUNCI! CARI KUNCI TERLEBIH DAHULU.")

	var label = get_tree().current_scene.find_child("DoorMessage", true, false)

	if label:
		label.text = "🔒 PINTU TERKUNCI\n\nCari kunci terlebih dahulu!"
		label.visible = true

		await get_tree().create_timer(3.0).timeout

		label.visible = false

	pesan_aktif = false
