extends Area3D

var is_inside = false

func _ready():
	pass

func _on_body_entered(body):
	if body.name == "PlayerClaire" or body.is_in_group("player"):
		is_inside = true

func _on_body_exited(body):
	if body.name == "PlayerClaire" or body.is_in_group("player"):
		is_inside = false

func _process(_delta):
	if is_inside and Input.is_action_just_pressed("interact"):
		if Global.has_door_code:
			print("PINTU TERBUKA! Kamu Berhasil Kabur!")
			get_tree().change_scene_to_file("res://scenes/scene_2_lab.tscn")
		else:
			print("Pintu Terkunci! Jawab kuis di meja dulu.")
