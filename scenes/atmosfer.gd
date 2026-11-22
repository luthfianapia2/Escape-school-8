extends RefCounted

const UIStyle := preload("res://scenes/ui_style.gd")
## Pembantu suasana horor & collision otomatis untuk Scene 1 (semua dibangun lewat kode).
## Pemakaian: const Atmosfer = preload("res://scenes/atmosfer.gd")

# ------------------------------------------------------------------
# Lingkungan: gelap, berkabut, sedikit glow
# ------------------------------------------------------------------
static func pasang_lingkungan(scene: Node3D) -> void:
	var we: WorldEnvironment = scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we == null:
		we = WorldEnvironment.new()
		we.name = "WorldEnvironment"
		scene.add_child(we)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.012, 0.018)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.09, 0.13, 0.17)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.025, 0.045, 0.05)
	env.fog_density = 0.032
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.2
	env.adjustment_saturation = 0.68
	we.environment = env


# ------------------------------------------------------------------
# Cahaya: sinar bulan redup + lampu hangat berkedip
# ------------------------------------------------------------------
static func pasang_cahaya(scene: Node3D, lantai_y: float) -> Array:
	var kedip: Array = []

	var matahari: DirectionalLight3D = scene.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if matahari != null:
		matahari.light_energy = 0.16
		matahari.light_color = Color(0.5, 0.6, 0.9)
		matahari.shadow_enabled = false

	# Lampu utama yang sudah ada di scene dijadikan lampu hangat redup yang berkedip.
	var utama: OmniLight3D = scene.get_node_or_null("OmniLight3D") as OmniLight3D
	if utama != null:
		utama.light_energy = 0.55
		utama.light_color = Color(1.0, 0.72, 0.42)
		utama.omni_range = 11.0
		kedip.append({"lampu": utama, "dasar": 0.55, "t": randf() * 10.0, "kuat": 0.6})

	var titik: Array = [Vector3(-6.0, 4.2, -6.0), Vector3(6.0, 4.2, -5.0), Vector3(-5.5, 4.2, 5.5), Vector3(6.0, 4.2, 5.5)]
	var i: int = 0
	for p in titik:
		var l := OmniLight3D.new()
		l.name = "LampuRedup%d" % i
		l.position = p
		l.light_color = Color(1.0, 0.68, 0.38)
		l.light_energy = 0.5
		l.omni_range = 8.0
		l.omni_attenuation = 1.4
		scene.add_child(l)
		# hanya satu-dua lampu yang benar-benar berkedip supaya tidak norak
		if i == 1 or i == 3:
			kedip.append({"lampu": l, "dasar": 0.5, "t": randf() * 10.0, "kuat": 0.75})
		i += 1
	return kedip


## Dipanggil tiap frame oleh scene untuk menghidupkan kedipan.
static func perbarui_kedip(kedip: Array, delta: float, faktor: float = 1.0) -> void:
	for d in kedip:
		var lampu: OmniLight3D = d["lampu"]
		if not is_instance_valid(lampu):
			continue
		d["t"] = float(d["t"]) + delta
		var t: float = d["t"]
		var n: float = sin(t * 7.0) * sin(t * 13.3 + 1.7) * 0.5 + 0.5
		var gangguan: float = 1.0
		# sesekali "hampir mati" sebentar
		if fmod(t, 7.0) > 6.55 and n > 0.4:
			gangguan = 0.15
		lampu.light_energy = float(d["dasar"]) * (1.0 - float(d["kuat"]) * n * 0.5) * gangguan * faktor


# ------------------------------------------------------------------
# Debu melayang di udara
# ------------------------------------------------------------------
static func pasang_debu(scene: Node3D, lantai_y: float) -> void:
	var p := CPUParticles3D.new()
	p.name = "Debu"
	p.position = Vector3(0, lantai_y + 1.8, 0)
	p.amount = 140
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(9.0, 1.8, 9.0)
	p.direction = Vector3(0.2, 0.3, 0.1)
	p.spread = 180.0
	p.gravity = Vector3(0, 0.0, 0)
	p.initial_velocity_min = 0.03
	p.initial_velocity_max = 0.12
	var bola := SphereMesh.new()
	bola.radius = 0.014
	bola.height = 0.028
	bola.radial_segments = 6
	bola.rings = 3
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.9, 0.85, 0.72, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bola.material = m
	p.mesh = bola
	scene.add_child(p)


# ------------------------------------------------------------------
# Collision otomatis: kotak AABB untuk setiap model rak/kursi/meja
# ------------------------------------------------------------------
static func aabb_global(node: Node) -> AABB:
	var hasil := AABB()
	var ada: bool = false
	var daftar: Array = []
	if node is MeshInstance3D:
		daftar.append(node)
	for n in node.find_children("*", "MeshInstance3D", true, false):
		daftar.append(n)
	for n in daftar:
		var mi: MeshInstance3D = n as MeshInstance3D
		if mi.mesh == null:
			continue
		var kotak: AABB = mi.global_transform * mi.get_aabb()
		if ada:
			hasil = hasil.merge(kotak)
		else:
			hasil = kotak
			ada = true
	if not ada:
		return AABB()
	return hasil


## Tambahkan StaticBody3D berbentuk kotak untuk tiap node 3D di `daftar` (array Node).
## zona_bebas: daftar AABB yang tidak boleh diblokir (pintu, titik awal pemain, dll.)
## Mengembalikan jumlah collision yang dibuat.
static func pasang_collision(scene: Node3D, daftar: Array, zona_bebas: Array, tinggi_min: float = 0.5, lebar_min: float = 0.35) -> int:
	var jumlah: int = 0
	for anak in daftar:
		if not (anak is Node3D):
			continue
		var kotak: AABB = aabb_global(anak)
		if kotak.size == Vector3.ZERO:
			continue
		# lewati benda kecil / datar (laptop, mouse, kertas)
		if kotak.size.y < tinggi_min or maxf(kotak.size.x, kotak.size.z) < lebar_min:
			continue
		var bebas: bool = false
		for z in zona_bebas:
			if kotak.intersects(z):
				bebas = true
				break
		if bebas:
			continue
		var body := StaticBody3D.new()
		body.name = "Tabrak_" + String(anak.name).substr(0, 24).replace(" ", "_")
		var cs := CollisionShape3D.new()
		var bentuk := BoxShape3D.new()
		bentuk.size = Vector3(maxf(kotak.size.x, 0.1), kotak.size.y, maxf(kotak.size.z, 0.1))
		cs.shape = bentuk
		body.add_child(cs)
		scene.add_child(body)
		body.global_position = kotak.get_center()
		jumlah += 1
	return jumlah


# ------------------------------------------------------------------
# Material kecil yang sering dipakai
# ------------------------------------------------------------------
static func material_kayu(warna: Color = Color(0.22, 0.12, 0.07)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = warna
	m.roughness = 0.85
	return m


static func material_bercahaya(warna: Color, energi: float = 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = warna
	m.emission_enabled = true
	m.emission = warna
	m.emission_energy_multiplier = energi
	return m


static func buat_kotak(induk: Node3D, nama: String, ukuran: Vector3, posisi: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nama
	var bm := BoxMesh.new()
	bm.size = ukuran
	mi.mesh = bm
	mi.material_override = mat
	mi.position = posisi
	induk.add_child(mi)
	return mi


# ------------------------------------------------------------------
# Teks sinematik di tengah layar (judul bab / kalimat penutup)
# ------------------------------------------------------------------
static func teks_layar(scene: Node, judul: String, sub: String = "", tahan: float = 2.4, latar: bool = false) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	scene.add_child(layer)
	var akar := Control.new()
	akar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	akar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	akar.modulate = Color(1, 1, 1, 0)
	layer.add_child(akar)
	if latar:
		var gelap := ColorRect.new()
		gelap.color = Color(0, 0, 0, 0.88)
		gelap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gelap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		akar.add_child(gelap)
	var kotak := VBoxContainer.new()
	kotak.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kotak.alignment = BoxContainer.ALIGNMENT_CENTER
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	akar.add_child(kotak)
	var l1: Label = UIStyle.buat_label(judul, 52, UIStyle.DARAH_TERANG)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l1.add_theme_constant_override("shadow_offset_x", 3)
	l1.add_theme_constant_override("shadow_offset_y", 3)
	kotak.add_child(l1)
	if sub != "":
		var l2: Label = UIStyle.buat_label(sub, 22, UIStyle.TULANG_REDUP)
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kotak.add_child(l2)
	var tw: Tween = scene.create_tween()
	tw.tween_property(akar, "modulate:a", 1.0, 0.9)
	tw.tween_interval(tahan)
	tw.tween_property(akar, "modulate:a", 0.0, 1.0)
	tw.tween_callback(layer.queue_free)


# ------------------------------------------------------------------
# Coretan samar di dinding (hanya suasana; tanpa hantu)
# ------------------------------------------------------------------
static func pasang_tulisan_dinding(scene: Node3D, lantai_y: float) -> void:
	var yl: float = lantai_y + 0.03
	var yd: float = lantai_y + 2.3
	# [teks, posisi, rotasi (derajat x,y,z), ukuran_font]
	# Coretan di LANTAI (dibaca dari arah pemain mulai, menghadap -Z) + di dinding.
	var daftar: Array = [
		["JANGAN TERTIDUR\nDI SINI", Vector3(0.0, yl, -3.6), Vector3(-90, 0, 0), 120],
		["Baca. Ingat. Jawab.", Vector3(-1.0, yl, 3.2), Vector3(-90, 180, 0), 90],
		["yang membaca\nakan keluar", Vector3(5.5, yl, 0.5), Vector3(-90, 90, 0), 100],
		["Jam berhenti\npukul 03:15", Vector3(-5.5, yl, -0.5), Vector3(-90, -90, 0), 100],
		["||||  ||||  |||\nhari ke-14", Vector3(9.7, yd, 3.0), Vector3(0, -90, 0), 80],
		["JANGAN TERTIDUR\nDI SINI", Vector3(-3.5, yd + 1.2, -9.7), Vector3(0, 0, 0), 110],
		["Jam berhenti\npukul 03:15", Vector3(2.0, yd + 1.2, 9.7), Vector3(0, 180, 0), 90],
	]
	for d in daftar:
		var l := Label3D.new()
		l.text = d[0]
		l.font_size = d[3]
		l.pixel_size = 0.0075
		l.modulate = Color(0.85, 0.12, 0.08, 0.92)
		l.outline_size = 6
		l.outline_modulate = Color(0.12, 0.0, 0.0, 0.9)
		l.shaded = false
		l.double_sided = false
		l.rotation_degrees = d[2]
		scene.add_child(l)
		l.global_position = d[1]


# ------------------------------------------------------------------
# Pemadaman listrik: cahaya dasar nyaris habis (senter jadi satu-satunya penerang)
# ------------------------------------------------------------------
static func atur_gelap(scene: Node3D, gelap: bool) -> void:
	var we: WorldEnvironment = scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var bulan: DirectionalLight3D = scene.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	var tw: Tween = scene.create_tween()
	tw.set_parallel(true)
	if we != null and we.environment != null:
		tw.tween_property(we.environment, "ambient_light_energy", 0.02 if gelap else 0.42, 1.2)
	if bulan != null:
		tw.tween_property(bulan, "light_energy", 0.0 if gelap else 0.16, 1.2)
