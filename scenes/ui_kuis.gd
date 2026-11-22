extends Control
## UI kuis pilihan ganda (A-D). Dipakai ulang oleh Scene 1 (perpustakaan) dan Scene 2 (lab).
## Gunakan setup(...) SEBELUM menambahkan ke scene untuk mengganti judul/soal.
## Sinyal: kuis_selesai (semua soal terjawab benar), ditutup (UI dihapus).

signal kuis_selesai
signal ditutup

const UIStyle = preload("res://scenes/ui_style.gd")

@onready var label_judul = $Panel/VBoxContainer/LabelJudul
@onready var label_nomor = $Panel/VBoxContainer/PanelInformasi/BarInformasi/LabelNomorSoal
@onready var label_benar = $Panel/VBoxContainer/PanelInformasi/BarInformasi/LabelBenar
@onready var label_pertanyaan = $Panel/VBoxContainer/PanelPertanyaan/LabelPertanyaan
@onready var label_hasil = $Panel/VBoxContainer/LabelHasil
@onready var label_petunjuk = $Panel/VBoxContainer/LabelPetunjukKunci

@onready var button_a = $Panel/VBoxContainer/ButtonA
@onready var button_b = $Panel/VBoxContainer/ButtonB
@onready var button_c = $Panel/VBoxContainer/ButtonC
@onready var button_d = $Panel/VBoxContainer/ButtonD
@onready var button_petunjuk = $Panel/VBoxContainer/ButtonPetunjuk
@onready var button_lanjut = $Panel/VBoxContainer/ButtonLanjut

var judul: String = "KUIS PERPUSTAKAAN !!"
var petunjuk_akhir: String = "Petunjuk: sebuah cahaya keemasan muncul di sisi timur ruangan."

var nomor_soal = 0
var jawaban_benar = 0
var kuis_selesai_flag = false
var sedang_memproses = false
var _ui_dibuka = false

# Mode bawaan (Scene 1): pilihan diacak tiap putaran dan 3 kali salah = mulai dari awal.
# Jika setup() dipanggil (mis. Scene 2), mode ini mati dan soal dipakai apa adanya.
var pakai_soal_bawaan: bool = true
var maks_salah: int = 3
var jumlah_salah: int = 0

var soal = [
	{
		"pertanyaan": "Siapa penulis novel \"Laskar Pelangi\"?",
		"pilihan": ["Andrea Hirata", "Tere Liye", "Habiburrahman El Shirazy", "Pramoedya Ananta Toer"],
		"jawaban": 0,
		"petunjuk": "Novel tentang sepuluh anak dari Belitung."
	},
	{
		"pertanyaan": "Apa lambang kimia untuk unsur emas?",
		"pilihan": ["Ag", "Au", "Fe", "Gd"],
		"jawaban": 1,
		"petunjuk": "Berasal dari kata Latin 'aurum'."
	},
	{
		"pertanyaan": "Sistem klasifikasi perpustakaan dengan angka 000-999 disebut...",
		"pilihan": ["Dewey Decimal", "Morse", "Roman Numeral", "Binary"],
		"jawaban": 0,
		"petunjuk": "Nama penciptanya seorang pustakawan Amerika bernama Melvil..."
	},
	{
		"pertanyaan": "Sumpah Pemuda diikrarkan pada tahun...",
		"pilihan": ["1908", "1928", "1945", "1950"],
		"jawaban": 1,
		"petunjuk": "Tiga ikrar: satu tanah air, satu bangsa, satu bahasa."
	},
	{
		"pertanyaan": "Organ tubuh manusia yang menghasilkan hormon insulin adalah...",
		"pilihan": ["Hati", "Ginjal", "Pankreas", "Lambung"],
		"jawaban": 2,
		"petunjuk": "Letaknya di belakang lambung."
	},
	{
		"pertanyaan": "Hasil dari akar kuadrat 144 ditambah 3 pangkat 2 adalah...",
		"pilihan": ["15", "18", "21", "27"],
		"jawaban": 2,
		"petunjuk": "12 ditambah 9."
	},
	{
		"pertanyaan": "ISBN pada sampul buku adalah singkatan dari...",
		"pilihan": ["International Standard Book Number", "Indonesian School Book Name", "Internal System Book Note", "International Simple Book Network"],
		"jawaban": 0,
		"petunjuk": "Nomor unik standar internasional untuk sebuah buku."
	}
]


## Panggil sebelum add_child() untuk memakai soal sendiri.
func setup(judul_baru: String, soal_baru: Array, petunjuk_akhir_baru: String) -> void:
	judul = judul_baru
	soal = soal_baru
	petunjuk_akhir = petunjuk_akhir_baru
	pakai_soal_bawaan = false
	maks_salah = 0


func _ready():
	if not cek_node():
		return

	button_a.pressed.connect(func(): pilih_jawaban(0))
	button_b.pressed.connect(func(): pilih_jawaban(1))
	button_c.pressed.connect(func(): pilih_jawaban(2))
	button_d.pressed.connect(func(): pilih_jawaban(3))

	button_petunjuk.pressed.connect(tampilkan_petunjuk)
	button_lanjut.pressed.connect(lanjut_game)

	_rapikan_tata_letak()
	_acak_pilihan()

	button_lanjut.hide()
	label_petunjuk.hide()

	# UI terbuka: lepas mouse dan bekukan pemain (diatur terpusat di Global).
	Global.buka_ui()
	_ui_dibuka = true

	tampilkan_soal()


func _exit_tree() -> void:
	if _ui_dibuka:
		_ui_dibuka = false
		Global.tutup_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		lanjut_game()


func cek_node() -> bool:
	var semua_node = [
		label_judul,
		label_nomor,
		label_benar,
		label_pertanyaan,
		label_hasil,
		label_petunjuk,
		button_a,
		button_b,
		button_c,
		button_d,
		button_petunjuk,
		button_lanjut
	]

	for node in semua_node:
		if node == null:
			push_error("Node UI Kuis tidak ditemukan. Periksa nama dan susunan node.")
			return false

	return true


func _rapikan_tata_letak() -> void:
	# Latar gelap pekat + panel di tengah dengan tepi merah darah dan glow samar
	var latar := get_node_or_null("Background") as ColorRect
	if latar != null:
		latar.color = Color(0.01, 0.008, 0.01, 0.9)

	var panel := $Panel as Panel
	panel.anchor_left = 0.14
	panel.anchor_right = 0.86
	panel.anchor_top = 0.04
	panel.anchor_bottom = 0.96
	panel.offset_left = 0.0
	panel.offset_right = 0.0
	panel.offset_top = 0.0
	panel.offset_bottom = 0.0
	panel.add_theme_stylebox_override("panel", UIStyle.gaya_panel(Color(0.06, 0.045, 0.05, 0.98), UIStyle.DARAH, 10, 3, Color(UIStyle.DARAH_TERANG, 0.4)))

	var vbox: Control = $Panel/VBoxContainer
	vbox.offset_left = 44.0
	vbox.offset_right = -44.0
	vbox.offset_top = 26.0
	vbox.offset_bottom = -22.0
	(vbox as VBoxContainer).add_theme_constant_override("separation", 10)

	label_judul.text = "- " + judul + " -"
	label_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_judul.add_theme_font_override("font", UIStyle.font())
	label_judul.add_theme_font_size_override("font_size", 34)
	label_judul.add_theme_color_override("font_color", UIStyle.DARAH_TERANG)
	label_judul.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label_judul.add_theme_constant_override("shadow_offset_x", 2)
	label_judul.add_theme_constant_override("shadow_offset_y", 2)

	var info := $Panel/VBoxContainer/PanelInformasi as PanelContainer
	info.add_theme_stylebox_override("panel", UIStyle.gaya_panel(Color(0.12, 0.09, 0.09), Color(UIStyle.DARAH, 0.7), 6, 1))
	for l in [label_nomor, label_benar, $Panel/VBoxContainer/PanelInformasi/BarInformasi/LabelPemisah]:
		l.add_theme_font_override("font", UIStyle.font())
		l.add_theme_font_size_override("font_size", 19)
		l.add_theme_color_override("font_color", UIStyle.KARAT)

	var pp := $Panel/VBoxContainer/PanelPertanyaan as PanelContainer
	pp.add_theme_stylebox_override("panel", UIStyle.gaya_panel(Color(0.1, 0.075, 0.07), Color(UIStyle.TULANG_REDUP, 0.5), 6, 1))
	pp.custom_minimum_size = Vector2(0, 110)
	label_pertanyaan.add_theme_font_override("font", UIStyle.font())
	label_pertanyaan.add_theme_font_size_override("font_size", 27)
	label_pertanyaan.add_theme_color_override("font_color", UIStyle.TULANG)
	label_pertanyaan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_pertanyaan.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	for b in [button_a, button_b, button_c, button_d]:
		b.custom_minimum_size = Vector2(0, 52)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UIStyle.gayai_tombol(b)
		b.add_theme_font_size_override("font_size", 22)
		b.mouse_entered.connect(_suara_hover.bind(b))

	button_petunjuk.text = "Butuh petunjuk?"
	button_petunjuk.custom_minimum_size = Vector2(0, 44)
	UIStyle.gayai_tombol(button_petunjuk)

	button_lanjut.text = "Lanjutkan"
	button_lanjut.custom_minimum_size = Vector2(0, 52)
	UIStyle.gayai_tombol(button_lanjut)

	# Latar krem bawaan scene diganti gelap agar tulisan hasil terbaca.
	label_hasil.add_theme_stylebox_override("normal", UIStyle.gaya_panel(Color(0.09, 0.065, 0.07), Color(UIStyle.DARAH, 0.5), 6, 1))
	label_hasil.custom_minimum_size = Vector2(0, 40)
	label_hasil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_hasil.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_hasil.add_theme_font_override("font", UIStyle.font())
	label_hasil.add_theme_font_size_override("font_size", 22)
	label_petunjuk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_petunjuk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_petunjuk.add_theme_font_override("font", UIStyle.font())
	label_petunjuk.add_theme_font_size_override("font_size", 19)
	label_petunjuk.add_theme_color_override("font_color", UIStyle.KARAT)

	var catatan: Label = UIStyle.buat_label("Tekan ESC untuk menutup kuis", 14, UIStyle.TULANG_REDUP)
	catatan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(catatan)

	# Muncul perlahan
	modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.5)


func _suara_hover(b: Button) -> void:
	if not b.disabled:
		Global.sfx("klik", -20.0)


func tampilkan_soal():
	label_nomor.text = "SOAL %d/%d" % [nomor_soal + 1, soal.size()]
	label_benar.text = "Benar: %d" % jawaban_benar
	label_pertanyaan.text = soal[nomor_soal]["pertanyaan"]
	_ketik(label_pertanyaan)

	button_a.text = "A. " + soal[nomor_soal]["pilihan"][0]
	button_b.text = "B. " + soal[nomor_soal]["pilihan"][1]
	button_c.text = "C. " + soal[nomor_soal]["pilihan"][2]
	button_d.text = "D. " + soal[nomor_soal]["pilihan"][3]

	label_hasil.text = ""
	label_petunjuk.hide()


func _warna_hasil(benar: bool) -> void:
	if benar:
		label_hasil.add_theme_color_override("font_color", Color(0.45, 0.85, 0.5))
	else:
		label_hasil.add_theme_color_override("font_color", Color(0.95, 0.25, 0.2))


func pilih_jawaban(index):
	if kuis_selesai_flag or sedang_memproses:
		return

	if index != soal[nomor_soal]["jawaban"]:
		Global.sfx("wrong")
		_getar_panel()
		_warna_hasil(false)
		jumlah_salah += 1
		if maks_salah > 0 and jumlah_salah >= maks_salah:
			_ulang_dari_awal()
			return
		if maks_salah > 0:
			label_hasil.text = "SALAH... (kesempatan tersisa: %d)" % (maks_salah - jumlah_salah)
		else:
			label_hasil.text = "SALAH... coba lagi."
		return

	sedang_memproses = true
	jawaban_benar += 1
	label_benar.text = "Benar: %d" % jawaban_benar
	label_hasil.text = "BENAR! Lanjut ke soal berikutnya."
	_warna_hasil(true)
	Global.sfx("correct")

	button_a.disabled = true
	button_b.disabled = true
	button_c.disabled = true
	button_d.disabled = true

	await get_tree().create_timer(0.8).timeout

	# UI bisa saja sudah ditutup (ESC) selama jeda 0,8 detik.
	if not is_inside_tree():
		return

	nomor_soal += 1

	if nomor_soal >= soal.size():
		selesaikan_kuis()
	else:
		tampilkan_soal()

	if not kuis_selesai_flag:
		button_a.disabled = false
		button_b.disabled = false
		button_c.disabled = false
		button_d.disabled = false

	sedang_memproses = false


func tampilkan_petunjuk():
	if kuis_selesai_flag:
		return

	label_petunjuk.text = soal[nomor_soal]["petunjuk"]
	label_petunjuk.show()


func selesaikan_kuis():
	kuis_selesai_flag = true

	label_nomor.text = "KUIS SELESAI!"
	label_pertanyaan.text = "Hebat! Kamu berhasil menyelesaikan kuis!"
	label_hasil.text = "Jawaban benar: %d/%d" % [jawaban_benar, soal.size()]
	label_petunjuk.text = petunjuk_akhir
	label_petunjuk.show()

	button_a.hide()
	button_b.hide()
	button_c.hide()
	button_d.hide()
	button_petunjuk.hide()

	button_lanjut.show()
	Global.sfx("reveal")
	_ketik(label_pertanyaan)
	kuis_selesai.emit()


func lanjut_game():
	if is_queued_for_deletion():
		return
	ditutup.emit()
	queue_free()


## Efek mesin tik pada label.
func _ketik(l: Label) -> void:
	l.visible_ratio = 0.0
	var tw := create_tween()
	tw.tween_property(l, "visible_ratio", 1.0, clampf(l.text.length() * 0.025, 0.3, 1.6))


## Panel bergetar + kilatan merah saat jawaban salah.
func _getar_panel() -> void:
	var panel := $Panel as Panel
	var dasar: float = panel.position.x
	var tw := create_tween()
	for dx in [12.0, -12.0, 8.0, -8.0, 4.0, 0.0]:
		tw.tween_property(panel, "position:x", dasar + dx, 0.045)
	var kilat := get_node_or_null("Background") as ColorRect
	if kilat != null:
		kilat.color = Color(0.35, 0.02, 0.02, 0.92)
		var tk := create_tween()
		tk.tween_property(kilat, "color", Color(0.01, 0.008, 0.01, 0.9), 0.4)


## Acak urutan pilihan (hanya soal bawaan) dan hitung ulang indeks jawaban yang benar.
func _acak_pilihan() -> void:
	if not pakai_soal_bawaan:
		return
	for s in soal:
		var benar_teks: String = s["pilihan"][s["jawaban"]]
		var daftar: Array = s["pilihan"].duplicate()
		daftar.shuffle()
		s["pilihan"] = daftar
		s["jawaban"] = daftar.find(benar_teks)


## Terlalu banyak salah: segel menolak, soal dimulai dari awal dengan urutan pilihan baru.
func _ulang_dari_awal() -> void:
	sedang_memproses = true
	label_hasil.text = "Segel menolak jawabanmu... mulai dari awal."
	for b in [button_a, button_b, button_c, button_d]:
		b.disabled = true
	await get_tree().create_timer(1.6).timeout
	if not is_inside_tree():
		return
	# Hukuman: kuis ditutup, perpustakaan bereaksi (lihat hukuman_kuis di scene_1_library.gd)
	var scene_utama: Node = get_tree().current_scene
	if pakai_soal_bawaan and scene_utama != null and scene_utama.has_method("hukuman_kuis"):
		lanjut_game()
		scene_utama.hukuman_kuis()
		return
	nomor_soal = 0
	jawaban_benar = 0
	jumlah_salah = 0
	_acak_pilihan()
	for b in [button_a, button_b, button_c, button_d]:
		b.disabled = false
	tampilkan_soal()
	sedang_memproses = false
