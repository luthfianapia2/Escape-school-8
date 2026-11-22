extends Control
## UI input kode (keypad sederhana). Dipakai Scene 3 (Lab Komputer).
## Panggil setup(...) SEBELUM add_child(). Sinyal: kode_benar, ditutup.

signal kode_benar
signal ditutup

const UIStyle = preload("res://scenes/ui_style.gd")

var judul: String = "TERMINAL"
var petunjuk: String = ""
var kode_target: String = ""

var _isian: LineEdit
var _hasil: Label
var _ui_dibuka: bool = false
var _benar: bool = false


func setup(judul_baru: String, petunjuk_baru: String, kode: String) -> void:
	judul = judul_baru
	petunjuk = petunjuk_baru
	kode_target = kode


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var redup := ColorRect.new()
	redup.color = Color(0, 0, 0, 0.7)
	redup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(redup)

	var tengah := CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tengah)

	var panel := PanelContainer.new()
	var gaya := UIStyle.gaya_panel(UIStyle.KRIM, UIStyle.COKLAT, 16, 3)
	gaya.set_content_margin_all(30.0)
	panel.add_theme_stylebox_override("panel", gaya)
	tengah.add_child(panel)

	var kotak := VBoxContainer.new()
	kotak.add_theme_constant_override("separation", 14)
	kotak.custom_minimum_size = Vector2(460, 0)
	panel.add_child(kotak)

	var l_judul := UIStyle.buat_label(judul, 30, UIStyle.COKLAT_TUA)
	l_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kotak.add_child(l_judul)

	var l_info := UIStyle.buat_label(petunjuk, 18, UIStyle.TEKS)
	l_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kotak.add_child(l_info)

	_isian = LineEdit.new()
	_isian.placeholder_text = "Ketik kode..."
	_isian.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_isian.max_length = kode_target.length()
	_isian.custom_minimum_size = Vector2(0, 56)
	_isian.add_theme_font_size_override("font_size", 30)
	_isian.text_submitted.connect(_cek_kode)
	kotak.add_child(_isian)

	var tombol := UIStyle.buat_tombol("MASUK", 200, 48)
	tombol.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tombol.pressed.connect(func() -> void: _cek_kode(_isian.text))
	kotak.add_child(tombol)

	_hasil = UIStyle.buat_label("", 20, UIStyle.TEKS)
	_hasil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hasil.custom_minimum_size = Vector2(0, 30)
	kotak.add_child(_hasil)

	var catatan := UIStyle.buat_label("Tekan ESC untuk menutup", 14, UIStyle.COKLAT)
	catatan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kotak.add_child(catatan)

	Global.buka_ui()
	_ui_dibuka = true
	_isian.grab_focus.call_deferred()


func _exit_tree() -> void:
	if _ui_dibuka:
		_ui_dibuka = false
		Global.tutup_ui()


# _input (bukan _unhandled_input) agar ESC tetap bekerja walau LineEdit sedang fokus.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_tutup()


func _cek_kode(teks: String) -> void:
	if _benar:
		return
	if teks.strip_edges() == kode_target:
		_benar = true
		Global.sfx("correct")
		_hasil.text = "AKSES DITERIMA!"
		_hasil.add_theme_color_override("font_color", Color(0.15, 0.45, 0.2))
		kode_benar.emit()
		await get_tree().create_timer(0.9).timeout
		if is_inside_tree():
			_tutup()
	else:
		Global.sfx("wrong")
		_hasil.text = "Kode salah. Coba lagi."
		_hasil.add_theme_color_override("font_color", Color(0.7, 0.15, 0.1))
		_isian.clear()


func _tutup() -> void:
	if is_queued_for_deletion():
		return
	ditutup.emit()
	queue_free()
