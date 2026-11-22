extends Area3D
## Basis semua objek yang bisa diinteraksi dengan tombol E (barang, kunci, kuis, pintu, dst.).
## Menangani: deteksi pemain (grup "player"), prompt "[E] ...", dan penekanan tombol E.
## Script turunan cukup meng-override _interaksi().
##
## Pemakaian di script turunan:
##   extends "res://scenes/interactable.gd"
##   func _ready() -> void:
##       teks_prompt = "[E] Ambil barang"
##       super()
##   func _interaksi() -> void:
##       ...

signal diinteraksi

@export var teks_prompt: String = "[E] Berinteraksi"

var pemain_dekat: bool = false
var aktif: bool = true


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not (pemain_dekat and aktif):
		return
	if Global.ui_terbuka > 0:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_interaksi()


## Override di script turunan. Bawaan: hanya memancarkan sinyal.
func _interaksi() -> void:
	diinteraksi.emit()


func nonaktifkan() -> void:
	aktif = false
	if pemain_dekat:
		Global.sembunyi_prompt()
	set_deferred("monitoring", false)


func ubah_prompt(teks: String) -> void:
	teks_prompt = teks
	if pemain_dekat and aktif:
		Global.prompt(teks_prompt)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	pemain_dekat = true
	if aktif:
		Global.prompt(teks_prompt)


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	pemain_dekat = false
	Global.sembunyi_prompt()
