extends Control

@onready var video_player = $Panel/VideoStreamPlay

func _ready():
	# Memastikan video langsung diputar saat layar kemenangan muncul
	if video_player and video_player.stream:
		video_player.play()
