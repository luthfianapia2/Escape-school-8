extends Label3D

var waktu := 0.0
var posisi_awal := 0.0


func _ready():
	posisi_awal = position.y


func _process(delta):
	waktu += delta
	position.y = posisi_awal + sin(waktu * 3.0) * 0.15
