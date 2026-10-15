extends CanvasLayer

@onready var question_label = $Panel/QuestionLabel
@onready var button_a = $Panel/ButtonA
@onready var button_b = $Panel/ButtonB
@onready var button_c = $Panel/ButtonC
@onready var button_d = $Panel/ButtonD

var nomor_soal := 0
var question_mark
var key


var soal = [
	{
		"pertanyaan": "Apa yang dibutuhkan tumbuhan untuk melakukan fotosintesis?",
		"jawaban": [
			"A. Cahaya matahari",
			"B. Batu",
			"C. Pasir",
			"D. Plastik"
		],
		"benar": 0
	},
	{
		"pertanyaan": "Planet yang dikenal sebagai Planet Merah adalah...",
		"jawaban": [
			"A. Venus",
			"B. Mars",
			"C. Jupiter",
			"D. Saturnus"
		],
		"benar": 1
	},
	{
		"pertanyaan": "Air mendidih pada suhu berapa derajat Celsius?",
		"jawaban": [
			"A. 50°C",
			"B. 75°C",
			"C. 100°C",
			"D. 150°C"
		],
		"benar": 2
	},
	{
		"pertanyaan": "Organ tubuh manusia yang berfungsi memompa darah adalah...",
		"jawaban": [
			"A. Paru-paru",
			"B. Jantung",
			"C. Lambung",
			"D. Ginjal"
		],
		"benar": 1
	},
	{
		"pertanyaan": "Gaya yang menyebabkan benda jatuh ke bawah disebut...",
		"jawaban": [
			"A. Gaya gesek",
			"B. Gaya magnet",
			"C. Gaya gravitasi",
			"D. Gaya listrik"
		],
		"benar": 2
	}
]


func _ready():
	# Pertanyaan disembunyikan saat game mulai
	visible = false

	# Hubungkan tombol
	button_a.pressed.connect(jawab_a)
	button_b.pressed.connect(jawab_b)
	button_c.pressed.connect(jawab_c)
	button_d.pressed.connect(jawab_d)

	# Cari QuestionMark dan Key
	question_mark = get_tree().current_scene.get_node_or_null("Book/QuestionMark")
	key = get_tree().current_scene.get_node_or_null("Key")

	# Key disembunyikan di awal
	if key:
		key.visible = false


func _process(_delta):
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func mulai_soal():
	nomor_soal = 0

	# ==============================
	# HILANGKAN TEKS MISI
	# ==============================

	var mission_ui = get_tree().current_scene.get_node_or_null("MissionUI")

	if mission_ui:
		mission_ui.visible = false

	var mission_label = get_tree().current_scene.find_child("MissionLabel", true, false)

	if mission_label:
		mission_label.visible = false

	# ==============================
	# TAMPILKAN PERTANYAAN
	# ==============================

	visible = true

	tampilkan_soal()

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	print("QUESTION UI MUNCUL")
	print("TEKS MISI DISEMBUNYIKAN")


func tampilkan_soal():
	var data = soal[nomor_soal]

	question_label.text = data["pertanyaan"]

	button_a.text = data["jawaban"][0]
	button_b.text = data["jawaban"][1]
	button_c.text = data["jawaban"][2]
	button_d.text = data["jawaban"][3]

	button_a.visible = true
	button_b.visible = true
	button_c.visible = true
	button_d.visible = true


func sembunyikan_tombol():
	button_a.visible = false
	button_b.visible = false
	button_c.visible = false
	button_d.visible = false


func jawab_a():
	periksa_jawaban(0)


func jawab_b():
	periksa_jawaban(1)


func jawab_c():
	periksa_jawaban(2)


func jawab_d():
	periksa_jawaban(3)


func periksa_jawaban(pilihan):
	var jawaban_benar = soal[nomor_soal]["benar"]

	if pilihan == jawaban_benar:
		jawaban_benar_dipilih()
	else:
		jawaban_salah()


func jawaban_benar_dipilih():
	sembunyikan_tombol()

	# Hilangkan tanda ?
	if question_mark:
		question_mark.visible = false

	# Munculkan kunci
	if key:
		key.visible = true

	question_label.text = "BENAR!\n\nCLUE:\nKunci ruangan berikutnya berada di dekat meja praktikum bagian belakang."

	print("JAWABAN BENAR - KUNCI MUNCUL")

	await get_tree().create_timer(4.0).timeout

	visible = false

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func jawaban_salah():
	sembunyikan_tombol()

	question_label.text = "SALAH!\n\nSoal berikutnya akan muncul..."

	print("JAWABAN SALAH")

	await get_tree().create_timer(2.0).timeout

	nomor_soal += 1

	if nomor_soal >= soal.size():
		nomor_soal = 0

	tampilkan_soal()
