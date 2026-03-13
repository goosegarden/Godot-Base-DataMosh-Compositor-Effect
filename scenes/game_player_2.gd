extends CharacterBody3D

signal notify_hurt

@export var godmode = false

@export var GRAVITY = 30
@export  var MAX_SPEED = 14

@export var JUMP_SPEED = 10
@export var damage = 8


@export var active = false
@export var test_capture_mouse = false

@export var MOUSE_SENSITIVITY = 0.2

@onready var camera = $base_cam/rotation_helper/Camera3D
@onready var rotation_helper = $base_cam/rotation_helper

@onready var gun_raycast = $base_cam/rotation_helper/gun_point/RayCast3D
@onready var bullet_pos = $base_cam/rotation_helper/gun_point/bullet_pos
var bullet = preload("res://scenes/bullet_fx.tscn")
#var bullet = preload("res://subscenes/props/bullet.tscn")

@onready var anp = $AnimationPlayer
@onready var gun_sound = $gun_fx
@onready var collected_fx = $collected


var camera_far = 1000

@export var rh_base_y = 4.0
const MAX_SLOPE_ANGLE = 75

var vel = Vector3()
var current_hvel = Vector3(0,0,0)
var vertical_speed = 0
var dir = Vector3()


func _ready():
	add_to_group("player")
	#if test_capture_mouse :
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
func _physics_process(delta: float) -> void:
	pass
			
	

func _process(delta):

	if active :
		process_input(delta)
		process_movement(delta)
		if Input.is_action_just_pressed("shoot") :
			shoot()
		#Input.get_last_mouse_velocity()


func activate() :
	active = true
	camera.make_current()
	

func deactivate() :
	active = false
	velocity = Vector3.ZERO
	


func process_input(delta):
	
	
	#var view_h = Input.get_action_strength("view_right") - Input.get_action_strength("view_left")
	#var view_v = Input.get_action_strength("view_up") - Input.get_action_strength("view_down")
	#
	#self.rotate_y(deg_to_rad(view_h * 1.0 * -1))
	#rotation_helper.rotate_x(clamp(deg_to_rad(view_v * 0.6), -70 ,70))

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

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			vertical_speed = JUMP_SPEED

		var bop_fac = .005
		var sintime = sin(Time.get_ticks_msec()*0.01)
		var boprot = .04
		

		if input_movement_vector.y != 0 or input_movement_vector.x != 0 :
#			$Rotation_Helper/Camera3D.rotation.z = bop_fac * sintime
			rotation_helper.transform.origin.y += -sintime * bop_fac
		else : 
			rotation_helper.transform.origin.y = rh_base_y

		if input_movement_vector.x == -1 :
			camera.rotation.z = lerp_angle(camera.rotation.z, boprot, 8.0*delta)
		elif input_movement_vector.x == 1 :
			camera.rotation.z = lerp_angle(camera.rotation.z, -boprot, 8.0*delta)

		else : 
			camera.rotation.z = lerp_angle(camera.rotation.z, 0, 8*delta)



func shoot() :
	
	anp.play("fire_gun")

	var b = bullet.instantiate()
	get_viewport().add_child(b)
	b.fire(bullet_pos.global_transform)
	#get_parent().give_bullet(b)




func process_movement(delta):
	vel = Vector3.ZERO
	dir.y = 0

	vertical_speed -= delta * GRAVITY 
	vel.y = vertical_speed

	var target  = MAX_SPEED  *dir

	current_hvel = lerp(current_hvel, target, 8.0*delta )

	vel.x = current_hvel.x
	vel.z = current_hvel.z

	set_velocity(vel)
	set_up_direction(Vector3(0, 1, 0))
	set_floor_stop_on_slope_enabled(true)
	set_max_slides(4)
	set_floor_max_angle(deg_to_rad(MAX_SLOPE_ANGLE))
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
