extends "res://scenes/interactable.gd"
## Kunci pintu keluar. Disembunyikan sampai kuis selesai; lalu muncul sebagai kunci emas 3D
## dengan sinar cahaya. Status disimpan di Global.has_key.

var _model: Node3D = null
var _lampu: OmniLight3D = null
var _sinar: MeshInstance3D = null
var _muncul: bool = false
var _t: float = 0.0


func _ready() -> void:
	teks_prompt = "[E] Ambil kunci"
	super()
	var lama := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if lama != null:
		lama.hide()
	var cs := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs != null and cs.shape is SphereShape3D:
		(cs.shape as SphereShape3D).radius = maxf((cs.shape as SphereShape3D).radius, 1.9)
	_bangun_model()
	# Tersembunyi sampai kuis selesai
	aktif = false
	monitoring = false
	_model.visible = false
	_sinar.visible = false
	_lampu.visible = false
	if Global.has_door_code and not Global.has_key:
		munculkan(false)


func _bangun_model() -> void:
	var emas := StandardMaterial3D.new()
	emas.albedo_color = Color(1.0, 0.78, 0.25)
	emas.metallic = 0.9
	emas.roughness = 0.3
	emas.emission_enabled = true
	emas.emission = Color(1.0, 0.65, 0.15)
	emas.emission_energy_multiplier = 1.4

	_model = Node3D.new()
	_model.name = "ModelKunci"
	add_child(_model)

	# Kepala kunci (cincin) di atas, tangkai ke bawah, gigi di ujung.
	var cincin := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.07
	torus.outer_radius = 0.15
	cincin.mesh = torus
	cincin.material_override = emas
	cincin.rotation_degrees = Vector3(90, 0, 0)
	cincin.position = Vector3(0, 0.3, 0)
	_model.add_child(cincin)

	var tangkai := MeshInstance3D.new()
	var sil := CylinderMesh.new()
	sil.top_radius = 0.03
	sil.bottom_radius = 0.03
	sil.height = 0.5
	tangkai.mesh = sil
	tangkai.material_override = emas
	tangkai.position = Vector3(0, 0.0, 0)
	_model.add_child(tangkai)

	for i in 3:
		var gigi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.14 - i * 0.03, 0.05, 0.04)
		gigi.mesh = bm
		gigi.material_override = emas
		gigi.position = Vector3(0.08 - i * 0.015, -0.2 + i * 0.09, 0)
		_model.add_child(gigi)

	_lampu = OmniLight3D.new()
	_lampu.light_color = Color(1.0, 0.8, 0.35)
	_lampu.light_energy = 1.1
	_lampu.omni_range = 3.6
	add_child(_lampu)

	_sinar = MeshInstance3D.new()
	var sl := CylinderMesh.new()
	sl.top_radius = 0.22
	sl.bottom_radius = 0.22
	sl.height = 4.0
	_sinar.mesh = sl
	var ms := StandardMaterial3D.new()
	ms.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ms.albedo_color = Color(1.0, 0.82, 0.4, 0.16)
	ms.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ms.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ms.cull_mode = BaseMaterial3D.CULL_DISABLED
	_sinar.material_override = ms
	_sinar.position = Vector3(0, 0.2, 0)
	add_child(_sinar)


func munculkan(dengan_efek: bool = true) -> void:
	if _muncul:
		return
	_muncul = true
	_model.visible = true
	_sinar.visible = true
	_lampu.visible = true
	aktif = true
	monitoring = true
	if dengan_efek:
		Global.sfx("reveal")
		_model.scale = Vector3.ZERO
		var tw := create_tween()
		tw.tween_property(_model, "scale", Vector3.ONE, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if not _muncul or _model == null:
		return
	_t += delta
	_model.rotate_y(delta * 1.4)
	_model.position.y = sin(_t * 2.0) * 0.07
	_lampu.light_energy = 1.0 + sin(_t * 3.0) * 0.25


func _interaksi() -> void:
	Global.has_key = true
	nonaktifkan()
	Global.sfx("key")
	_sinar.hide()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_model, "scale", Vector3.ZERO, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(_lampu, "light_energy", 0.0, 0.6)
	Global.kartu("Kunci Perpustakaan", "Kunci emas tua yang dingin di genggaman. Pintu keluar ada di sudut barat ruangan.", 5.0)

	var scene_utama: Node = get_tree().current_scene
	if scene_utama != null and scene_utama.has_method("perbarui_tujuan"):
		scene_utama.perbarui_tujuan()
	if scene_utama != null and scene_utama.has_method("mulai_gempa"):
		await get_tree().create_timer(1.5).timeout
		scene_utama.mulai_gempa()
