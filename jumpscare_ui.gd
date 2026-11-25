extends CanvasLayer

@export var jumpscare_rect: TextureRect
@export var sfx_player: AudioStreamPlayer
@export var slide_offset: Vector2 = Vector2(-240.0, 240.0) # Offset awal dari posisi target (kiri & bawah)
@export var jump_duration: float = 0.10                 # Kecepatan melesat ("boom")
@export var visible_duration: float = 0.75              # Lama muncul di layar

var _target_pos: Vector2
var _start_pos: Vector2

func _ready() -> void:
	if jumpscare_rect:
		_target_pos = jumpscare_rect.position
		_start_pos = _target_pos + slide_offset
		jumpscare_rect.position = _start_pos
		jumpscare_rect.visible = false

func play_jumpscare() -> void:
	if sfx_player and sfx_player.stream:
		sfx_player.stop()
		sfx_player.play()

	if not jumpscare_rect:
		return

	jumpscare_rect.position = _start_pos
	jumpscare_rect.scale = Vector2(0.65, 0.65)
	jumpscare_rect.visible = true

	var tween := create_tween().set_parallel(true)
	tween.tween_property(jumpscare_rect, "position", _target_pos, jump_duration)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(jumpscare_rect, "scale", Vector2.ONE, jump_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(visible_duration).timeout
	jumpscare_rect.visible = false
	jumpscare_rect.position = _start_pos