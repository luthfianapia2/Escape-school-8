
extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var label_pesan: Label = $Panel/LabelPesan

func _ready() -> void:
	UIStyle.apply_panel(panel)
	UIStyle.apply_label(label_pesan, 20)
	hide()

func tampilkan_pesan(teks: String) -> void:
	label_pesan.text = teks
	show()

func sembunyikan_pesan() -> void:
	hide()
