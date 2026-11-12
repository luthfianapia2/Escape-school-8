extends Node3D

func _ready() -> void:
	# Memutar animasi intro/kamera secara otomatis begitu scene dibuka
	if has_node("AnimationPlayer2"):
		$AnimationPlayer2.play("intro_anim")
