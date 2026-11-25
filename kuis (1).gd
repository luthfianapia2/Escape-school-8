extends Node
## Pasang di node UI_kuis. Soal diisi di bawah (SOAL) -- ganti sesuka hati.
## Node UI dicari lewat nama, jadi tidak perlu mengatur path.

signal kuis_selesai

# opsi: 4 pilihan (A-D), jawaban: index benar (0=A, 1=B, 2=C, 3=D)
const SOAL := [
	{
		"tanya": "Komponen yang berfungsi sebagai \"otak\" komputer adalah...",
		"opsi": ["RAM", "CPU", "Monitor", "Keyboard"],
		"jawaban": 1,
		"petunjuk": "Disebut juga prosesor.",
	},
	{
		"tanya": "Memori sementara yang isinya hilang saat komputer dimatikan adalah...",
		"opsi": ["RAM", "Hard disk", "SSD", "Flashdisk"],
		"jawaban": 0,
		"petunjuk": "Singkatan dari Random Access Memory.",
	},
	{
		"tanya": "Perangkat berikut yang termasuk perangkat input adalah...",
		"opsi": ["Monitor", "Printer", "Speaker", "Keyboard"],
		"jawaban": 3,
		"petunjuk": "Dipakai untuk memasukkan data ke komputer.",
	},
	{
		"tanya": "Satu byte terdiri dari berapa bit?",
		"opsi": ["2 bit", "4 bit", "8 bit", "16 bit"],
		"jawaban": 2,
		"petunjuk": "Sama dengan jumlah kaki laba-laba.",
	},
	{
		"tanya": "Perangkat output yang dipakai untuk mencetak dokumen ke kertas adalah...",
		"opsi": ["Scanner", "Printer", "Mouse", "Webcam"],
		"jawaban": 1,
		"petunjuk": "Baru saja kamu pakai di lab ini.",
	},
]

@export var player_name := "CharacterBody3D"   # pemain dibekukan selama kuis

var _idx := 0
var _benar := 0
var _terkunci := false
var _ringkasan := false
var _player: Node

var _l_nomor: Label
var _l_pemisah: Label
var _l_benar: Label
var _l_tanya: Label
var _l_hasil: Label
var _l_petunjuk: Label
var _btn: Array[Button] = []
var _b_petunjuk: Button
var _b_lanjut: Button

func _ready() -> void:
	_l_nomor = find_child("LabelNomorSoal", true, false) as Label
	_l_pemisah = find_child("LabelPemisah", true, false) as Label
	_l_benar = find_child("LabelBenar", true, false) as Label
	_l_tanya = find_child("LabelPertanyaan", true, false) as Label
	_l_hasil = find_child("LabelHasil", true, false) as Label
	_l_petunjuk = find_child("LabelPetunjukKunci", true, false) as Label
	_b_petunjuk = find_child("ButtonPetunjuk", true, false) as Button
	_b_lanjut = find_child("ButtonLanjut", true, false) as Button
	for n in ["ButtonA", "ButtonB", "ButtonC", "ButtonD"]:
		var b := find_child(n, true, false) as Button
		if b == null:
			push_warning("kuis.gd: " + n + " tidak ditemukan")
			continue
		_btn.append(b)
		b.pressed.connect(_pilih.bind(_btn.size() - 1))
	if _b_petunjuk:
		_b_petunjuk.pressed.connect(func(): if _l_petunjuk: _l_petunjuk.visible = not _l_petunjuk.visible)
	if _b_lanjut:
		_b_lanjut.pressed.connect(_lanjut)
	set("visible", false)

func buka() -> void:
	_idx = 0
	_benar = 0
	_ringkasan = false
	_tampil_soal()
	set("visible", true)
	_player = get_tree().current_scene.find_child(player_name, true, false)
	if _player:
		_player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _tutup() -> void:
	set("visible", false)
	if _player:
		_player.process_mode = Node.PROCESS_MODE_INHERIT
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	kuis_selesai.emit()

func _tampil_soal() -> void:
	var s: Dictionary = SOAL[_idx]
	_terkunci = false
	_teks(_l_nomor, "Soal %d/%d" % [_idx + 1, SOAL.size()])
	_teks(_l_pemisah, "|")
	_teks(_l_benar, "Benar: %d" % _benar)
	_teks(_l_tanya, s["tanya"])
	_teks(_l_hasil, "")
	_teks(_l_petunjuk, s["petunjuk"])
	if _l_petunjuk:
		_l_petunjuk.visible = false
	if _b_petunjuk:
		_b_petunjuk.visible = true
	for i in _btn.size():
		_btn[i].visible = true
		_btn[i].disabled = false
		_btn[i].modulate = Color.WHITE
		_btn[i].text = "%s. %s" % [char(65 + i), s["opsi"][i]]
	if _b_lanjut:
		_b_lanjut.visible = false

func _pilih(i: int) -> void:
	if _terkunci:
		return
	_terkunci = true
	var s: Dictionary = SOAL[_idx]
	var betul: bool = (i == s["jawaban"])
	if betul:
		_benar += 1
		_teks(_l_hasil, "Benar!")
	else:
		_teks(_l_hasil, "Salah! Jawaban yang benar: %s" % char(65 + int(s["jawaban"])))
	_teks(_l_benar, "Benar: %d" % _benar)
	for b in _btn:
		b.disabled = true
	_btn[s["jawaban"]].modulate = Color(0.4, 1.0, 0.4)
	if not betul:
		_btn[i].modulate = Color(1.0, 0.4, 0.4)
	if _b_lanjut:
		_b_lanjut.visible = true
		_b_lanjut.text = "Selesai" if _idx == SOAL.size() - 1 else "Lanjut"

func _lanjut() -> void:
	if _ringkasan:
		_tutup()
	elif _idx >= SOAL.size() - 1:
		_tampil_ringkasan()
	else:
		_idx += 1
		_tampil_soal()

func _tampil_ringkasan() -> void:
	_ringkasan = true
	_teks(_l_tanya, "Kuis selesai!")
	_teks(_l_hasil, "Skor kamu: %d/%d. Laci terbuka dan pintu keluar sekarang bisa dibuka." % [_benar, SOAL.size()])
	for b in _btn:
		b.visible = false
	if _b_petunjuk:
		_b_petunjuk.visible = false
	if _l_petunjuk:
		_l_petunjuk.visible = false
	if _b_lanjut:
		_b_lanjut.text = "Tutup"

func _teks(l: Label, t: String) -> void:
	if l:
		l.text = t
