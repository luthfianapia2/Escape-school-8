extends "res://scenes/interactable.gd"
## Pintu keluar. Dipasang HANYA pada PintuKeluar/CollisionShape3D/AreaPintu (sebuah Area3D).
## Syarat: kuis selesai (Global.has_door_code) DAN kunci diambil (Global.has_key).
## Saat terbuka, daun pintu berayun ke luar (engsel di ujung +Z), lalu lanjut ke scene berikutnya.

@export var butuh_semua_barang: bool = false
@export var jumlah_barang_wajib: int = 3

const Atmosfer := preload("res://scenes/atmosfer.gd")

const UIStyle := preload("res://scenes/ui_style.gd")

var _terbuka: bool = false
var _putar: float = 0.0            # kemajuan memutar kunci macet (0..1)
var _tonggak: int = 0
var _jatuh_dipicu: bool = false
var _bar_layer: CanvasLayer = null
var _bar_isi: ColorRect = null
var _daun: StaticBody3D = null
var _lampu_status: OmniLight3D = null
var _tulisan: Label3D = null
var _t: float = 0.0


func _ready() -> void:
	teks_prompt = "[E] Periksa pintu"
	super()
	# Struktur: PintuKeluar (StaticBody3D) > CollisionShape3D > AreaPintu (script ini)
	var cs := get_parent()
	if cs != null:
		_daun = cs.get_parent() as StaticBody3D
	if _daun != null:
		_percantik_pintu.call_deferred()   # ditunda: induk masih sibuk menyiapkan anak-anaknya


func _percantik_pintu() -> void:
	var mesh_lama := _daun.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_lama != null:
		var kayu := StandardMaterial3D.new()
		kayu.albedo_color = Color(0.36, 0.19, 0.09)
		kayu.roughness = 0.8
		mesh_lama.material_override = kayu

	# Panel timbul di daun pintu supaya terlihat seperti pintu kayu, bukan dinding.
	var gelap := StandardMaterial3D.new()
	gelap.albedo_color = Color(0.2, 0.1, 0.05)
	gelap.roughness = 0.9
	for ay in [0.55, -0.45]:
		var pnl := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(1.0, 0.8, 0.03)
		pnl.mesh = pb
		pnl.material_override = gelap
		pnl.position = Vector3(0.0, ay, 0.11)
		_daun.add_child(pnl)

	_bangun_kusen()

	var logam := StandardMaterial3D.new()
	logam.albedo_color = Color(0.75, 0.58, 0.25)
	logam.metallic = 0.9
	logam.roughness = 0.35

	# Gagang di sisi bebas (x lokal +0.5; pintu lebar 1.4 pada sumbu X lokal)
	for sisi in [-1.0, 1.0]:
		var g := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.06
		s.height = 0.12
		g.mesh = s
		g.material_override = logam
		g.position = Vector3(0.5, -0.1, 0.14 * sisi)
		_daun.add_child(g)

	_lampu_status = OmniLight3D.new()
	_lampu_status.light_color = Color(0.95, 0.15, 0.1)
	_lampu_status.light_energy = 2.4
	_lampu_status.omni_range = 7.0
	_lampu_status.position = Vector3(0.0, 1.45, 0.5)
	_daun.add_child(_lampu_status)

	var plat := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 0.15, 0.05)
	plat.mesh = bm
	var mp := StandardMaterial3D.new()
	mp.albedo_color = Color(0.9, 0.1, 0.08)
	mp.emission_enabled = true
	mp.emission = Color(0.9, 0.1, 0.08)
	mp.emission_energy_multiplier = 1.8
	plat.material_override = mp
	plat.position = Vector3(0.0, 1.45, 0.14)
	plat.name = "PlatStatus"
	_daun.add_child(plat)


## Kusen logam + papan "KELUAR" yang menyala, dipasang di dunia (tidak ikut berayun).
func _bangun_kusen() -> void:
	var dunia: Node = _daun.get_parent()
	if dunia == null:
		return
	var o: Vector3 = _daun.global_position
	var logam := StandardMaterial3D.new()
	logam.albedo_color = Color(0.55, 0.42, 0.18)
	logam.metallic = 0.8
	logam.roughness = 0.4
	var bagian: Array = [
		[Vector3(0.16, 2.7, 0.14), Vector3(-9.66, o.y + 0.1, o.z - 0.8)],
		[Vector3(0.16, 2.7, 0.14), Vector3(-9.66, o.y + 0.1, o.z + 0.8)],
		[Vector3(0.16, 0.14, 1.74), Vector3(-9.66, o.y + 1.45, o.z)],
	]
	for b in bagian:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = b[0]
		mi.mesh = bm
		mi.material_override = logam
		dunia.add_child(mi)
		mi.global_position = b[1]

	_tulisan = Label3D.new()
	_tulisan.text = "KELUAR"
	_tulisan.font_size = 64
	_tulisan.pixel_size = 0.0055
	_tulisan.modulate = Color(1.0, 0.25, 0.2)
	_tulisan.outline_modulate = Color(0.1, 0.0, 0.0)
	_tulisan.outline_size = 12
	_tulisan.shaded = false
	_tulisan.double_sided = true
	_tulisan.rotation_degrees = Vector3(0, 90, 0)
	dunia.add_child(_tulisan)
	_tulisan.global_position = Vector3(-9.6, o.y + 1.85, o.z)


func _process(delta: float) -> void:
	_t += delta
	if _lampu_status != null and not _terbuka:
		var siap: bool = Global.has_key and Global.has_door_code
		if siap:
			_lampu_status.light_color = Color(0.3, 1.0, 0.45)
			if _tulisan != null:
				_tulisan.modulate = Color(0.35, 1.0, 0.5)
		else:
			_lampu_status.light_energy = 2.0 + sin(_t * 2.5) * 0.6
	if _putar > 0.0 and not _terbuka:
		_putar = maxf(_putar - 0.22 * delta, 0.0)
		_perbarui_bar()
		if _putar <= 0.0:
			_tonggak = 0
			_sembunyikan_bar()
	# Saat pemain mendekati pintu membawa kunci, buku-buku berjatuhan dari rak.
	if not _jatuh_dipicu and Global.has_key and _daun != null:
		var pemain: Node3D = get_tree().get_first_node_in_group("player") as Node3D
		if pemain != null and pemain.global_position.distance_to(_daun.global_position) < 5.5:
			_jatuh_dipicu = true
			_jatuhkan_buku()
	if pemain_dekat and aktif:
		var teks: String = "[E] Putar kunci (tekan cepat!)" if (Global.has_key and Global.has_door_code) else "[E] Pintu terkunci"
		if teks != teks_prompt:
			ubah_prompt(teks)


func _interaksi() -> void:
	if _terbuka:
		return

	var kurang := PackedStringArray()
	if not Global.has_door_code:
		kurang.append("selesaikan kuis di meja")
	if not Global.has_key:
		kurang.append("temukan kunci")
	if butuh_semua_barang and Global.barang_ditemukan < jumlah_barang_wajib:
		kurang.append("temukan semua buku")

	if kurang.size() > 0:
		Global.sfx("locked")
		Global.kartu("Pintu Terkunci", "Gagangnya tak bergerak. Kamu harus: " + ", ".join(kurang) + ".", 4.0)
		return

	# Kunci berkarat dan macet: tekan E berulang-ulang dengan cepat untuk memutarnya.
	_putar = minf(_putar + 0.12, 1.0)
	Global.sfx("ratchet", -4.0, 0.9 + _putar * 0.4)
	_tampilkan_bar()
	var scene_utama: Node = get_tree().current_scene
	if _putar >= 0.5 and _tonggak < 1:
		_tonggak = 1
		Global.sfx("ketuk", -4.0, 0.8)
		Global.pesan("Sesuatu bergerak di balik pintu...", 3.0)
	if _putar >= 0.8 and _tonggak < 2:
		_tonggak = 2
		if scene_utama != null and scene_utama.has_method("kedip_lampu"):
			scene_utama.kedip_lampu()
	if _putar >= 1.0:
		_buka_pintu()


func _buka_pintu() -> void:
	_terbuka = true
	nonaktifkan()
	_sembunyikan_bar()
	Global.sfx("key")
	Global.sfx("geser", -4.0, 0.9)
	Global.pesan("Klik... pintu terbuka.", 3.0)
	var sc: Node = get_tree().current_scene
	if sc != null and sc.has_method("selesai_gempa"):
		sc.selesai_gempa()
	if _lampu_status != null:
		_lampu_status.light_color = Color(0.3, 1.0, 0.45)

	await _ayun_pintu()
	Atmosfer.teks_layar(self, "Kamu berhasil keluar...", "tapi ini belum berakhir.", 1.6, true)
	await get_tree().create_timer(3.2).timeout
	Global.next_scene()


func _tampilkan_bar() -> void:
	if _bar_layer == null:
		_bar_layer = CanvasLayer.new()
		_bar_layer.layer = 28
		add_child(_bar_layer)
		var box := PanelContainer.new()
		box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		box.offset_left = -210.0
		box.offset_right = 210.0
		box.offset_top = -190.0
		box.offset_bottom = -110.0
		box.add_theme_stylebox_override("panel", UIStyle.gaya_panel(Color(0.06, 0.045, 0.05, 0.95), UIStyle.DARAH, 8, 2, Color(UIStyle.DARAH_TERANG, 0.35)))
		_bar_layer.add_child(box)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		box.add_child(v)
		var l: Label = UIStyle.buat_label("KUNCI MACET!  Tekan E cepat-cepat", 20, UIStyle.DARAH_TERANG)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		var tempat := Control.new()
		tempat.custom_minimum_size = Vector2(380, 18)
		v.add_child(tempat)
		var latar := ColorRect.new()
		latar.color = Color(0.15, 0.1, 0.1)
		latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tempat.add_child(latar)
		_bar_isi = ColorRect.new()
		_bar_isi.color = UIStyle.KARAT
		_bar_isi.size = Vector2(0, 18)
		tempat.add_child(_bar_isi)
	_bar_layer.visible = true
	_perbarui_bar()


func _perbarui_bar() -> void:
	if _bar_isi != null:
		_bar_isi.size = Vector2(380.0 * clampf(_putar, 0.0, 1.0), 18.0)


func _sembunyikan_bar() -> void:
	if _bar_layer != null:
		_bar_layer.visible = false


## Buku-buku jatuh dari rak di dekat pintu (kosmetik: tidak menghalangi pemain secara fisik).
func _jatuhkan_buku() -> void:
	if _daun == null:
		return
	var dunia: Node = get_tree().current_scene
	var pangkal: Vector3 = _daun.global_position
	var warna: Array = [Color(0.45, 0.07, 0.08), Color(0.2, 0.12, 0.07), Color(0.12, 0.2, 0.28), Color(0.3, 0.25, 0.1)]
	var daftar: Array = []
	for i in 7:
		var rb := RigidBody3D.new()
		rb.collision_layer = 2   # lapisan 2: tidak memblokir pemain (pemain hanya mendeteksi lapisan 1)
		rb.collision_mask = 1
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(0.22, 0.06, 0.3)
		cs.shape = bs
		rb.add_child(cs)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = bs.size
		mi.mesh = bm
		var m := StandardMaterial3D.new()
		m.albedo_color = warna[i % warna.size()]
		mi.material_override = m
		rb.add_child(mi)
		dunia.add_child(rb)
		rb.global_position = Vector3(pangkal.x + randf_range(1.3, 2.6), pangkal.y + 1.3 + i * 0.22, pangkal.z + randf_range(-1.0, 1.0))
		rb.angular_velocity = Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3))
		daftar.append(rb)
	Global.sfx("jatuh", -4.0)
	Global.pesan("Buku-buku berjatuhan dari rak!", 3.0)
	await get_tree().create_timer(0.7).timeout
	Global.sfx("jatuh", -2.0, 0.85)
	await get_tree().create_timer(5.0).timeout
	for rb in daftar:
		if is_instance_valid(rb):
			rb.freeze = true


func _ayun_pintu() -> void:
	if _daun == null:
		return
	var awal: Transform3D = _daun.global_transform
	# Engsel di ujung global +Z (lebar pintu 1.4 sepanjang sumbu Z dunia setelah rotasi 90 derajat).
	var engsel: Vector3 = awal.origin + Vector3(0.0, 0.0, 0.7)
	var tw := create_tween()
	tw.tween_method(_set_ayun.bind(awal, engsel), 0.0, deg_to_rad(100.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


func _set_ayun(sudut: float, awal: Transform3D, engsel: Vector3) -> void:
	var rot := Basis(Vector3.UP, sudut)
	_daun.global_transform = Transform3D(rot * awal.basis, engsel + rot * (awal.origin - engsel))
