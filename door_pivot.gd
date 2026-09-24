extends Node3D

var terbuka := false
var sedang_bergerak := false

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E and not sedang_bergerak:
			buka_tutup_pintu()

func buka_tutup_pintu():
	sedang_bergerak = true

	var target_rotation := rotation.y

	if terbuka:
		target_rotation = 0.0
	else:
		target_rotation = deg_to_rad(90.0)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation:y", target_rotation, 0.8)

	await tween.finished

	terbuka = not terbuka
	sedang_bergerak = false
