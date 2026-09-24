extends CharacterBody3D

@export var speed := 5.0
@export var mouse_sensitivity := 0.003

@onready var camera = $Camera3D

var camera_x := 0.0


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

		camera_x -= event.relative.y * mouse_sensitivity
		camera_x = clamp(camera_x, -1.4, 1.4)

		camera.rotation.x = camera_x

	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _physics_process(_delta):
	var input_dir = Vector2.ZERO

	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1

	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1

	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1

	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	var direction = transform.basis * Vector3(
		input_dir.x,
		0,
		input_dir.y
	)

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()
