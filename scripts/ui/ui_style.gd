
extends RefCounted
class_name UIStyle

const BG_DARK := Color("#2B1C15")
const PANEL_DARK := Color("#513522")
const PANEL_LIGHT := Color("#F2DFC0")
const GOLD := Color("#D8A45D")
const TEXT_DARK := Color("#382316")
const TEXT_LIGHT := Color("#FFF0D5")
const BORDER := Color("#B8874F")

static func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_LIGHT
	style.border_color = BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style

static func button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_DARK
	style.border_color = GOLD
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func button_hover_style() -> StyleBoxFlat:
	var style := button_style()
	style.bg_color = Color("#805735")
	style.border_color = Color("#F5D49A")
	return style

static func button_pressed_style() -> StyleBoxFlat:
	var style := button_style()
	style.bg_color = Color("#382316")
	return style

static func button_disabled_style() -> StyleBoxFlat:
	var style := button_style()
	style.bg_color = Color("#756454")
	style.border_color = Color("#9C876E")
	return style

static func apply_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", button_style())
	button.add_theme_stylebox_override("hover", button_hover_style())
	button.add_theme_stylebox_override("pressed", button_pressed_style())
	button.add_theme_stylebox_override("disabled", button_disabled_style())

	button.add_theme_color_override("font_color", TEXT_LIGHT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_disabled_color", Color("#B9A58C"))

	button.add_theme_font_size_override("font_size", 18)

static func apply_label(label: Label, ukuran: int = 18) -> void:
	label.add_theme_color_override("font_color", TEXT_DARK)
	label.add_theme_font_size_override("font_size", ukuran)

static func apply_panel(panel: Panel) -> void:
	panel.add_theme_stylebox_override("panel", panel_style())

static func apply_input(input: LineEdit) -> void:
	var style := panel_style()
	style.bg_color = Color("#FFF5E5")
	style.set_corner_radius_all(8)

	input.add_theme_stylebox_override("normal", style)
	input.add_theme_stylebox_override("focus", button_hover_style())
	input.add_theme_color_override("font_color", TEXT_DARK)
	input.add_theme_color_override("caret_color", TEXT_DARK)
	input.add_theme_font_size_override("font_size", 20)
