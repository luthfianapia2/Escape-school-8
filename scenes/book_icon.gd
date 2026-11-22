extends Control
## Ikon buku kecil untuk penghitung buku di HUD. Digambar lewat kode (tanpa tekstur).
## Kosong = siluet bergaris dengan "?", terisi = buku bersampul merah dengan pita emas.

const COVER := Color(0.45, 0.07, 0.08)
const PUNGGUNG := Color(0.26, 0.03, 0.05)
const EMAS := Color(0.86, 0.68, 0.3)
const HALAMAN := Color(0.9, 0.85, 0.7)

var terisi: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(40, 48)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = custom_minimum_size / 2.0
	resized.connect(func() -> void: pivot_offset = size / 2.0)


func set_terisi(nilai: bool, animasi: bool = false) -> void:
	terisi = nilai
	queue_redraw()
	if nilai and animasi:
		scale = Vector2(1.8, 1.8)
		modulate = Color(2.4, 1.9, 1.2)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "modulate", Color.WHITE, 0.7)


func _draw() -> void:
	var r := Rect2(Vector2(6, 4), Vector2(28, 40))
	if terisi:
		draw_rect(r, COVER)
		draw_rect(Rect2(r.position, Vector2(5, r.size.y)), PUNGGUNG)
		draw_rect(Rect2(r.position + Vector2(10, 9), Vector2(14, 3)), EMAS)
		draw_rect(Rect2(r.position + Vector2(10, 16), Vector2(14, 2)), Color(EMAS, 0.6))
		draw_rect(Rect2(r.position + Vector2(2, r.size.y - 4), Vector2(r.size.x - 3, 4)), HALAMAN)
		draw_rect(r, EMAS, false, 1.5)
	else:
		draw_rect(r, Color(0.1, 0.08, 0.08, 0.85))
		draw_rect(r, Color(0.4, 0.33, 0.3, 0.9), false, 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x, r.position.y + 28), "?", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 22, Color(0.5, 0.43, 0.38))
