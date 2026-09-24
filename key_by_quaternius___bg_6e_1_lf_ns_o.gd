extends Area3D

var player_near := false


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body.name == "Player":
		player_near = true
		print("KUNCI DITEMUKAN - TEKAN E")


func _on_body_exited(body):
	if body.name == "Player":
		player_near = false


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_E:
			if player_near:
				ambil_kunci()


func ambil_kunci():
	print("KUNCI DIDAPATKAN!")
	get_parent().visible = false
