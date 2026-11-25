extends CanvasLayer
## UI desktop 2D untuk misi komputer (kuis level SMP).
## Dibuat lewat kode, jadi cukup di-.new() lalu add_child() (lihat komputer_interact.gd).
## Sinyal "selesai" dikirim saat komputer ditutup. lulus = true kalau semua jawaban benar.

signal selesai(lulus: bool)

# "benar" = indeks jawaban benar di array "opsi" (urutan opsi diacak saat tampil)
const SOAL := [
	{
		"tanya": "Perangkat yang dipakai untuk mengetik huruf dan angka disebut ...",
		"opsi": ["Keyboard", "Monitor", "Speaker", "Printer"],
		"benar": 0,
	},
	{
		"tanya": "Bagian komputer yang bertugas memproses data dan sering disebut \"otak komputer\" adalah ...",
		"opsi": ["CPU", "Mouse", "Webcam", "Flashdisk"],
		"benar": 0,
	},
	{
		"tanya": "Perangkat output yang menampilkan gambar dan tulisan dari komputer adalah ...",
		"opsi": ["Scanner", "Monitor", "Keyboard", "Mikrofon"],
		"benar": 1,
	},
	{
		"tanya": "Windows, Linux, dan macOS termasuk jenis ...",
		"opsi": ["Perangkat keras", "Sistem operasi", "Aplikasi game", "Kabel jaringan"],
		"benar": 1,
	},
	{
		"tanya": "Kepanjangan dari RAM adalah ...",
		"opsi": ["Read Only Memory", "Random Access Memory", "Real Application Machine", "Run All Mode"],
		"benar": 1,
	},
	{
		"tanya": "Alat yang dipakai untuk menggerakkan kursor (pointer) di layar adalah ...",
		"opsi": ["Mouse", "Headset", "Proyektor", "Charger"],
		"benar": 0,
	},
]

var urutan: Array = []
var idx := 0
var skor := 0
var terkunci := false
var lulus := false
var teks_benar := ""

var label_progres: Label
var label_tanya: Label
var box_opsi: VBoxContainer
var label_info: Label
var tombol_aksi: Button


func _ready() -> void:
	layer = 100
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_bangun_ui()
	_mulai()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		selesai.emit(lulus)


func _bangun_ui() -> void:
	# latar gelap
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var tengah := CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(tengah)

	# jendela "desktop"
	var panel := PanelContainer.new()
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = Color(0.09, 0.12, 0.19)
	gaya.border_color = Color(0.35, 0.6, 1.0)
	gaya.set_border_width_all(3)
	gaya.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", gaya)
	tengah.add_child(panel)

	var margin := MarginContainer.new()
	for sisi in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + sisi, 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(680, 0)
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	# header: judul + tombol tutup
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var judul := Label.new()
	judul.text = "Misi 1 - Ujian Komputer"
	judul.add_theme_font_size_override("font_size", 26)
	judul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(judul)
	var tombol_tutup := Button.new()
	tombol_tutup.text = "Tutup (Esc)"
	tombol_tutup.pressed.connect(func(): selesai.emit(lulus))
	header.add_child(tombol_tutup)

	vbox.add_child(HSeparator.new())

	label_progres = Label.new()
	label_progres.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	vbox.add_child(label_progres)

	label_tanya = Label.new()
	label_tanya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_tanya.custom_minimum_size = Vector2(680, 60)
	label_tanya.add_theme_font_size_override("font_size", 20)
	vbox.add_child(label_tanya)

	box_opsi = VBoxContainer.new()
	box_opsi.add_theme_constant_override("separation", 8)
	vbox.add_child(box_opsi)

	label_info = Label.new()
	label_info.add_theme_font_size_override("font_size", 18)
	vbox.add_child(label_info)

	tombol_aksi = Button.new()
	tombol_aksi.custom_minimum_size = Vector2(0, 44)
	tombol_aksi.pressed.connect(_aksi_ditekan)
	vbox.add_child(tombol_aksi)


func _mulai() -> void:
	urutan = range(SOAL.size())
	urutan.shuffle()
	idx = 0
	skor = 0
	_tampil_soal()


func _bersihkan_opsi() -> void:
	for c in box_opsi.get_children():
		box_opsi.remove_child(c)
		c.queue_free()


func _tampil_soal() -> void:
	terkunci = false
	_bersihkan_opsi()
	tombol_aksi.visible = false
	label_info.text = ""

	var s: Dictionary = SOAL[urutan[idx]]
	label_progres.text = "Soal %d dari %d" % [idx + 1, urutan.size()]
	label_tanya.text = s["tanya"]

	var opsi: Array = s["opsi"].duplicate()
	teks_benar = opsi[s["benar"]]
	opsi.shuffle()
	for o in opsi:
		var b := Button.new()
		b.text = o
		b.custom_minimum_size = Vector2(0, 42)
		b.pressed.connect(_jawab.bind(b, o == teks_benar))
		box_opsi.add_child(b)


func _jawab(tombol: Button, benar: bool) -> void:
	if terkunci:
		return
	terkunci = true
	for b in box_opsi.get_children():
		b.disabled = true
		if b.text == teks_benar:
			b.modulate = Color(0.5, 1.0, 0.5)

	if benar:
		skor += 1
		label_info.text = "Benar!"
	else:
		tombol.modulate = Color(1.0, 0.5, 0.5)
		label_info.text = "Salah. Jawaban yang benar: " + teks_benar

	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	idx += 1
	if idx >= urutan.size():
		_tampil_hasil()
	else:
		_tampil_soal()


func _tampil_hasil() -> void:
	_bersihkan_opsi()
	label_progres.text = "Hasil"
	label_info.text = ""
	lulus = (skor == urutan.size())
	if lulus:
		label_tanya.text = "Hebat! Semua jawaban benar (%d/%d).\nMisi selesai. Pintu sudah terbuka, silakan menuju pintu." % [skor, urutan.size()]
		tombol_aksi.text = "Tutup Komputer"
	else:
		label_tanya.text = "Kamu benar %d dari %d soal.\nSemua soal harus benar supaya pintu terbuka. Coba lagi ya!" % [skor, urutan.size()]
		tombol_aksi.text = "Coba Lagi"
	tombol_aksi.visible = true


func _aksi_ditekan() -> void:
	if lulus:
		selesai.emit(true)
	else:
		_mulai()
