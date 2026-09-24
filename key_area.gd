extends Area3D

var player_near := false


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Awalnya kunci belum didapat
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
			if player_near:
				ambil_kunci()


func ambil_kunci():
	print("KUNCI DIDAPATKAN!")

	# Tandai bahwa kunci sudah didapat
	get_tree().current_scene.set_meta("key_obtained", true)

	# Hilangkan tanda tanya di atas kunci
	var key_question_mark = get_parent().find_child("QuestionMark", true, false)

	if key_question_mark:
		key_question_mark.visible = false

	# Hilangkan kunci
	get_parent().visible = false

	# Hilangkan tanda tanya di atas buku
	var book_question_mark = get_tree().current_scene.find_child("QuestionMark", true, false)

	if book_question_mark:
		book_question_mark.visible = false

	print("KUNCI BERHASIL DIAMBIL!")
