extends Area3D

var player_near := false
var sudah_diambil := false


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body.name == "Player":
		player_near = true
		print("BUKU MISI DEKAT - TEKAN E")


func _on_body_exited(body):
	if body.name == "Player":
		player_near = false


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_E:
			if player_near and not sudah_diambil:
				get_viewport().set_input_as_handled()
				ambil_buku()


func ambil_buku():
	if sudah_diambil:
		return

	sudah_diambil = true

	print("BUKU MISI DITEMUKAN!")

	var mission_manager = get_tree().current_scene.get_node_or_null("MissionManager")

	if mission_manager == null:
		print("ERROR: MissionManager TIDAK DITEMUKAN!")
		return

	mission_manager.tambah_buku()

	get_parent().visible = false
