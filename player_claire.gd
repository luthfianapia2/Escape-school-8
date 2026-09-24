extends CharacterBody3D

const WALK_SPEED = 5.0
const RUN_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

var current_speed = WALK_SPEED
var initial_y_rotation = 0.0

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if camera:
		camera.rotation.y = PI
		camera.rotation.x = 0
		camera.rotation.z = 0
	initial_y_rotation = rotation.y

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		
		if camera:
			camera.rotate_x(event.relative.y * MOUSE_SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_key_pressed(KEY_SHIFT):
		current_speed = RUN_SPEED
	else:
		current_speed = WALK_SPEED

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	var direction = (transform.basis * Vector3(-input_dir.x, 0, -input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if anim_player:
			if current_speed == RUN_SPEED and anim_player.has_animation("Run"):
				anim_player.play("Run")
			elif anim_player.has_animation("Walk"):
				anim_player.play("Walk")
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		
		if anim_player and anim_player.has_animation("Idle"):
			anim_player.play("Idle")

	move_and_slide()
