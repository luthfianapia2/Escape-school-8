extends Node

var buku_ditemukan := 0
var rak_ditemukan := 0
var botol_ditemukan := 0

var misi_selesai := false


func _ready():
	print("MISSION MANAGER AKTIF")


func update_ui():
	var label = get_tree().current_scene.find_child("MissionLabel", true, false)

	if label:
		label.text = "MISI\n\nBuku: %d/2\nRak: %d/2\nBotol: %d/3" % [
			buku_ditemukan,
			rak_ditemukan,
			botol_ditemukan
		]


func tambah_buku():
	buku_ditemukan += 1

	print("=== BUKU DITEMUKAN ===")
	print("BUKU: ", buku_ditemukan, "/2")

	update_ui()
	cek_misi()


func tambah_rak():
	rak_ditemukan += 1

	print("=== RAK DITEMUKAN ===")
	print("RAK: ", rak_ditemukan, "/2")

	update_ui()
	cek_misi()


func tambah_botol():
	botol_ditemukan += 1

	print("=== BOTOL DITEMUKAN ===")
	print("BOTOL: ", botol_ditemukan, "/3")

	update_ui()
	cek_misi()


func cek_misi():
	if misi_selesai:
		return

	if buku_ditemukan >= 2 and rak_ditemukan >= 2 and botol_ditemukan >= 3:

		misi_selesai = true

		print("================================")
		print("SEMUA MISI SELESAI!")
		print("================================")

		var mission_ui = get_tree().current_scene.get_node_or_null("MissionUI")
		var label = get_tree().current_scene.find_child("MissionLabel", true, false)

		# Tampilkan hasil misi
		if mission_ui:
			mission_ui.visible = true

		if label:
			label.visible = true
			label.text = "MISI SELESAI!\n\nBuku: 2/2\nRak: 2/2\nBotol: 3/3"

		# Tunggu 3 detik
		await get_tree().create_timer(3.0).timeout

		# Munculkan tanda tanya di buku
		aktifkan_buku()

		# Tampilkan arahan
		if label:
			label.visible = true
			label.text = "MISI BERIKUTNYA\n\nCari buku bertanda ?\n\nTekan E untuk membuka buku."

		print("ARAHAN KE BUKU MUNCUL!")

		# Arahan tampil selama 5 detik
		await get_tree().create_timer(5.0).timeout

		# Hilangkan arahan
		if mission_ui:
			mission_ui.visible = false

		print("ARAHAN KE BUKU HILANG!")


func aktifkan_buku():
	var book = get_tree().current_scene.get_node_or_null("Book")

	if book:
		var question_mark = book.get_node_or_null("QuestionMark")

		if question_mark:
			question_mark.visible = true
			print("TANDA TANYA BUKU MUNCUL!")
		else:
			print("ERROR: QuestionMark TIDAK DITEMUKAN!")
	else:
		print("ERROR: Book TIDAK DITEMUKAN!")
