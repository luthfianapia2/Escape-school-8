extends RayCast3D
## Pasang script ini di node RayCast3D (anak Camera3D) milik pemain.
## Script player lu tidak perlu diubah sama sekali.

@export var jarak := 3.0
@export var tampilkan_crosshair := true

var hint_label: Label


func _ready() -> void:
	enabled = true
	collide_with_bodies = true
	target_position = Vector3(0, 0, -jarak)  # lurus ke depan kamera
	_pastikan_input_interact()
	_buat_hud()


func _pastikan_input_interact() -> void:
	# otomatis membuat action "interact" (tombol E) jika belum ada di Input Map
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_E
		InputMap.action_add_event("interact", ev)


func _buat_hud() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 5
	add_child(cl)

	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 24)
	hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hint_label.add_theme_constant_override("outline_size", 6)
	hint_label.visible = false
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(hint_label)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_top = -140.0
	hint_label.offset_bottom = -100.0

	if tampilkan_crosshair:
		var dot := ColorRect.new()
		dot.color = Color(1, 1, 1, 0.8)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cl.add_child(dot)
		dot.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		dot.custom_minimum_size = Vector2(4, 4)
		dot.offset_left = -2.0
		dot.offset_right = 2.0
		dot.offset_top = -2.0
		dot.offset_bottom = 2.0


func _process(_delta: float) -> void:
	var obj: Node = _cari_interactable()
	if obj != null:
		if obj.has_method("get_hint"):
			hint_label.text = str(obj.call("get_hint"))
		else:
			hint_label.text = "[E] Interaksi"
		hint_label.visible = true
	else:
		hint_label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var obj: Node = _cari_interactable()
		if obj != null:
			hint_label.visible = false
			obj.call("interact", _cari_player())


func _cari_interactable() -> Node:
	if not is_colliding():
		return null
	var n = get_collider()
	while n != null and n is Node:
		if n.has_method("interact"):
			return n
		n = n.get_parent()
	return null


func _cari_player() -> Node:
	var n: Node = self
	while n != null:
		if n is CharacterBody3D:
			return n
		n = n.get_parent()
	return null
