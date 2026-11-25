extends StaticBody3D
## Pasang di StaticBody3D yang bisa diinteraksi untuk quest.
## target_id: "question", "printer", atau "book"

@export var target_id: String = ""
@export var prompt_text: String = "Interaksi"
@export var box_size: Vector3 = Vector3(1, 1, 1)   # dipakai kalau tidak ada CollisionShape3D
@export var show_marker: bool = false              # true untuk tanda tanya
@export var marker_text: String = "?"

var _marker: Label3D
var _t := 0.0

func _ready() -> void:
	add_to_group("quest_target")
	collision_layer = 2          # layer yang dibaca RayCast3D pemain (mask 2)
	collision_mask = 0
	var has_shape := false
	for c in get_children():
		if c is CollisionShape3D:
			has_shape = true
	if not has_shape:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = box_size
		cs.shape = bs
		add_child(cs)
	if show_marker:
		_marker = Label3D.new()
		_marker.text = marker_text
		_marker.font_size = 256
		_marker.pixel_size = 0.004
		_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_marker.no_depth_test = true
		_marker.modulate = Color(1, 0.85, 0.1)
		_marker.outline_modulate = Color(0, 0, 0)
		_marker.position = Vector3(0, box_size.y * 0.5 + 0.4, 0)
		add_child(_marker)

func _process(delta: float) -> void:
	if _marker and _marker.visible:
		_t += delta
		_marker.position.y = box_size.y * 0.5 + 0.4 + sin(_t * 3.0) * 0.1

func set_marker_visible(v: bool) -> void:
	if _marker:
		_marker.visible = v
