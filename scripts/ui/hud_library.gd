
extends CanvasLayer

@onready var label_barang: Label = $PanelAtas/LabelBarang
@onready var label_objektif: Label = $PanelAtas/LabelObjektif
@onready var label_interaksi: Label = $PanelBawah/LabelInteraksi
@onready var panel_atas: Panel = $PanelAtas
@onready var panel_bawah: Panel = $PanelBawah

func _ready() -> void:
	UIStyle.apply_panel(panel_atas)
	UIStyle.apply_panel(panel_bawah)

	UIStyle.apply_label(label_barang, 22)
	UIStyle.apply_label(label_objektif, 16)
	UIStyle.apply_label(label_interaksi, 18)

	label_interaksi.text = ""

func perbarui_barang(jumlah: int, total: int) -> void:
	label_barang.text = "Barang ditemukan: %d/%d" % [jumlah, total]

func perbarui_objektif(teks: String) -> void:
	label_objektif.text = teks

func tampilkan_interaksi(teks: String) -> void:
	label_interaksi.text = teks
	panel_bawah.show()

func sembunyikan_interaksi() -> void:
	label_interaksi.text = ""
	panel_bawah.hide()
