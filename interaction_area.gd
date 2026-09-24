extends Area3D

var player_near := false
var question_ui


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	question_ui = get_tree().current_scene.get_node("QuestionUI")


func _on_body_entered(body):
	if body.name == "Player":
		player_near = true
		print("BUKU DEKAT - TEKAN E")


func _on_body_exited(body):
	if body.name == "Player":
		player_near = false


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_E:
			if player_near:
				buka_pertanyaan()


func buka_pertanyaan():
	if question_ui:
		question_ui.visible = true
		print("PERTANYAAN MUNCUL!")
