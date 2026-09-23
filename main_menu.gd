extends Control

# Path ke scene intro game kamu
@export var game_scene_path: String = "res://intro.tscn"

# Referensi otomatis ke node-node UI
@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options_panel: Panel = $OptionsPanel
@onready var credits_panel: Panel = $CreditsPanel
@onready var volume_slider: HSlider = $OptionsPanel/VolumeSlider

func _ready() -> void:
	# Tampilkan menu utama dan sembunyikan panel saat game baru buka
	main_buttons.show()
	options_panel.hide()
	credits_panel.hide()
	
	# Set nilai slider awal mengikuti volume bawaan
	if volume_slider:
		volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
		# Menghubungkan slider ke fungsi volume secara otomatis (opsional kalau belum terhubung di Signals)
		if not volume_slider.value_changed.is_connected(_on_volume_slider_value_changed):
			volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	
	# Focus awal ke tombol Start
	$MainButtons/StartButton.grab_focus()

# --- TOMBOL UTAMA ---

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(game_scene_path)

func _on_options_button_pressed() -> void:
	main_buttons.hide()
	options_panel.show()

func _on_credits_button_pressed() -> void:
	main_buttons.hide()
	credits_panel.show()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

# --- OPTION PANEL (SLIDER VOLUME) ---

func _on_volume_slider_value_changed(value: float) -> void:
	# Mengubah volume master audio (0 = mute, 1 = max)
	if value == 0:
		AudioServer.set_bus_volume_db(0, -80)
	else:
		AudioServer.set_bus_volume_db(0, linear_to_db(value))

# --- TOMBOL BACK ---

func _on_back_from_options_pressed() -> void:
	options_panel.hide()
	main_buttons.show()
	$MainButtons/OptionsButton.grab_focus()

func _on_back_from_credits_pressed() -> void:
	credits_panel.hide()
	main_buttons.show()
	$MainButtons/CreditsButton.grab_focus()
