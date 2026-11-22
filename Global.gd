extends Node
## Autoload "Global": progres permainan, perpindahan scene, suara, dan jembatan ke HUD.
##
## Aturan integrasi untuk semua anggota tim:
##  - Pindah scene SELALU lewat Global.go_to(path) atau Global.next_scene().
##  - Urutan scene diatur di konstanta ALUR di bawah. Jika nama file scene berubah,
##    cukup ubah di sini.
##  - Pesan ke pemain: Global.pesan(teks). Kartu pop-up: Global.kartu(judul, isi).
##    Tujuan: Global.tujuan(teks). Suara: Global.sfx("nama").

const SCENE_MAIN_MENU := "res://main_menu.tscn"
const SCENE_INTRO := "res://intro.tscn"
const SCENE_1 := "res://scenes/scene_1_library.tscn"
const SCENE_2 := "res://scenes/scene_2_lab.tscn"
const SCENE_3 := "res://scenes/scene_3_computer_lab.tscn"
const SCENE_ENDING := "res://ending.tscn"

const ALUR: Array[String] = [
	SCENE_MAIN_MENU,
	SCENE_INTRO,
	SCENE_1,
	SCENE_2,
	SCENE_3,
	SCENE_ENDING,
]

const HUD_SCRIPT := preload("res://scenes/hud.gd")

# Daftar efek suara (file WAV di folder audio/). Tambah di sini jika ada suara baru.
const SUARA := {
	"ambient_drone": "res://audio/ambient_drone.wav",
	"creak": "res://audio/creak.wav",
	"pickup": "res://audio/pickup.wav",
	"key": "res://audio/key.wav",
	"correct": "res://audio/correct.wav",
	"wrong": "res://audio/wrong.wav",
	"locked": "res://audio/locked.wav",
	"step": "res://audio/step.wav",
	"heartbeat": "res://audio/heartbeat.wav",
	"reveal": "res://audio/reveal.wav",
	"bell": "res://audio/bell.wav",
	"rustle": "res://audio/rustle.wav",
	"klik": "res://audio/klik.wav",
	"ketuk": "res://audio/ketuk.wav",
	"geser": "res://audio/geser.wav",
	"jatuh": "res://audio/jatuh.wav",
	"angin": "res://audio/angin.wav",
	"tetes": "res://audio/tetes.wav",
	"buzz": "res://audio/buzz.wav",
	"ratchet": "res://audio/ratchet.wav",
	"kartu": "res://audio/kartu.wav",
	"gemuruh": "res://audio/gemuruh.wav",
}

# --- Progres Scene 1 (nama lama dipertahankan agar kompatibel) ---
var has_door_code: bool = false   # kuis perpustakaan selesai
var has_key: bool = false         # kunci perpustakaan sudah diambil
var barang_ditemukan: int = 0     # jumlah buku yang ditemukan

# --- Progres umum (dipakai Scene 2, Scene 3, dst.) ---
var flags: Dictionary = {}
var waktu_mulai_msec: int = 0

# Jumlah UI penuh-layar yang sedang terbuka. Jika > 0, pemain tidak bergerak.
var ui_terbuka: int = 0
# true selama cutscene (mis. animasi bangun): pemain tidak bisa bergerak/melihat.
var cutscene: bool = false

var _hud_ref: Node = null
var _fade: ColorRect = null
var _sedang_pindah: bool = false
var _pemutar_sfx: Array[AudioStreamPlayer] = []
var _ambient: AudioStreamPlayer = null
var _cache_suara: Dictionary = {}
var _derit_generasi: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	waktu_mulai_msec = Time.get_ticks_msec()

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)

	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pemutar_sfx.append(p)

	_ambient = AudioStreamPlayer.new()
	add_child(_ambient)


# ------------------------------------------------------------------
# Progres
# ------------------------------------------------------------------
func reset_progress() -> void:
	has_door_code = false
	has_key = false
	barang_ditemukan = 0
	flags = {}
	ui_terbuka = 0
	cutscene = false
	waktu_mulai_msec = Time.get_ticks_msec()


func set_flag(kunci: String, nilai: Variant = true) -> void:
	flags[kunci] = nilai


func has_flag(kunci: String) -> bool:
	return bool(flags.get(kunci, false))


func waktu_bermain_detik() -> int:
	return int((Time.get_ticks_msec() - waktu_mulai_msec) / 1000.0)


func format_waktu(detik: int) -> String:
	var menit: int = floori(detik / 60.0)
	var sisa: int = detik % 60
	return "%02d:%02d" % [menit, sisa]


# ------------------------------------------------------------------
# Perpindahan scene
# ------------------------------------------------------------------
func go_to(path: String) -> void:
	if _sedang_pindah:
		return
	if not ResourceLoader.exists(path):
		push_error("Scene tidak ditemukan: %s" % path)
		pesan("Scene berikutnya belum tersedia: %s" % path, 5.0)
		return

	_sedang_pindah = true
	ui_terbuka = 0
	cutscene = false
	berhenti_ambient()

	var tween_keluar := create_tween()
	tween_keluar.tween_property(_fade, "color:a", 1.0, 0.4)
	await tween_keluar.finished

	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Gagal memuat scene %s (kode %d)" % [path, err])

	await get_tree().process_frame
	await get_tree().process_frame

	var tween_masuk := create_tween()
	tween_masuk.tween_property(_fade, "color:a", 0.0, 0.4)
	await tween_masuk.finished
	_sedang_pindah = false


## Pindah ke scene berikutnya sesuai urutan ALUR.
func next_scene() -> void:
	var sekarang: String = ""
	var cur: Node = get_tree().current_scene
	if cur != null:
		sekarang = cur.scene_file_path

	var idx: int = ALUR.find(sekarang)
	if idx == -1 or idx + 1 >= ALUR.size():
		go_to(SCENE_MAIN_MENU)
	else:
		go_to(ALUR[idx + 1])


# ------------------------------------------------------------------
# UI penuh-layar (kuis, input kode, dll.)
# ------------------------------------------------------------------
func buka_ui() -> void:
	ui_terbuka += 1
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	sembunyi_prompt()


func tutup_ui() -> void:
	ui_terbuka = maxi(0, ui_terbuka - 1)
	if ui_terbuka == 0 and get_tree().get_first_node_in_group("player") != null:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ------------------------------------------------------------------
# HUD (pesan, kartu, prompt interaksi, daftar tujuan, penghitung buku)
# ------------------------------------------------------------------
func pasang_hud(induk: Node) -> Node:
	var hud_baru: CanvasLayer = HUD_SCRIPT.new()
	induk.add_child(hud_baru)
	_hud_ref = hud_baru
	return hud_baru


func hud() -> Node:
	if is_instance_valid(_hud_ref):
		return _hud_ref
	_hud_ref = get_tree().get_first_node_in_group("hud")
	return _hud_ref


func pesan(teks: String, durasi: float = 3.0) -> void:
	var h := hud()
	if h != null:
		h.show_message(teks, durasi)


func kartu(judul: String, isi: String, durasi: float = 5.0) -> void:
	var h := hud()
	if h != null:
		sfx("kartu", -12.0)
		h.show_card(judul, isi, durasi)


func tujuan(teks: String) -> void:
	var h := hud()
	if h != null:
		h.set_objective(teks)


func set_buku(jumlah: int, total: int) -> void:
	var h := hud()
	if h != null:
		h.set_buku(jumlah, total)


func prompt(teks: String) -> void:
	var h := hud()
	if h != null:
		h.show_prompt(teks)


func sembunyi_prompt() -> void:
	var h := hud()
	if h != null:
		h.hide_prompt()


# ------------------------------------------------------------------
# Suara
# ------------------------------------------------------------------
func _ambil_suara(nama: String) -> AudioStream:
	if _cache_suara.has(nama):
		return _cache_suara[nama]
	var path: String = SUARA.get(nama, "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	var s: AudioStream = load(path)
	_cache_suara[nama] = s
	return s


func sfx(nama: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var s := _ambil_suara(nama)
	if s == null:
		return
	var pemutar: AudioStreamPlayer = _pemutar_sfx[0]
	for p in _pemutar_sfx:
		if not p.playing:
			pemutar = p
			break
	pemutar.stream = s
	pemutar.volume_db = volume_db
	pemutar.pitch_scale = pitch
	pemutar.play()


## Suara latar horor yang berulang mulus + derit samar acak (tanpa jumpscare).
func mulai_ambient(volume_db: float = -8.0) -> void:
	var s := _ambil_suara("ambient_drone")
	if s == null:
		return
	if s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.data.size() / 2.0)   # 16-bit mono: 2 byte per sampel
	_ambient.stream = s
	_ambient.volume_db = volume_db
	_ambient.play()
	_jadwalkan_derit()
	_napas_ambient(volume_db)


## Volume ambient naik-turun pelan (+-2 dB) supaya tidak terdengar seperti dengung monoton.
func _napas_ambient(dasar: float) -> void:
	var gen: int = _derit_generasi
	while gen == _derit_generasi:
		var tw := create_tween()
		tw.tween_property(_ambient, "volume_db", dasar + 2.0, 7.0).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_ambient, "volume_db", dasar - 2.0, 7.0).set_trans(Tween.TRANS_SINE)
		await tw.finished


func berhenti_ambient() -> void:
	_derit_generasi += 1
	if _ambient != null:
		_ambient.stop()


func _jadwalkan_derit() -> void:
	_derit_generasi += 1
	var generasi: int = _derit_generasi
	while generasi == _derit_generasi:
		await get_tree().create_timer(randf_range(12.0, 30.0)).timeout
		if generasi != _derit_generasi:
			break
		# [nama, volume_min, volume_maks] - kejadian suara acak di latar (tanpa jumpscare)
		var pool: Array = [
			["ketuk", -22.0, -15.0], ["rustle", -26.0, -20.0], ["bell", -30.0, -24.0],
			["angin", -24.0, -17.0], ["tetes", -26.0, -19.0], ["tetes", -28.0, -21.0],
		]
		var p: Array = pool.pick_random()
		sfx(p[0], randf_range(p[1], p[2]), randf_range(0.85, 1.15))
