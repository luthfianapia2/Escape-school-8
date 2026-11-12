extends Label

@export var title_font: FontFile
@export_file("*.tscn") var next_scene_path: String

@onready var next_button: TextureButton = $next 
@onready var hand_print: TextureRect = $tangan # Ambil referensi node cetakan tangan

var story_lines: Array[String] = [
	"Suasana sekolah terasa sangat sunyi...",
	"Tidak ada guru, tidak ada satu pun murid lain.",
	"Pintu gerbang terkunci rapat dari luar.",
	"Ada sesuatu yang mengawasi dari balik lorong gelap...",
	"Aku harus segera mencari jalan keluar."
]

var current_line_index: int = 0
var total_elapsed_time: float = 0.0

const MAIN_DURATION: float = 16.5
const TITLE_DURATION: float = 5.0
const TOTAL_DURATION: float = MAIN_DURATION + TITLE_DURATION

func _ready() -> void:
	text = ""
	add_theme_font_size_override("font_size", 65)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Sembunyikan tombol dan cetakan tangan di awal game
	if next_button:
		next_button.visible = false
		next_button.pressed.connect(_on_next_button_pressed)
		
	if hand_print:
		hand_print.visible = false
	
	if story_lines.size() > 0:
		play_typewriter_effect(story_lines[0], MAIN_DURATION / story_lines.size())

func _process(delta: float) -> void:
	total_elapsed_time += delta
	
	if total_elapsed_time <= MAIN_DURATION:
		var interval = MAIN_DURATION / float(story_lines.size())
		var target_index = int(total_elapsed_time / interval)
		
		if target_index != current_line_index and target_index < story_lines.size():
			current_line_index = target_index
			play_typewriter_effect(story_lines[current_line_index], interval * 0.8)
				
	elif total_elapsed_time > MAIN_DURATION and total_elapsed_time <= TOTAL_DURATION:
		if text != "ESCAPE SCHOOL":
			if title_font:
				add_theme_font_override("font", title_font)
			add_theme_font_size_override("font_size", 200) 
			
			play_typewriter_effect("ESCAPE SCHOOL", TITLE_DURATION * 0.8)
			
	# Pas durasi 21.5 detik selesai, munculkan tombol next DAN cetakan tangan merah!
	if total_elapsed_time >= TOTAL_DURATION:
		if next_button and not next_button.visible:
			next_button.visible = true
			
		if hand_print and not hand_print.visible:
			hand_print.visible = true

func play_typewriter_effect(new_text: String, duration: float) -> void:
	text = new_text
	visible_characters = 0
	var tween = create_tween()
	tween.tween_property(self, "visible_characters", new_text.length(), duration)

func _on_next_button_pressed() -> void:
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
	else:
		print("Pilih file scene tujuan di Inspector 'Next Scene Path'!")
