extends Area3D

@export var ghost_sprite: Sprite3D          # Arahkan ke Sprite3D hantu di balik tembok
@export var end_marker: Marker3D            # Arahkan ke Marker3D tujuan akhir lintasan
@export var sfx_player: Node                # Bisa diisi AudioStreamPlayer atau AudioStreamPlayer3D
@export var sfx_delay: float = 0.0          # Jeda (detik) sebelum SFX bunyi saat mulai melintas
@export var cross_duration: float = 0.45    # Kecepatan melintas (makin kecil makin cepat)
@export var one_shot: bool = true           # true = sekali aja, false = bisa setiap lewat trigger

var _triggered: bool = false
var _start_pos: Vector3

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if ghost_sprite:
		_start_pos = ghost_sprite.global_position
		ghost_sprite.visible = false

func _on_body_entered(body: Node3D) -> void:
	if one_shot and _triggered:
		return
	if body is CharacterBody3D:
		_triggered = true
		_run_across()

func _play_sfx() -> void:
	if sfx_player and "stream" in sfx_player and sfx_player.stream != null:
		sfx_player.stop()
		sfx_player.play()

func _run_across() -> void:
	if not ghost_sprite or not end_marker:
		return

	ghost_sprite.global_position = _start_pos
	ghost_sprite.visible = true

	if sfx_delay > 0.0:
		await get_tree().create_timer(sfx_delay).timeout
		if not ghost_sprite.visible:
			return
	_play_sfx()

	var tween := create_tween()
	tween.tween_property(ghost_sprite, "global_position", end_marker.global_position, cross_duration)\
		.set_trans(Tween.TRANS_LINEAR)

	await tween.finished
	ghost_sprite.visible = false
	ghost_sprite.global_position = _start_pos
