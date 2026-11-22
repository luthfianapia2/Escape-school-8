extends RefCounted
## Gaya UI bersama bernuansa horor (panel gelap, tulang-putih, merah darah, emas karat).
## Dipakai HUD, Main Menu, Ending, kuis, dan input kode agar tampilan seragam.
## Pemakaian: const UIStyle = preload("res://scenes/ui_style.gd")

# --- Palet horor ---
const LATAR_PANEL := Color(0.075, 0.06, 0.062)
const BESI := Color(0.17, 0.13, 0.13)
const TULANG := Color(0.9, 0.85, 0.74)
const TULANG_REDUP := Color(0.62, 0.57, 0.5)
const DARAH := Color(0.5, 0.08, 0.08)
const DARAH_TERANG := Color(0.82, 0.17, 0.13)
const KARAT := Color(0.86, 0.68, 0.3)

# --- Nama lama dipertahankan agar kode lama tetap jalan (nilainya kini palet horor) ---
const KRIM := LATAR_PANEL          # latar panel
const KRIM_GELAP := BESI           # tombol normal
const COKLAT_MUDA := Color(0.34, 0.09, 0.09)   # tombol hover
const COKLAT := DARAH              # garis tepi
const COKLAT_TUA := DARAH_TERANG   # judul
const TEKS := TULANG               # teks
const LATAR_GELAP := Color(0.03, 0.024, 0.026, 0.92)

static var _font: Font = null


## Font serif (Palatino/Georgia/Times) agar terasa seperti buku tua; fallback otomatis.
static func font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Palatino Linotype", "Book Antiqua", "Georgia", "Cambria", "Times New Roman", "serif"])
		_font = f
	return _font


static func gaya_panel(bg: Color = LATAR_PANEL, border: Color = DARAH, radius: int = 8, lebar_border: int = 2, glow: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(lebar_border)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(14.0)
	if glow.a > 0.0:
		s.shadow_color = glow
		s.shadow_size = 14
	return s


static func gayai_tombol(b: Button) -> void:
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", TULANG)
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.93, 0.82))
	b.add_theme_color_override("font_pressed_color", KARAT)
	b.add_theme_color_override("font_focus_color", TULANG)
	b.add_theme_color_override("font_disabled_color", Color(TULANG, 0.4))
	b.add_theme_stylebox_override("normal", gaya_panel(BESI, Color(DARAH, 0.8), 6, 2))
	b.add_theme_stylebox_override("hover", gaya_panel(COKLAT_MUDA, DARAH_TERANG, 6, 2, Color(DARAH_TERANG, 0.35)))
	b.add_theme_stylebox_override("pressed", gaya_panel(DARAH, KARAT, 6, 2))
	b.add_theme_stylebox_override("disabled", gaya_panel(Color(BESI, 0.6), Color(DARAH, 0.3), 6, 2))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


static func buat_tombol(teks: String, lebar: float = 280.0, tinggi: float = 50.0) -> Button:
	var b := Button.new()
	b.text = teks
	b.custom_minimum_size = Vector2(lebar, tinggi)
	gayai_tombol(b)
	return b


static func buat_label(teks: String, ukuran: int = 20, warna: Color = TULANG) -> Label:
	var l := Label.new()
	l.text = teks
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	return l
