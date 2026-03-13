extends CharacterBody3D


@export var GRAVITY = 30
@export  var MAX_SPEED = 10

@export var JUMP_SPEED = 9
@export var damage = 8

@export var active = false
@export var test_capture_mouse = false

@export var MOUSE_SENSITIVITY = 0.2

@onready var camera = $base_cam/rotation_helper/Camera3D
@onready var rotation_helper = $base_cam/rotation_helper
#@onready var gun = $base_cam/rotation_helper/Camera3D/gun


var camera_far = 1000


const MAX_SLOPE_ANGLE = 75

var vel = Vector3()
var current_hvel = Vector3(0,0,0)
var vertical_speed = 0
var dir = Vector3()




func _ready():
	add_to_group("player")
	add_to_group("agent")
	
	if test_capture_mouse :
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func _process(delta):

	if active :
		process_input(delta)
		process_movement(delta)
		#if Input.is_action_just_pressed("shoot") :
			#gun.fire()


func process_input(delta):

	dir = Vector3()
	var cam_xform = camera.get_global_transform()

	var input_movement_vector = Vector2()

	if Input.is_action_pressed("mv_fw"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("mv_bw"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("mv_lf"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("mv_rg"):
		input_movement_vector.x += 1
	

	input_movement_vector = input_movement_vector.normalized()

	dir += -cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x
	# ----------------------------------

	# ----------------------------------
	# Jumping
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			vertical_speed = JUMP_SPEED

		var bop_fac = .001
		var sintime = sin(Time.get_ticks_msec()*0.015)
		var boprot = .005
		

		if input_movement_vector.y != 0 or input_movement_vector.x != 0 :
#			$Rotation_Helper/Camera3D.rotation.z = bop_fac * sintime
			rotation_helper.transform.origin.y += -sintime * bop_fac
		

		if input_movement_vector.x == -1 :
			camera.rotation.z = lerp_angle(camera.rotation.z, boprot, .5*delta)
		elif input_movement_vector.x == 1 :
			camera.rotation.z = lerp_angle(camera.rotation.z, -boprot, .5*delta)

		else : 
			camera.rotation.z = lerp_angle(camera.rotation.z, 0, 8*delta)



func process_movement(delta):
	
	vel = Vector3.ZERO
	dir.y = 0

	vertical_speed -= delta * GRAVITY 
	vel.y = vertical_speed

	var target  = MAX_SPEED  *dir

	current_hvel = lerp(current_hvel, target, 10.0*delta )

	vel.x = current_hvel.x
	vel.z = current_hvel.z

	set_velocity(vel)

	move_and_slide()
	if is_on_floor() :
		vertical_speed = 0


func _input(event):
	if active :
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:

			rotation_helper.rotate_x(deg_to_rad(event.relative.y * MOUSE_SENSITIVITY* -1))
			self.rotate_y(deg_to_rad(event.relative.x * MOUSE_SENSITIVITY * -1))

			var camera_rot = rotation_helper.rotation_degrees
			camera_rot.x = clamp(camera_rot.x, -70, 70)
			rotation_helper.rotation_degrees = camera_rot


func activate() :
	active = true
	
func deactivate() :
	active = false
	
	
