extends Node
## Taruh di node "QuestManager" (Node biasa) di map_komputer.tscn.
## HUD dibuat lewat kode, jadi tidak perlu bikin scene UI.

signal quest_completed   # dipancarkan setelah kuis selesai & pintu terbuka

enum Stage { FIND_QUESTION, PRINT_1, FIND_BOOK, PRINT_2, RETURN_QUESTION, OPEN_DRAWER, DONE }

@export var raycast_path: NodePath = ^"../CharacterBody3D/Camera3D/RayCast3D"
@export var print_duration := 5.0   # lama "mencetak"; suara printer dipotong (fade) di durasi ini
@export var sfx_printer: AudioStream
@export var sfx_book: AudioStream
@export var sfx_volume_db := 0.0

var _player_printer: AudioStreamPlayer
var _player_book: AudioStreamPlayer

var stage: int = Stage.FIND_QUESTION
var has_book := false
var busy := false

# --- misi terakhir: laci -> kuis -> pintu terbuka ---
@export var door_path: NodePath = ^"../furnitur/doorway"
@export var door_open_rotation_deg := 90.0     # sudut ayun pintu (negatif = arah sebaliknya)
@export var door_hinge_right := false          # true = engsel di sisi kanan daun pintu
# laci yang sudah ada di scene (punya interactable sendiri). Isi dengan node laci/StaticBody3D-nya.
@export var laci_path: NodePath
@export var wall_path: NodePath = ^"../bangunanDasar/tembok belakang"   # tembok yang dilubangi untuk pintu
var _kuis: Node
var _laci: Node

var _ray: RayCast3D
var _targets := {}           # target_id -> quest_target node
var _current: Node = null

var _objective_panel: PanelContainer
var _objective_label: Label
var _prompt_label: Label
var _banner_label: Label

func _ready() -> void:
	_ray = get_node_or_null(raycast_path)
	if _ray == null:
		push_warning("QuestManager: RayCast3D tidak ditemukan di " + str(raycast_path))
	_build_audio()
	_build_hud()
	await get_tree().process_frame   # tunggu semua quest_target siap
	for n in get_tree().get_nodes_in_group("quest_target"):
		_register(n)
	_laci = get_node_or_null(laci_path)
	_kuis = get_tree().current_scene.find_child("UI_kuis", true, false)
	if _kuis and _kuis.has_signal("kuis_selesai"):
		_kuis.kuis_selesai.connect(_on_kuis_selesai)
	else:
		push_warning("QuestManager: UI_kuis (dengan kuis.gd) tidak ditemukan")
	_apply_stage()
	_banner("Quest: cari tanda tanya (?) di pojok kanan atas ruangan", 5.0)

const SFX_DIR := "res://sfx"

# Cari file di res://sfx yang namanya mengandung kata kunci (tidak peduli spasi/underscore/huruf besar)
func _find_sfx(keyword: String) -> AudioStream:
	for f in DirAccess.get_files_at(SFX_DIR):
		var name := f.trim_suffix(".import").trim_suffix(".remap")
		if name.to_lower().contains(keyword) and name.get_extension().to_lower() in ["mp3", "ogg", "wav"]:
			var res = _load_audio(SFX_DIR + "/" + name)
			if res:
				return res
	push_warning("QuestManager: SFX dengan kata '" + keyword + "' tidak ditemukan di " + SFX_DIR)
	return null

# Coba load normal (hasil import). Kalau belum ter-import, baca file mentahnya.
func _load_audio(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			return res
	if not FileAccess.file_exists(path):
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		push_warning("QuestManager: file kosong/tidak terbaca: " + path)
		return null
	match path.get_extension().to_lower():
		"mp3":
			var mp3 := AudioStreamMP3.new()
			mp3.data = bytes
			return mp3
		"ogg":
			return AudioStreamOggVorbis.load_from_buffer(bytes)
	push_warning("QuestManager: format belum didukung untuk fallback: " + path)
	return null

func _load_sfx(current: AudioStream, keyword: String) -> AudioStream:
	return current if current else _find_sfx(keyword)

func _build_audio() -> void:
	sfx_printer = _load_sfx(sfx_printer, "printer")
	sfx_book = _load_sfx(sfx_book, "knuckle")
	_player_printer = AudioStreamPlayer.new()
	_player_printer.stream = sfx_printer
	_player_printer.volume_db = sfx_volume_db
	add_child(_player_printer)
	_player_book = AudioStreamPlayer.new()
	_player_book.stream = sfx_book
	_player_book.volume_db = sfx_volume_db
	add_child(_player_book)

func _register(n: Node) -> void:
	_targets[n.target_id] = n

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	# objective (kiri atas), awalnya disembunyikan
	_objective_panel = PanelContainer.new()
	_objective_panel.position = Vector2(20, 20)
	_objective_label = Label.new()
	_objective_label.add_theme_font_size_override("font_size", 20)
	_objective_panel.add_child(_objective_label)
	_objective_panel.visible = false
	layer.add_child(_objective_panel)

	# prompt "E" (tengah bawah)
	_prompt_label = Label.new()
	_prompt_label.add_theme_font_size_override("font_size", 24)
	_prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.offset_top = -140
	_prompt_label.offset_left = -200
	_prompt_label.offset_right = 200
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.visible = false
	layer.add_child(_prompt_label)

	# banner teks (tengah atas)
	_banner_label = Label.new()
	_banner_label.add_theme_font_size_override("font_size", 28)
	_banner_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner_label.offset_top = 60
	_banner_label.offset_left = -400
	_banner_label.offset_right = 400
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_label.modulate.a = 0.0
	layer.add_child(_banner_label)

func _banner(text: String, seconds: float = 3.0) -> void:
	_banner_label.text = text
	var tw := create_tween()
	tw.tween_property(_banner_label, "modulate:a", 1.0, 0.3)
	tw.tween_interval(seconds)
	tw.tween_property(_banner_label, "modulate:a", 0.0, 0.5)

func _apply_stage() -> void:
	var q = _targets.get("question")
	if q:
		# tanda tanya terlihat saat dicari & saat harus kembali
		q.set_marker_visible(stage == Stage.FIND_QUESTION or stage == Stage.RETURN_QUESTION)
	match stage:
		Stage.FIND_QUESTION:
			_objective_panel.visible = false
		Stage.PRINT_1:
			_set_objective("Print dokumen di printer (deretan kiri)")
		Stage.FIND_BOOK:
			_set_objective("Cari buku di rak kiri pojok bawah")
		Stage.PRINT_2:
			_set_objective("Print buku di printer")
		Stage.RETURN_QUESTION:
			_set_objective("Kembali ke tanda tanya (?)")
		Stage.OPEN_DRAWER:
			_set_objective("Buka laci")
		Stage.DONE:
			_set_objective("Pintu terbuka! Keluar lewat pintu")

func _set_objective(text: String) -> void:
	_objective_label.text = "Objective: " + text
	_objective_panel.visible = true

func _process(_delta: float) -> void:
	_current = null
	if _ray and _ray.is_colliding() and not busy:
		var c = _ray.get_collider()
		if c and "target_id" in c and c.target_id != "":
			_current = c
	if _current:
		_prompt_label.text = "[E] " + _current.prompt_text
		_prompt_label.visible = true
	else:
		_prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if not busy and stage == Stage.OPEN_DRAWER and _ray and _ray.is_colliding():
			var col = _ray.get_collider()
			if _laci and col and (col == _laci or _laci.is_ancestor_of(col)):
				_interact("drawer")
				return
			elif col and not ("target_id" in col):
				print("QuestManager: E ditekan pada ", col.get_path(), "  -> isi Laci Path dengan node ini kalau ini laci")
		if _current and not busy:
			_interact(_current.target_id)

func _interact(id: String) -> void:
	match id:
		"question":
			match stage:
				Stage.FIND_QUESTION:
					stage = Stage.PRINT_1
					_apply_stage()
					_banner("Ada tugas untukmu! Cetak dokumen di printer.")
				Stage.RETURN_QUESTION:
					stage = Stage.OPEN_DRAWER
					_apply_stage()
					_banner("Dokumen lengkap! Sekarang buka laci.")
				_:
					_banner("Selesaikan dulu tugasmu.")
		"printer":
			match stage:
				Stage.PRINT_1:
					await _print("Mencetak dokumen...")
					stage = Stage.FIND_BOOK
					_apply_stage()
					_banner("Dokumen tercetak. Sekarang cari bukunya.")
				Stage.PRINT_2:
					await _print("Mencetak isi buku...")
					stage = Stage.RETURN_QUESTION
					_apply_stage()
					_banner("Selesai dicetak. Kembali ke tanda tanya.")
				_:
					_banner("Belum ada yang perlu dicetak.")
		"drawer":
			if stage == Stage.OPEN_DRAWER and _kuis:
				busy = true
				_objective_panel.visible = false
				_kuis.buka()
			elif stage == Stage.DONE:
				_banner("Laci sudah terbuka.")
			else:
				_banner("Laci terkunci. Selesaikan tugas lain dulu.")
		"book":
			if stage == Stage.FIND_BOOK:
				has_book = true
				if _player_book.stream:
					_player_book.play()
				stage = Stage.PRINT_2
				_apply_stage()
				_banner("Buku didapat. Bawa ke printer.")
			elif stage == Stage.PRINT_2 or stage == Stage.RETURN_QUESTION:
				_banner("Buku sudah kamu ambil.")
			else:
				_banner("Belum waktunya mengambil buku.")

func _print(text: String) -> void:
	busy = true
	_prompt_label.text = text
	_prompt_label.visible = true
	if _player_printer.stream:
		_player_printer.volume_db = sfx_volume_db
		_player_printer.play()
	await get_tree().create_timer(print_duration).timeout
	if _player_printer.playing:
		var tw := create_tween()
		tw.tween_property(_player_printer, "volume_db", -40.0, 0.4)
		await tw.finished
		_player_printer.stop()
		_player_printer.volume_db = sfx_volume_db
	busy = false

func _on_kuis_selesai() -> void:
	busy = false
	stage = Stage.DONE
	_apply_stage()
	_open_door()
	_banner("Kuis selesai! Pintu sudah terbuka.", 4.0)
	quest_completed.emit()

func _open_door() -> void:
	var door := get_node_or_null(door_path)
	if door == null:
		push_warning("QuestManager: pintu tidak ditemukan di " + str(door_path))
		return
	for c in door.get_children():
		if c is CollisionShape3D:
			_cut_wall(c)                       # lubangi tembok di belakang pintu
			c.set_deferred("disabled", true)   # collision bingkai pintu dimatikan
	var leaf := door.get_node_or_null("door") as MeshInstance3D
	if leaf == null:
		push_warning("QuestManager: node 'door' tidak ditemukan di bawah " + str(door_path))
		return
	# engsel = tepi kiri/kanan daun pintu (dihitung dari ukuran mesh), lalu daun diayun mengitari engsel
	var box := leaf.get_aabb()
	var hx := box.end.x if door_hinge_right else box.position.x
	var hinge_local := Vector3(hx, 0.0, box.get_center().z)
	var start := leaf.transform
	var pivot := start * hinge_local
	var angle := deg_to_rad(door_open_rotation_deg)
	var tw := create_tween()
	tw.tween_method(_swing_door.bind(leaf, pivot, start, angle), 0.0, 1.0, 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _swing_door(t: float, leaf: Node3D, pivot: Vector3, start: Transform3D, angle: float) -> void:
	var rot := Transform3D(Basis(Vector3.UP, angle * t), Vector3.ZERO)
	leaf.transform = Transform3D(Basis(), pivot) * rot * Transform3D(Basis(), -pivot) * start

# Tembok belakang adalah CSGBox3D solid, jadi pintu hanya hiasan sampai tembok dilubangi.
func _cut_wall(cs: CollisionShape3D) -> void:
	if wall_path.is_empty():
		return   # Wall Path dikosongkan = tembok sudah punya celah sendiri, tidak perlu dilubangi
	var wall := get_node_or_null(wall_path)
	if wall == null or not (wall is CSGShape3D):
		push_warning("QuestManager: tembok tidak ditemukan di " + str(wall_path))
		return
	if not (cs.shape is BoxShape3D):
		return
	var sz: Vector3 = (cs.shape as BoxShape3D).size
	var sc := cs.global_transform.basis.get_scale()
	var cutter := CSGBox3D.new()
	cutter.operation = CSGShape3D.OPERATION_SUBTRACTION
	cutter.size = Vector3(sz.x * sc.x, sz.y * sc.y, 2.0)
	wall.add_child(cutter)
	cutter.global_position = cs.global_position
