extends CharacterBody3D
## Player Claire (first-person). Dasar script dari teman; ditambah: animasi bangun dari kursi,
## senter (tombol F), head-bob + suara langkah, dan pembekuan saat UI/cutscene.
##
## Catatan animasi: file walk.res / run.res tidak ada di proyek, jadi animasi jalan/lari dari
## AnimationPlayer dilewati. Jika nanti ada animasi bernama "walk"/"run" (di AnimationPlayer
## player atau di model), script ini akan memakainya otomatis.

const WALK_SPEED = 5.0
const RUN_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

const PITCH_MAKS_DERAJAT := 70.0   # batas tengok atas/bawah

var current_speed = WALK_SPEED

# Pemetaan state -> [AnimationPlayer, nama animasi]. Dicari otomatis berdasarkan nama.
var _peta_anim: Dictionary = {}
var _state_anim: String = ""

var _cam_dasar_pos: Vector3 = Vector3.ZERO
var _bob_t: float = 0.0
var _langkah_siap: bool = true
var guncang: float = 0.0   # amplitudo guncangan kamera (meter), diatur scene saat gempa
var _senter: SpotLight3D = null
var _senter_niat: bool = false        # senter dinyalakan pemain (tombol F)
var senter_lemah: bool = false        # baterai lemah: senter sesekali mati sebentar
var _lemah_hitung: float = 6.0
var _senter_padam_sisa: float = 0.0

@onready var camera: Camera3D = get_node_or_null("Camera3D")
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var model_anim: AnimationPlayer = get_node_or_null("Idle/AnimationPlayer")


func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if camera:
		camera.rotation = Vector3(0, PI, 0)
		_cam_dasar_pos = camera.position
		_buat_senter()
	_siapkan_animasi()
	_putar("idle")


func _unhandled_input(event: InputEvent) -> void:
	if Global.ui_terbuka > 0 or Global.cutscene:
		return

	# ESC melepas/menangkap kembali mouse. Klik di jendela menangkap kembali.
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	# F = senter
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		if _senter != null:
			aktifkan_senter(not _senter_niat)
			Global.sfx("klik", -8.0)
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

		if camera:
			# Batasi tengok atas/bawah (tidak bisa jungkir balik). Dihitung dari arah pandang
			# sebenarnya, jadi tetap benar walau kamera diputar 180 derajat di scene.
			var d: float = -event.relative.y * MOUSE_SENSITIVITY
			camera.rotate_x(d)
			var naik: float = asin(clampf(-camera.basis.z.y, -1.0, 1.0))
			if absf(naik) > deg_to_rad(PITCH_MAKS_DERAJAT):
				camera.rotate_x(-d)


func _physics_process(delta: float) -> void:
	_proses_senter(delta)
	# Gravitasi
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Saat UI atau cutscene aktif, pemain berdiri diam.
	if Global.ui_terbuka > 0 or Global.cutscene:
		velocity.x = 0.0
		velocity.z = 0.0
		_putar("idle")
		move_and_slide()
		return

	# Lari (Shift)
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed = RUN_SPEED
	else:
		current_speed = WALK_SPEED

	# Mengambil input WASD / Panah (A & D ditukar karena model menghadap +Z)
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("left") or Input.is_action_pressed("ui_left"):
		input_dir.x += 1  # A = Kiri
	if Input.is_action_pressed("right") or Input.is_action_pressed("ui_right"):
		input_dir.x -= 1  # D = Kanan
	if Input.is_action_pressed("forward") or Input.is_action_pressed("ui_up"):
		input_dir.y += 1  # W = Maju
	if Input.is_action_pressed("backward") or Input.is_action_pressed("ui_down"):
		input_dir.y -= 1  # S = Mundur

	input_dir = input_dir.normalized()

	# Arah gerak berdasarkan rotasi player
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		if current_speed == RUN_SPEED:
			_putar("run")
		else:
			_putar("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		_putar("idle")

	move_and_slide()
	_goyang_kamera(delta)


# ------------------------------------------------------------------
# Head-bob + langkah kaki (pengganti animasi jalan pada kamera first-person)
# ------------------------------------------------------------------
func _goyang_kamera(delta: float) -> void:
	if camera == null or Global.cutscene:
		return

	var kecepatan: float = Vector2(velocity.x, velocity.z).length()
	var bergerak: bool = kecepatan > 0.5 and is_on_floor()
	var target: Vector3 = Vector3.ZERO

	if bergerak:
		_bob_t += delta * kecepatan * 1.9
		target = Vector3(cos(_bob_t * 0.5) * 0.018, sin(_bob_t) * 0.035, 0.0)
		var s: float = sin(_bob_t)
		if s < -0.9 and _langkah_siap:
			_langkah_siap = false
			Global.sfx("step", -12.0 + (3.0 if current_speed == RUN_SPEED else 0.0), randf_range(0.9, 1.1))
		elif s > 0.0:
			_langkah_siap = true

	if guncang > 0.0:
		target += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * guncang

	var offset: Vector3 = camera.position - _cam_dasar_pos
	offset = offset.lerp(target, clampf(delta * 12.0, 0.0, 1.0))
	camera.position = _cam_dasar_pos + offset


# ------------------------------------------------------------------
# Senter
# ------------------------------------------------------------------
func _buat_senter() -> void:
	_senter = SpotLight3D.new()
	_senter.name = "Senter"
	_senter.spot_range = 11.0
	_senter.spot_angle = 30.0
	_senter.spot_attenuation = 1.0
	_senter.light_energy = 1.9
	_senter.light_color = Color(1.0, 0.93, 0.78)
	_senter.shadow_enabled = false
	_senter.visible = false
	camera.add_child(_senter)


## true bila senter menyala dan sorotannya mengarah ke `titik` (dipakai buku yang hanya tampak di bawah cahaya).
func senter_menyorot(titik: Vector3, jarak_maks: float, sudut_maks_deg: float) -> bool:
	if _senter == null or not _senter.visible or camera == null:
		return false
	var arah: Vector3 = titik - camera.global_position
	var jarak: float = arah.length()
	if jarak > jarak_maks:
		return false
	if jarak < 0.05:
		return true
	var maju: Vector3 = -camera.global_transform.basis.z
	return rad_to_deg(maju.angle_to(arah / jarak)) <= sudut_maks_deg


func aktifkan_senter(nyala: bool) -> void:
	_senter_niat = nyala
	if _senter != null:
		_senter.visible = nyala and _senter_padam_sisa <= 0.0


## Baterai lemah: sesekali senter mati 0,5-1 detik lalu menyala lagi.
## Senter mati paksa selama `durasi` detik, lalu kembali ke pilihan pemain (dipakai gangguan).
func senter_kedip(durasi: float) -> void:
	if _senter == null or not _senter_niat:
		return
	_senter_padam_sisa = durasi
	_senter.visible = false


func _proses_senter(delta: float) -> void:
	if _senter == null:
		return
	if _senter_padam_sisa > 0.0:
		_senter_padam_sisa -= delta
		if _senter_padam_sisa <= 0.0:
			_senter.visible = _senter_niat
			if _senter_niat:
				Global.sfx("klik", -10.0)
		return
	if senter_lemah and _senter_niat:
		_lemah_hitung -= delta
		if _lemah_hitung <= 0.0:
			_lemah_hitung = randf_range(5.0, 10.0)
			_senter_padam_sisa = randf_range(0.5, 1.1)
			_senter.visible = false


# ------------------------------------------------------------------
# Animasi bangun dari kursi (dipanggil di awal Scene 1)
# Kamera mulai rendah (kepala di meja, mata tertutup), lalu: mata terbuka grogi,
# berkedip, kepala terangkat, menoleh kiri-kanan, kursi terdorong, berdiri.
# ------------------------------------------------------------------
func bangun_dari_kursi(kursi: Node3D = null) -> void:
	if camera == null:
		return

	Global.cutscene = true
	var pos0: Vector3 = _cam_dasar_pos
	var arah_maju: Vector3 = -global_transform.basis.z * -1.0   # maju = +Z lokal player
	arah_maju.y = 0.0
	arah_maju = arah_maju.normalized()

	# Pose tertidur: kepala bersandar di meja
	camera.position = pos0 + Vector3(0.0, -0.66, 0.3)
	camera.rotation = Vector3(deg_to_rad(-64.0), PI, deg_to_rad(8.0))

	var hud_node: Node = Global.hud()
	if hud_node != null:
		hud_node.atur_kelopak(1.0)

	Global.sfx("heartbeat", -4.0)
	await get_tree().create_timer(1.1).timeout

	# 1) Mata membuka grogi, berkedip dua kali
	await _jalankan_kelopak(hud_node, 1.0, 0.55, 1.5)
	await _jalankan_kelopak(hud_node, 0.55, 0.95, 0.45)
	Global.sfx("heartbeat", -6.0)
	await _jalankan_kelopak(hud_node, 0.95, 0.3, 0.8)
	await _jalankan_kelopak(hud_node, 0.3, 0.8, 0.35)
	await _jalankan_kelopak(hud_node, 0.8, 0.0, 0.9)

	# 2) Kepala terangkat dari meja
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(camera, "position", pos0 + Vector3(0.0, -0.3, 0.12), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(camera, "rotation:x", deg_to_rad(-22.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(camera, "rotation:z", 0.0, 1.6)
	await tw.finished

	# 3) Menoleh kiri lalu kanan (bingung)
	var tw2 := create_tween()
	tw2.tween_property(camera, "rotation:y", PI + 0.55, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw2.tween_interval(0.25)
	tw2.tween_property(camera, "rotation:y", PI - 0.5, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw2.tween_interval(0.2)
	tw2.tween_property(camera, "rotation:y", PI, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw2.finished

	# 4) Kursi terdorong ke belakang, Claire berdiri
	Global.sfx("geser", -10.0, 1.2)
	var tw3 := create_tween()
	tw3.set_parallel(true)
	if kursi != null:
		tw3.tween_property(kursi, "global_position", kursi.global_position - arah_maju * 0.7, 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw3.tween_property(camera, "position", pos0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw3.tween_property(camera, "rotation:x", 0.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw3.finished

	camera.position = pos0
	camera.rotation = Vector3(0.0, PI, 0.0)
	Global.cutscene = false


func _jalankan_kelopak(hud_node: Node, dari: float, ke: float, durasi: float) -> void:
	if hud_node != null:
		var tw: Tween = hud_node.tween_kelopak(dari, ke, durasi)
		await tw.finished
	else:
		await get_tree().create_timer(durasi).timeout


# ------------------------------------------------------------------
# Animasi model (idle bawaan FBX; walk/run dipakai bila tersedia)
# ------------------------------------------------------------------
func _siapkan_animasi() -> void:
	_peta_anim = {}

	# Idle: utamakan animasi bernama "idle"; jika tidak ada, pakai animasi bawaan model FBX.
	var idle: Array = _cari_animasi("idle", [model_anim, anim_player])
	if idle.is_empty() and model_anim != null:
		for nama in model_anim.get_animation_list():
			if String(nama) != "RESET":
				idle = [model_anim, String(nama)]
				break
	if not idle.is_empty():
		_peta_anim["idle"] = idle

	var jalan: Array = _cari_animasi("walk", [anim_player, model_anim])
	if not jalan.is_empty():
		_peta_anim["walk"] = jalan

	var lari: Array = _cari_animasi("run", [anim_player, model_anim])
	if not lari.is_empty():
		_peta_anim["run"] = lari

	# Pastikan semua animasi yang dipakai berulang (loop).
	for kunci in _peta_anim.keys():
		var pasangan: Array = _peta_anim[kunci]
		var pemutar: AnimationPlayer = pasangan[0]
		var anim: Animation = pemutar.get_animation(pasangan[1])
		if anim != null:
			anim.loop_mode = Animation.LOOP_LINEAR

	# Hentikan autoplay bawaan agar dua AnimationPlayer tidak berebut skeleton.
	for p in [anim_player, model_anim]:
		if p != null:
			p.stop()


func _cari_animasi(kata: String, pemutar: Array) -> Array:
	for p in pemutar:
		if p == null:
			continue
		for nama in p.get_animation_list():
			if String(nama).to_lower().contains(kata):
				return [p, String(nama)]
	return []


func _putar(state: String) -> void:
	if state == _state_anim:
		return
	_state_anim = state

	var target: Array = []
	if _peta_anim.has(state):
		target = _peta_anim[state]
	elif _peta_anim.has("idle"):
		target = _peta_anim["idle"]
	if target.is_empty():
		return

	var pemutar: AnimationPlayer = target[0]
	for p in [anim_player, model_anim]:
		if p != null and p != pemutar:
			p.stop()
	pemutar.play(target[1])
