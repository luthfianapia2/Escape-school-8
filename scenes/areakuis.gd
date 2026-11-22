extends "res://scenes/interactable.gd"
## Meja kuis. Terkunci sampai 3 buku ditemukan. Setelah kuis selesai, kunci emas muncul.

const UI_KUIS := preload("res://scenes/ui_kuis.tscn")
const BUKU_WAJIB := 3

var _layer: CanvasLayer = null
var _lampu: OmniLight3D = null
var _t: float = 0.0


func _ready() -> void:
	super()
	# Perbesar area agar mudah dijangkau.
	var cs := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs != null and cs.shape is BoxShape3D:
		var b := cs.shape as BoxShape3D
		b.size = Vector3(maxf(b.size.x, 3.4), maxf(b.size.y, 4.0), maxf(b.size.z, 3.4))

	_bangun_meja()
	perbarui_status()


func _bangun_meja() -> void:
	# Podium kecil dengan buku besar terbuka. Posisi relatif ke lantai (lantai ~ y 1.157).
	var lantai_y: float = 1.157
	var dasar: Vector3 = Vector3(global_position.x, lantai_y, global_position.z)
	var podium := Node3D.new()
	podium.name = "PodiumKuis"
	get_parent().add_child.call_deferred(podium)
	var kayu: StandardMaterial3D = StandardMaterial3D.new()
	kayu.albedo_color = Color(0.16, 0.09, 0.06)
	kayu.roughness = 0.9
	var kertas: StandardMaterial3D = StandardMaterial3D.new()
	kertas.albedo_color = Color(0.85, 0.78, 0.6)
	kertas.emission_enabled = true
	kertas.emission = Color(0.9, 0.55, 0.2)
	kertas.emission_energy_multiplier = 0.35
	var a: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = Vector3(0.7, 1.0, 0.7)
	a.mesh = bm
	a.material_override = kayu
	a.position = Vector3(0, 0.5, 0)
	podium.add_child(a)
	var b: MeshInstance3D = MeshInstance3D.new()
	var bm2: BoxMesh = BoxMesh.new()
	bm2.size = Vector3(0.55, 0.05, 0.4)
	b.mesh = bm2
	b.material_override = kertas
	b.position = Vector3(0, 1.03, 0)
	b.rotation_degrees = Vector3(-12, 0, 0)
	podium.add_child(b)
	# Tabrak kecil agar podium tidak bisa ditembus
	var sb: StaticBody3D = StaticBody3D.new()
	var csb: CollisionShape3D = CollisionShape3D.new()
	var bs: BoxShape3D = BoxShape3D.new()
	bs.size = Vector3(0.7, 1.0, 0.7)
	csb.shape = bs
	csb.position = Vector3(0, 0.5, 0)
	sb.add_child(csb)
	podium.add_child(sb)

	_lampu = OmniLight3D.new()
	_lampu.omni_range = 4.0
	_lampu.position = Vector3(0, 1.6, 0)
	podium.add_child(_lampu)
	podium.position = dasar


func _process(delta: float) -> void:
	_t += delta
	if is_instance_valid(_lampu):
		var dasar: float = 1.1 if _kuis_terbuka() else 0.35
		_lampu.light_energy = dasar + sin(_t * 2.0) * 0.1


func _kuis_terbuka() -> bool:
	return Global.barang_ditemukan >= BUKU_WAJIB and not Global.has_door_code


func perbarui_status() -> void:
	if Global.has_door_code:
		ubah_prompt("[E] Meja kuis (selesai)")
		if is_instance_valid(_lampu):
			_lampu.light_color = Color(0.8, 0.7, 0.4)
	elif Global.barang_ditemukan >= BUKU_WAJIB:
		ubah_prompt("[E] Kerjakan kuis")
		if is_instance_valid(_lampu):
			_lampu.light_color = Color(1.0, 0.8, 0.4)
	else:
		ubah_prompt("[E] Meja kuis (terkunci %d/%d)" % [Global.barang_ditemukan, BUKU_WAJIB])
		if is_instance_valid(_lampu):
			_lampu.light_color = Color(0.9, 0.2, 0.15)


func _interaksi() -> void:
	if Global.has_door_code:
		Global.pesan("Kuis sudah selesai. Cari cahaya keemasan di sisi timur.")
		return
	if Global.barang_ditemukan < BUKU_WAJIB:
		Global.sfx("locked")
		Global.kartu("Meja Terkunci", "Sebuah segel gelap menutup buku di meja ini. Temukan %d buku tersembunyi dulu (%d/%d)." % [BUKU_WAJIB, Global.barang_ditemukan, BUKU_WAJIB], 4.5)
		return
	if is_instance_valid(_layer):
		return

	_layer = CanvasLayer.new()
	_layer.layer = 30
	get_tree().current_scene.add_child(_layer)

	var ui := UI_KUIS.instantiate()
	_layer.add_child(ui)
	ui.kuis_selesai.connect(_on_kuis_selesai)
	ui.ditutup.connect(_on_kuis_ditutup)


func _on_kuis_selesai() -> void:
	Global.has_door_code = true


func _on_kuis_ditutup() -> void:
	if is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null
	perbarui_status()

	var scene_utama: Node = get_tree().current_scene
	if scene_utama != null and scene_utama.has_method("perbarui_tujuan"):
		scene_utama.perbarui_tujuan()
	if Global.has_door_code and scene_utama != null and scene_utama.has_method("muncul_kunci"):
		scene_utama.muncul_kunci()
