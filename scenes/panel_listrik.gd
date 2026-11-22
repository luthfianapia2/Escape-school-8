extends "res://scenes/interactable.gd"
## Kotak sekring (panel listrik). Saat listrik padam, LED merah berkedip sebagai penanda.
## Menekan E saat padam = menyalakan listrik kembali (memanggil listrik_pulih() di scene utama).

var _gelap: bool = false
var _mat_led: StandardMaterial3D = null
var _lampu: OmniLight3D = null
var _t: float = 0.0


func _ready() -> void:
	teks_prompt = "[E] Periksa panel sekring"
	super()
	_bangun()


func _bangun() -> void:
	var cs := CollisionShape3D.new()
	var bs := SphereShape3D.new()
	bs.radius = 1.9
	cs.shape = bs
	cs.position = Vector3(0, 0.9, 0)
	add_child(cs)

	var logam := StandardMaterial3D.new()
	logam.albedo_color = Color(0.16, 0.18, 0.19)
	logam.metallic = 0.6
	logam.roughness = 0.5
	var pintu := StandardMaterial3D.new()
	pintu.albedo_color = Color(0.26, 0.29, 0.3)
	pintu.metallic = 0.5
	pintu.roughness = 0.45

	var badan := StaticBody3D.new()
	add_child(badan)
	var csb := CollisionShape3D.new()
	var bb := BoxShape3D.new()
	bb.size = Vector3(0.75, 1.5, 0.3)
	csb.shape = bb
	csb.position = Vector3(0, 0.75, 0)
	badan.add_child(csb)

	_kotak(badan, Vector3(0.75, 1.5, 0.3), Vector3(0, 0.75, 0), logam)
	_kotak(badan, Vector3(0.62, 1.25, 0.03), Vector3(0, 0.78, 0.16), pintu)
	# kaki
	_kotak(badan, Vector3(0.6, 0.06, 0.25), Vector3(0, 0.03, 0), logam)

	_mat_led = StandardMaterial3D.new()
	_mat_led.emission_enabled = true
	_mat_led.albedo_color = Color(1.0, 0.1, 0.05)
	_mat_led.emission = Color(1.0, 0.1, 0.05)
	_mat_led.emission_energy_multiplier = 2.0
	var led := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.04
	sp.height = 0.08
	led.mesh = sp
	led.material_override = _mat_led
	led.position = Vector3(0.2, 1.25, 0.19)
	add_child(led)

	var tulisan := Label3D.new()
	tulisan.text = "SEKRING\nUTAMA"
	tulisan.font_size = 48
	tulisan.pixel_size = 0.0045
	tulisan.modulate = Color(0.85, 0.8, 0.6, 0.9)
	tulisan.shaded = false
	tulisan.position = Vector3(0, 0.85, 0.185)
	add_child(tulisan)

	_lampu = OmniLight3D.new()
	_lampu.light_color = Color(1.0, 0.15, 0.08)
	_lampu.light_energy = 0.4
	_lampu.omni_range = 4.0
	_lampu.position = Vector3(0.2, 1.3, 0.5)
	add_child(_lampu)
	setel(false)


func _kotak(induk: Node3D, ukuran: Vector3, posisi: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = ukuran
	mi.mesh = bm
	mi.material_override = mat
	mi.position = posisi
	induk.add_child(mi)


## Dipanggil scene: true = listrik padam (LED merah berkedip), false = normal (LED hijau).
func setel(gelap: bool) -> void:
	_gelap = gelap
	if _mat_led != null:
		var w: Color = Color(1.0, 0.1, 0.05) if gelap else Color(0.1, 1.0, 0.3)
		_mat_led.albedo_color = w
		_mat_led.emission = w
	if _lampu != null:
		_lampu.light_color = w_lampu(gelap)
	ubah_prompt("[E] Nyalakan listrik" if gelap else "[E] Panel sekring (listrik normal)")


func w_lampu(gelap: bool) -> Color:
	return Color(1.0, 0.15, 0.08) if gelap else Color(0.2, 1.0, 0.4)


func _process(delta: float) -> void:
	_t += delta
	if _mat_led == null:
		return
	if _gelap:
		var nyala: bool = fmod(_t, 1.2) < 0.5
		_mat_led.emission_energy_multiplier = 3.0 if nyala else 0.15
		_lampu.light_energy = 1.0 if nyala else 0.05
	else:
		_mat_led.emission_energy_multiplier = 1.2
		_lampu.light_energy = 0.15


func _interaksi() -> void:
	if not _gelap:
		Global.pesan("Panel sekring. Listrik masih menyala.", 3.0)
		return
	Global.sfx("key")
	Global.sfx("reveal", -6.0)
	var scene_utama: Node = get_tree().current_scene
	if scene_utama != null and scene_utama.has_method("listrik_pulih"):
		scene_utama.listrik_pulih()
