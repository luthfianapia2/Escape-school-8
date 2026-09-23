extends CharacterBody3D

const SPEED = 5.0
const MOUSE_SENSITIVITY = 0.003

@onready var camera_3d: Camera3D = $Camera3D
@onready var ray_cast_3d: RayCast3D = $Camera3D/RayCast3D

func _ready() -> void:
	# Mengunci kursor mouse ke dalam jendela game
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	# Gerakan Mouse untuk Rotasi Kamera
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_3d.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	# Tekan ESC untuk memunculkan/menyembunyikan kursor
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Interaksi (Tombol E atau Aksi 'interact')
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		if ray_cast_3d and ray_cast_3d.is_colliding():
			var collider = ray_cast_3d.get_collider()
			if collider:
				_proses_interaksi(collider)

func _physics_process(delta: float) -> void:
	# Gravitasi
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Ambil input WASD / Panah
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Jika Input Map kustom belum diset, gunakan Arrow/WASD bawaan
	if input_dir == Vector2.ZERO:
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _proses_interaksi(collider: Object) -> void:
	var target = collider
	if not target.has_method("interaksi") and collider.get_parent():
		target = collider.get_parent()
	
	if target and target.is_inside_tree() and target.has_method("interaksi"):
		var ui_canvas = get_tree().get_first_node_in_group("ui_canvas")
		target.interaksi(ui_canvas)
