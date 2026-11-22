extends Node
## Kejadian aneh di perpustakaan (tanpa jumpscare, tanpa hantu): buku jatuh sendiri,
## kursi bergeser sendiri, ketukan lalu lampu berkedip, langkah kaki samar.
## Dipasang otomatis oleh scene_1_library.gd. Tidak perlu diatur di editor.

const LANTAI_Y := 1.157

var _aktif: bool = true
var _terakhir: String = ""


func _ready() -> void:
	_loop.call_deferred()


func _exit_tree() -> void:
	_aktif = false


func _loop() -> void:
	await get_tree().create_timer(40.0).timeout
	# jeda antar kejadian [min, maks] per tingkat teror (makin lama pemain diam, makin sering)
	var jeda: Array = [[22.0, 45.0], [14.0, 26.0], [9.0, 16.0], [5.0, 10.0]]
	while _aktif:
		var tunggu: float = 0.0
		var target: float = randf_range(22.0, 45.0)
		while _aktif and tunggu < target:
			await get_tree().create_timer(1.0).timeout
			tunggu += 1.0
			var tingkat: int = 0
			if get_parent() != null and get_parent().has_method("tingkat_teror"):
				tingkat = get_parent().tingkat_teror()
			target = minf(target, float(jeda[tingkat][1]))
		if not _aktif:
			return
		if Global.cutscene or Global.ui_terbuka > 0:
			continue
		var daftar: Array = ["buku", "kursi", "ketuk_lampu", "langkah"]
		daftar.erase(_terakhir)
		var pilih: String = daftar.pick_random()
		_terakhir = pilih
		picu(pilih)


func picu(nama: String) -> void:
	match nama:
		"buku":
			_buku_jatuh()
		"kursi":
			_kursi_geser()
		"ketuk_lampu":
			_ketuk_lampu()
		"langkah":
			_langkah()
		"kursi_awal":
			_kursi_awal_geser()


func _pemain() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


# ------------------------------------------------------------------
# Buku jatuh dari atas, di sekitar pemain (kosmetik, tidak menghalangi)
# ------------------------------------------------------------------
func _buku_jatuh() -> void:
	var p := _pemain()
	if p == null:
		return
	var arah := Vector3(0, 0, -1)
	var kam := get_viewport().get_camera_3d()
	if kam != null:
		arah = -kam.global_basis.z
		arah.y = 0.0
		if arah.length() > 0.01:
			arah = arah.normalized()
	arah = arah.rotated(Vector3.UP, deg_to_rad(randf_range(-30.0, 30.0)))   # tepat di depan pandangan
	var pos: Vector3 = p.global_position + arah * randf_range(2.2, 3.5)
	pos.x = clampf(pos.x, -8.5, 8.5)
	pos.z = clampf(pos.z, -8.5, 8.5)
	pos.y = LANTAI_Y + 2.4

	var jumlah: int = randi_range(1, 3)
	for i in jumlah:
		var buku := RigidBody3D.new()
		buku.collision_layer = 2
		buku.collision_mask = 1
		var mesh := MeshInstance3D.new()
		var kotak := BoxMesh.new()
		kotak.size = Vector3(0.22, 0.04, 0.3)
		mesh.mesh = kotak
		var mat := StandardMaterial3D.new()
		mat.albedo_color = [Color(0.35, 0.08, 0.08), Color(0.12, 0.2, 0.3), Color(0.25, 0.18, 0.1)].pick_random()
		mesh.material_override = mat
		buku.add_child(mesh)
		var shape := CollisionShape3D.new()
		var bentuk := BoxShape3D.new()
		bentuk.size = kotak.size
		shape.shape = bentuk
		buku.add_child(shape)
		get_parent().add_child(buku)
		buku.global_position = pos + Vector3(randf_range(-0.2, 0.2), i * 0.25, randf_range(-0.2, 0.2))
		buku.rotation = Vector3(randf() * 3.0, randf() * 3.0, randf() * 3.0)
		buku.angular_velocity = Vector3(randf_range(-4, 4), randf_range(-4, 4), randf_range(-4, 4))
		get_tree().create_timer(30.0).timeout.connect(buku.queue_free)

	await get_tree().create_timer(0.55).timeout
	Global.sfx("jatuh", -4.0, randf_range(0.9, 1.1))


# ------------------------------------------------------------------
# Kursi bergeser sendiri
# ------------------------------------------------------------------
func _kursi_geser() -> void:
	var p := _pemain()
	var dek := get_parent().get_node_or_null("dekorasi")
	if p == null or dek == null:
		return
	var depan: Array[Node3D] = []
	var dekat: Array[Node3D] = []
	var semua: Array[Node3D] = []
	var kam := get_viewport().get_camera_3d()
	for c in dek.get_children():
		var k := c as Node3D
		if k == null or not String(k.name).begins_with("chair"):
			continue
		semua.append(k)
		var jarak: float = k.global_position.distance_to(p.global_position)
		if jarak > 2.0 and jarak < 7.0:
			dekat.append(k)
			if kam != null:
				var ke_kursi: Vector3 = (k.global_position - kam.global_position).normalized()
				if ke_kursi.dot(-kam.global_basis.z) > 0.6:
					depan.append(k)   # kursi yang sedang terlihat pemain
	var pilihan: Array[Node3D] = depan
	if pilihan.is_empty():
		pilihan = dekat if not dekat.is_empty() else semua
	if pilihan.is_empty():
		return
	_geser(pilihan.pick_random(), randf_range(0.9, 1.4))


func _kursi_awal_geser() -> void:
	var k := get_parent().get_node_or_null("KursiAwal") as Node3D
	if k != null:
		_geser(k, 1.0)


func _geser(k: Node3D, jarak: float) -> void:
	var arah := Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU)
	var target: Vector3 = k.global_position + arah * jarak
	target.x = clampf(target.x, -9.0, 9.0)
	target.z = clampf(target.z, -9.0, 9.0)
	Global.sfx("geser", -7.0, randf_range(0.9, 1.1))
	var tw := create_tween().set_parallel(true)
	tw.tween_property(k, "global_position", target, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(k, "rotation:y", k.rotation.y + randf_range(-0.6, 0.6), 1.2)


# ------------------------------------------------------------------
# Ketukan lalu lampu berkedip
# ------------------------------------------------------------------
func _ketuk_lampu() -> void:
	Global.sfx("ketuk", -8.0, randf_range(0.85, 1.0))
	await get_tree().create_timer(0.8).timeout
	var s := get_parent()
	if s != null and s.has_method("kedip_lampu"):
		s.kedip_lampu()


# ------------------------------------------------------------------
# Langkah kaki samar, menjauh
# ------------------------------------------------------------------
func _langkah() -> void:
	var volume: float = -12.0
	for i in 5:
		Global.sfx("step", volume, 0.7)
		volume -= 3.0
		await get_tree().create_timer(0.6).timeout
