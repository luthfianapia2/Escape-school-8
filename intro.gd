extends Node3D

func _ready() -> void:
	# Memutar animasi intro secara otomatis begitu scene terbuka
	$AnimationPlayer2.play("intro_anim")
