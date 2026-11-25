extends StaticBody3D
## Pasang di StaticBody3D komputer (yang punya CollisionShape3D menutupi monitor/meja).
## Saat pemain menekan E (lewat interactor.gd), muncul UI desktop 2D berisi kuis.
## Kalau semua jawaban benar, pintu terbuka (dicek oleh pintu_interact.gd).

const DESKTOP_UI_SCRIPT := preload("desktop_ui.gd")
const KUNCI_MISI := "misi_komputer_selesai"

@export var teks_hint := "[E] Gunakan Komputer"
@export var teks_hint_selesai := "Misi komputer sudah selesai"

var ui_instance: CanvasLayer = null
var player_ref: Node = null


func get_hint() -> String:
	if Engine.get_meta(KUNCI_MISI, false):
		return teks_hint_selesai
	return teks_hint


func interact(player: Node) -> void:
	if ui_instance != null:
		return
	if Engine.get_meta(KUNCI_MISI, false):
		return

	# kunci pemain: gerak + mouse look berhenti
	player_ref = player
	if player_ref != null:
		player_ref.set("velocity", Vector3.ZERO)
		player_ref.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# buat UI desktop 2D
	ui_instance = DESKTOP_UI_SCRIPT.new()
	get_tree().current_scene.add_child(ui_instance)
	ui_instance.connect("selesai", _on_desktop_selesai)


func _on_desktop_selesai(lulus: bool) -> void:
	if lulus:
		Engine.set_meta(KUNCI_MISI, true)

	if ui_instance != null:
		ui_instance.queue_free()
		ui_instance = null
	if player_ref != null:
		player_ref.process_mode = Node.PROCESS_MODE_INHERIT
		player_ref = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
