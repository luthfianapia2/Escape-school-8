extends "res://scenes/interactable.gd"
## Buku tersembunyi di perpustakaan (dipasang pada Item1/Item2/Item3 -> Area3D).
## Efek: buku melayang pelan, bersinar redup (makin terang saat pemain dekat), debu cahaya,
## animasi saat diambil, dan kartu petunjuk buku berisi clue menuju buku berikutnya.

const PETUNJUK := {
	1: ["Buku 1/3 - \"Catatan Penjaga Malam\"", "Sampulnya berdebu. Isinya catatan seorang penjaga yang berjaga sampai pagi, halaman terakhirnya dirobek."],
	2: ["Buku 2/3 - \"Sejarah yang Dilupakan\"", "Tertulis dengan tinta pudar tentang hal-hal yang sengaja dilupakan orang."],
	3: ["Buku 3/3 - \"Kunci Bagi Yang Mau Belajar\"", "Halaman pertamanya hanya berisi satu kalimat: \"Kamu sudah sejauh ini.\""],
}

const UIStyle := preload("res://scenes/ui_style.gd")
const SANDI_KOTAK := "0315"   # dari coretan "Jam berhenti pukul 03:15"

var indeks: int = 1
var terkunci: bool = false
var _kaca: Node3D = null
var _layer_kode: CanvasLayer = null
var _input_sandi: LineEdit = null
var _hasil_sandi: Label = null
var _gembok_ui_aktif: bool = false
var _buku: Node3D = null
var _lampu: OmniLight3D = null
var _y_awal: float = 0.0
var _t: float = 0.0
var _diambil: bool = false
var butuh_senter: bool = false      # buku 2: hanya tampak bila disorot senter
var _vis: float = 1.0
var _skala_awal: Vector3 = Vector3.ONE
var _debu: CPUParticles3D = null
var _terlihat: bool = true


func _ready() -> void:
	teks_prompt = "[E] Periksa buku"
	super()
	var induk := get_parent()
	if induk != null:
		indeks = clampi(String(induk.name).substr(4).to_int(), 1, 3)
		# Kotak putih polos di bawah buku disembunyikan.
		if induk is MeshInstance3D:
			(induk as MeshInstance3D).mesh = null

	# Perbesar jangkauan agar buku di balik rak tetap bisa dijangkau (rak kini punya collision).
	var cs := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs != null and cs.shape is SphereShape3D:
		(cs.shape as SphereShape3D).radius = maxf((cs.shape as SphereShape3D).radius, 1.9)
		_buku = cs.get_node_or_null("books") as Node3D
	if _buku != null:
		_y_awal = _buku.position.y
		_skala_awal = _buku.scale
	butuh_senter = indeks == 2
	if butuh_senter:
		_vis = 0.0
		_terlihat = false
		aktif = false
		if _buku != null:
			_buku.scale = _skala_awal * 0.001

	# Buku 3 disimpan dalam kotak kaca bergembok sandi.
	terkunci = indeks == 3 and not Global.has_flag("kotak3_terbuka")

	_lampu = OmniLight3D.new()
	_lampu.light_color = Color(1.0, 0.8, 0.45)
	_lampu.light_energy = 0.12
	_lampu.omni_range = 2.2
	add_child(_lampu)
	_lampu.global_position = (_buku.global_position if _buku != null else global_position) + Vector3(0, 0.3, 0)

	var debu := CPUParticles3D.new()
	debu.amount = 14
	debu.lifetime = 2.4
	debu.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	debu.emission_sphere_radius = 0.45
	debu.gravity = Vector3(0, 0.12, 0)
	debu.initial_velocity_max = 0.06
	var bola := SphereMesh.new()
	bola.radius = 0.012
	bola.height = 0.024
	bola.radial_segments = 6
	bola.rings = 3
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.85, 0.5, 0.8)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bola.material = m
	debu.mesh = bola
	add_child(debu)
	debu.global_position = _lampu.global_position
	_debu = debu
	if butuh_senter:
		_debu.emitting = false

	if terkunci:
		teks_prompt = "[E] Kotak terkunci (sandi 4 digit)"
		_bangun_kotak()



func _process(delta: float) -> void:
	if _diambil:
		return
	_t += delta
	if butuh_senter:
		_perbarui_tampak(delta)
	if _buku != null:
		_buku.position.y = _y_awal + sin(_t * 1.6) * 0.04
	if _lampu != null:
		var kuat: float = 0.1 + sin(_t * 2.2) * 0.03
		var pemain: Node3D = get_tree().get_first_node_in_group("player") as Node3D
		if pemain != null:
			var jarak: float = pemain.global_position.distance_to(global_position)
			kuat += clampf((4.0 - jarak) / 4.0, 0.0, 1.0) * 0.8   # makin dekat makin terang
		if pemain_dekat:
			kuat += 0.3
		if butuh_senter:
			kuat *= _vis
		_lampu.light_energy = lerpf(_lampu.light_energy, kuat, clampf(delta * 5.0, 0.0, 1.0))


## Buku 2: muncul pelan bila senter menyorotnya (<= 7 m, sudut 30 derajat), lenyap bila tidak.
func _perbarui_tampak(delta: float) -> void:
	var pemain: Node = get_tree().get_first_node_in_group("player")
	var titik: Vector3 = (_buku.global_position if _buku != null else global_position) + Vector3(0, 0.2, 0)
	var disorot: bool = false
	if pemain != null and pemain.has_method("senter_menyorot"):
		disorot = pemain.senter_menyorot(titik, 7.0, 30.0)
	_vis = move_toward(_vis, 1.0 if disorot else 0.0, delta * (2.5 if disorot else 4.0))
	if _buku != null:
		_buku.scale = _skala_awal * maxf(_vis, 0.001)
	if _debu != null:
		_debu.emitting = _vis > 0.3
	var sekarang: bool = _vis > 0.6
	if sekarang != _terlihat:
		_terlihat = sekarang
		aktif = sekarang
		if pemain_dekat:
			if aktif:
				Global.prompt(teks_prompt)
			else:
				Global.sembunyi_prompt()


func _bangun_kotak() -> void:
	_kaca = Node3D.new()
	add_child(_kaca)
	var pusat: Vector3 = (_buku.global_position if _buku != null else global_position)
	_kaca.global_position = pusat
	var kaca := StandardMaterial3D.new()
	kaca.albedo_color = Color(0.55, 0.75, 0.9, 0.2)
	kaca.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	kaca.roughness = 0.1
	kaca.metallic = 0.3
	var kotak := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.5, 1.0, 1.5)
	kotak.mesh = bm
	kotak.material_override = kaca
	_kaca.add_child(kotak)
	# Gembok kecil di depan
	var emas := StandardMaterial3D.new()
	emas.albedo_color = Color(0.9, 0.7, 0.25)
	emas.metallic = 0.9
	emas.roughness = 0.35
	var badan := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(0.22, 0.26, 0.1)
	badan.mesh = bb
	badan.material_override = emas
	badan.position = Vector3(0, -0.25, 0.78)
	_kaca.add_child(badan)
	var busur := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.05
	tm.outer_radius = 0.09
	busur.mesh = tm
	busur.material_override = emas
	busur.rotation_degrees = Vector3(90, 0, 0)
	busur.position = Vector3(0, -0.08, 0.78)
	_kaca.add_child(busur)


## Keypad sandi dibangun langsung di sini (tidak butuh file UI lain).
func _buka_gembok() -> void:
	if is_instance_valid(_layer_kode):
		return
	_layer_kode = CanvasLayer.new()
	_layer_kode.layer = 30
	get_tree().current_scene.add_child(_layer_kode)

	var akar := Control.new()
	akar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer_kode.add_child(akar)
	var redup := ColorRect.new()
	redup.color = Color(0, 0, 0, 0.78)
	redup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	akar.add_child(redup)
	var tengah := CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	akar.add_child(tengah)
	var panel := PanelContainer.new()
	var gaya: StyleBoxFlat = UIStyle.gaya_panel(Color(0.06, 0.045, 0.05, 0.98), UIStyle.DARAH, 10, 3, Color(UIStyle.DARAH_TERANG, 0.4))
	gaya.set_content_margin_all(30.0)
	panel.add_theme_stylebox_override("panel", gaya)
	tengah.add_child(panel)
	var kotak := VBoxContainer.new()
	kotak.add_theme_constant_override("separation", 14)
	kotak.custom_minimum_size = Vector2(460, 0)
	panel.add_child(kotak)

	var judul: Label = UIStyle.buat_label("GEMBOK KOTAK", 30, UIStyle.DARAH_TERANG)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kotak.add_child(judul)
	var info: Label = UIStyle.buat_label("Gembok sandi 4 digit.\nAda angka yang pernah kamu lihat tertulis di ruangan ini...", 18, UIStyle.TULANG)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kotak.add_child(info)

	_input_sandi = LineEdit.new()
	_input_sandi.placeholder_text = "Ketik sandi..."
	_input_sandi.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_input_sandi.max_length = SANDI_KOTAK.length()
	_input_sandi.custom_minimum_size = Vector2(0, 56)
	_input_sandi.add_theme_font_size_override("font_size", 30)
	_input_sandi.text_submitted.connect(_cek_sandi)
	kotak.add_child(_input_sandi)

	var tombol: Button = UIStyle.buat_tombol("BUKA", 200, 48)
	tombol.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tombol.pressed.connect(_tekan_buka)
	kotak.add_child(tombol)

	_hasil_sandi = UIStyle.buat_label("", 20, UIStyle.TULANG)
	_hasil_sandi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hasil_sandi.custom_minimum_size = Vector2(0, 30)
	kotak.add_child(_hasil_sandi)
	var catatan: Label = UIStyle.buat_label("Tekan ESC untuk menutup", 14, UIStyle.TULANG_REDUP)
	catatan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kotak.add_child(catatan)

	Global.buka_ui()
	_gembok_ui_aktif = true
	_input_sandi.grab_focus.call_deferred()


func _tekan_buka() -> void:
	if _input_sandi != null:
		_cek_sandi(_input_sandi.text)


func _cek_sandi(teks: String) -> void:
	if not terkunci:
		return
	if teks.strip_edges() == SANDI_KOTAK:
		_hasil_sandi.text = "Klik... terbuka."
		_hasil_sandi.add_theme_color_override("font_color", Color(0.45, 0.85, 0.5))
		_on_gembok_benar()
		await get_tree().create_timer(0.8).timeout
		_tutup_gembok()
	else:
		Global.sfx("wrong")
		_hasil_sandi.text = "Sandi salah."
		_hasil_sandi.add_theme_color_override("font_color", Color(0.95, 0.25, 0.2))
		_input_sandi.clear()


func _input(event: InputEvent) -> void:
	if _gembok_ui_aktif and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_tutup_gembok()


func _tutup_gembok() -> void:
	if not _gembok_ui_aktif:
		return
	_gembok_ui_aktif = false
	if is_instance_valid(_layer_kode):
		_layer_kode.queue_free()
	_layer_kode = null
	Global.tutup_ui()


func _on_gembok_benar() -> void:
	Global.set_flag("kotak3_terbuka", true)
	terkunci = false
	Global.sfx("key")
	Global.pesan("Klik! Gembok terbuka.", 3.0)
	if _kaca != null:
		var tw := create_tween()
		tw.tween_property(_kaca, "scale", Vector3.ZERO, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(_kaca.hide)
	ubah_prompt("[E] Periksa buku")


func _interaksi() -> void:
	if terkunci:
		_buka_gembok()
		return
	var scene_utama: Node = get_tree().current_scene
	if scene_utama == null or not scene_utama.has_method("tambah_barang"):
		push_error("Fungsi tambah_barang() tidak ditemukan di scene utama!")
		return

	_diambil = true
	nonaktifkan()
	Global.sfx("pickup")

	if _buku != null:
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(_buku, "position:y", _buku.position.y + 0.7, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_buku, "scale", Vector3.ZERO, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(_buku.hide)
	if _lampu != null:
		var tl := create_tween()
		tl.tween_property(_lampu, "light_energy", 3.0, 0.15)
		tl.tween_property(_lampu, "light_energy", 0.0, 0.6)

	scene_utama.tambah_barang(indeks)
	var p: Array = PETUNJUK.get(indeks, ["Buku", ""])
	var isi: String = p[1]
	if scene_utama.has_method("teks_clue_tersisa"):
		isi += "\n\n" + scene_utama.teks_clue_tersisa()
	Global.kartu(p[0], isi, 10.0)
