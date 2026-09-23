extends Node3D

@onready var door_left = $RootNode/Door_DoubleLeft
@onready var door_right = $RootNode/Door_DoubleRight

var is_open: bool = false
var is_player_near: bool = false

# Simpan rotasi awal (saat tertutup)
var rot_left_closed: float = 0.0
var rot_right_closed: float = 0.0

# Sudut keterbukaan pintu (dalam derajat)
var rot_left_open: float = -90.0
var rot_right_open: float = 90.0

# Variabel untuk menyimpan referensi tween agar bisa di-reset
var current_tween: Tween

func _ready():
	rot_left_closed = door_left.rotation_degrees.y
	rot_right_closed = door_right.rotation_degrees.y

func _input(event):
	# Deteksi pencet tombol Spasi / Enter / Tombol Interaksi (ui_accept) saat player di dekat pintu
	if is_player_near and event.is_action_pressed("ui_accept"):
		toggle_door()

func toggle_door():
	is_open = !is_open
	
	# Matikan tween sebelumnya jika masih berjalan (mencegah glitch saat dispam)
	if current_tween and current_tween.is_running():
		current_tween.kill()
	
	# Animasi halus pakai Tween
	current_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if is_open:
		current_tween.tween_property(door_left, "rotation_degrees:y", rot_left_closed + rot_left_open, 0.8)
		current_tween.tween_property(door_right, "rotation_degrees:y", rot_right_closed + rot_right_open, 0.8)
	else:
		current_tween.tween_property(door_left, "rotation_degrees:y", rot_left_closed, 0.8)
		current_tween.tween_property(door_right, "rotation_degrees:y", rot_right_closed, 0.8)

# Signal pendeteksi player mendekat/menjauh
func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		is_player_near = true

func _on_area_3d_body_exited(body):
	if body.is_in_group("player"):
		is_player_near = false
