extends CanvasLayer
## HUD gameplay bernuansa horor, dibangun lewat kode. Dipasang lewat Global.pasang_hud(self).
## Fitur: vignette gelap, daftar tujuan, penghitung buku, pesan sementara (toast),
## kartu pop-up besar (judul + isi), prompt interaksi, dan kelopak mata (animasi bangun).
## Semua dipanggil lewat Global (pesan, kartu, tujuan, set_buku, prompt) supaya scene lain
## tidak perlu tahu detail HUD.

const UIStyle = preload("res://scenes/ui_style.gd")
const BookIcon = preload("res://scenes/book_icon.gd")

var _root: Control
var _tujuan_panel: PanelContainer
var _tujuan_label: Label
var _buku_panel: PanelContainer
var _buku_hbox: HBoxContainer
var _buku_label: Label
var _buku_ikon: Array = []
var _buku_lama: int = 0
var _pesan_panel: PanelContainer
var _pesan_label: Label
var _prompt_panel: PanelContainer
var _prompt_label: Label
var _kartu_panel: PanelContainer
var _kartu_judul: Label
var _kartu_isi: Label
var _bar_atas: ColorRect
var _bar_bawah: ColorRect
var _tween_pesan: Tween
var _tween_kartu: Tween


func _ready() -> void:
	layer = 20
	add_to_group("hud")

	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_bangun_vinyet()
	_bangun_tujuan()
	_bangun_buku()
	_bangun_bawah()
	_bangun_kartu()
	_bangun_kelopak()   # terakhir agar menutupi semuanya


# ------------------------------------------------------------------
# Pembangunan elemen
# ------------------------------------------------------------------
func _bangun_vinyet() -> void:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.8)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)

	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(rect)


func _bangun_tujuan() -> void:
	_tujuan_panel = PanelContainer.new()
	_tujuan_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tujuan_panel.add_theme_stylebox_override("panel", UIStyle.gaya_panel(UIStyle.LATAR_GELAP, Color(UIStyle.DARAH, 0.8), 6, 2))
	_tujuan_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_tujuan_panel.offset_left = -400.0
	_tujuan_panel.offset_right = -20.0
	_tujuan_panel.offset_top = 20.0
	_tujuan_panel.offset_bottom = 20.0
	_tujuan_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_tujuan_panel.visible = false
	_root.add_child(_tujuan_panel)

	_tujuan_label = UIStyle.buat_label("", 17, UIStyle.TULANG)
	_tujuan_label.custom_minimum_size = Vector2(350, 0)
	_tujuan_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tujuan_panel.add_child(_tujuan_label)


func _bangun_buku() -> void:
	_buku_panel = PanelContainer.new()
	_buku_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buku_panel.add_theme_stylebox_override("panel", UIStyle.gaya_panel(UIStyle.LATAR_GELAP, Color(UIStyle.KARAT, 0.7), 6, 2))
	_buku_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_buku_panel.offset_left = 20.0
	_buku_panel.offset_top = 20.0
	_buku_panel.offset_right = 20.0
	_buku_panel.offset_bottom = 20.0
	_buku_panel.visible = false
	_root.add_child(_buku_panel)

	_buku_hbox = HBoxContainer.new()
	_buku_hbox.add_theme_constant_override("separation", 6)
	_buku_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buku_panel.add_child(_buku_hbox)

	var judul := UIStyle.buat_label("BUKU", 16, UIStyle.KARAT)
	judul.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_buku_hbox.add_child(judul)

	_buku_label = UIStyle.buat_label("0/3", 18, UIStyle.TULANG)
	_buku_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _bangun_bawah() -> void:
	var bawah := VBoxContainer.new()
	bawah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bawah.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bawah.offset_left = 0.0
	bawah.offset_right = 0.0
	bawah.offset_top = -210.0
	bawah.offset_bottom = -28.0
	bawah.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bawah.alignment = BoxContainer.ALIGNMENT_END
	bawah.add_theme_constant_override("separation", 10)
	_root.add_child(bawah)

	_pesan_panel = PanelContainer.new()
	_pesan_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pesan_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_pesan_panel.add_theme_stylebox_override("panel", UIStyle.gaya_panel(UIStyle.LATAR_GELAP, UIStyle.DARAH, 6, 2, Color(UIStyle.DARAH, 0.3)))
	_pesan_panel.visible = false
	bawah.add_child(_pesan_panel)

	_pesan_label = UIStyle.buat_label("", 20, UIStyle.TULANG)
	_pesan_label.custom_minimum_size = Vector2(460, 0)
	_pesan_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pesan_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pesan_panel.add_child(_pesan_label)

	_prompt_panel = PanelContainer.new()
	_prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_prompt_panel.add_theme_stylebox_override("panel", UIStyle.gaya_panel(Color(0.05, 0.04, 0.04, 0.88), UIStyle.KARAT, 20, 2))
	_prompt_panel.visible = false
	bawah.add_child(_prompt_panel)

	_prompt_label = UIStyle.buat_label("", 20, UIStyle.KARAT)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_panel.add_child(_prompt_label)


func _bangun_kartu() -> void:
	_kartu_panel = PanelContainer.new()
	_kartu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kartu_panel.add_theme_stylebox_override("panel", UIStyle.gaya_panel(Color(0.06, 0.047, 0.045, 0.96), UIStyle.KARAT, 4, 2, Color(0, 0, 0, 0.6)))
	_kartu_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_kartu_panel.offset_left = -270.0
	_kartu_panel.offset_right = 270.0
	_kartu_panel.offset_top = 80.0
	_kartu_panel.offset_bottom = 80.0
	_kartu_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_kartu_panel.visible = false
	_root.add_child(_kartu_panel)

	var kotak := VBoxContainer.new()
	kotak.add_theme_constant_override("separation", 8)
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kartu_panel.add_child(kotak)

	_kartu_judul = UIStyle.buat_label("", 24, UIStyle.KARAT)
	_kartu_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_kartu_judul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kotak.add_child(_kartu_judul)

	var garis := ColorRect.new()
	garis.color = Color(UIStyle.DARAH_TERANG, 0.8)
	garis.custom_minimum_size = Vector2(0, 2)
	garis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kotak.add_child(garis)

	_kartu_isi = UIStyle.buat_label("", 19, UIStyle.TULANG)
	_kartu_isi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_kartu_isi.custom_minimum_size = Vector2(500, 0)
	kotak.add_child(_kartu_isi)


func _bangun_kelopak() -> void:
	_bar_atas = ColorRect.new()
	_bar_atas.color = Color.BLACK
	_bar_atas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_atas.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_bar_atas.visible = false
	_root.add_child(_bar_atas)

	_bar_bawah = ColorRect.new()
	_bar_bawah.color = Color.BLACK
	_bar_bawah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_bawah.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bar_bawah.visible = false
	_root.add_child(_bar_bawah)


# ------------------------------------------------------------------
# API publik (dipanggil lewat Global)
# ------------------------------------------------------------------
func set_objective(teks: String) -> void:
	_tujuan_label.text = teks
	_tujuan_panel.visible = teks != ""


func show_message(teks: String, durasi: float = 3.0) -> void:
	_pesan_label.text = teks
	_pesan_panel.modulate.a = 1.0
	_pesan_panel.visible = true
	if _tween_pesan != null and _tween_pesan.is_valid():
		_tween_pesan.kill()
	_tween_pesan = create_tween()
	_tween_pesan.tween_interval(durasi)
	_tween_pesan.tween_property(_pesan_panel, "modulate:a", 0.0, 0.5)
	_tween_pesan.tween_callback(_pesan_panel.hide)


func show_prompt(teks: String) -> void:
	_prompt_label.text = teks
	_prompt_panel.visible = true


func hide_prompt() -> void:
	_prompt_panel.visible = false


## Kartu pop-up besar di atas layar (judul + isi), muncul geser-turun lalu memudar.
func show_card(judul: String, isi: String, durasi: float = 5.0) -> void:
	_kartu_judul.text = judul
	_kartu_isi.text = isi
	if _tween_kartu != null and _tween_kartu.is_valid():
		_tween_kartu.kill()
	_kartu_panel.visible = true
	_kartu_panel.modulate.a = 0.0
	_kartu_panel.offset_top = 40.0
	_kartu_panel.offset_bottom = 40.0

	_tween_kartu = create_tween()
	_tween_kartu.set_parallel(true)
	_tween_kartu.tween_property(_kartu_panel, "modulate:a", 1.0, 0.45)
	_tween_kartu.tween_property(_kartu_panel, "offset_top", 80.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween_kartu.tween_property(_kartu_panel, "offset_bottom", 80.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween_kartu.chain().tween_interval(durasi)
	_tween_kartu.chain().tween_property(_kartu_panel, "modulate:a", 0.0, 0.6)
	_tween_kartu.chain().tween_callback(_kartu_panel.hide)


## Penghitung buku. Isi terbaru diberi animasi "pop".
func set_buku(jumlah: int, total: int) -> void:
	if _buku_ikon.size() != total:
		for ikon in _buku_ikon:
			ikon.queue_free()
		_buku_ikon.clear()
		if _buku_label.get_parent() != null:
			_buku_hbox.remove_child(_buku_label)
		for i in total:
			var ikon: Control = BookIcon.new()
			_buku_hbox.add_child(ikon)
			_buku_ikon.append(ikon)
		_buku_hbox.add_child(_buku_label)

	for i in total:
		var ikon_i: Control = _buku_ikon[i]
		var baru: bool = jumlah > _buku_lama and i == jumlah - 1
		ikon_i.set_terisi(i < jumlah, baru)

	_buku_label.text = "%d/%d" % [jumlah, total]
	_buku_lama = jumlah
	_buku_panel.visible = true

	if jumlah > 0:
		var tw := create_tween()
		_buku_panel.pivot_offset = _buku_panel.size / 2.0
		_buku_panel.scale = Vector2(1.12, 1.12)
		tw.tween_property(_buku_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## 0 = mata terbuka penuh, 1 = tertutup penuh.
func atur_kelopak(rasio: float) -> void:
	var tinggi_layar: float = get_viewport().get_visible_rect().size.y
	var h: float = tinggi_layar * 0.51 * clampf(rasio, 0.0, 1.0)
	var tampak: bool = rasio > 0.001
	_bar_atas.visible = tampak
	_bar_bawah.visible = tampak
	_bar_atas.offset_top = 0.0
	_bar_atas.offset_bottom = h
	_bar_bawah.offset_top = -h
	_bar_bawah.offset_bottom = 0.0


func tween_kelopak(dari: float, ke: float, durasi: float) -> Tween:
	var tw := create_tween()
	tw.tween_method(atur_kelopak, dari, ke, durasi).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw
