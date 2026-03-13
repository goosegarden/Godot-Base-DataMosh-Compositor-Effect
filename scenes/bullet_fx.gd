extends Node3D

signal bullet_ends

var alive = false
var speed = 30.0
var dir : Vector3
var timer = 0.0
var lifetime = 2.0

@onready var light = $OmniLight3D2
@onready var anp = $AnimationPlayer
@onready var smoke = $smoke
@onready var sparks = $sparkles
@onready var sp = $AudioStreamPlayer3D

var hit = false

func _ready() -> void:
	pass
	
	
func _process(delta: float) -> void:
	if alive : 
		global_position += dir * speed * delta
		timer += delta
		if timer > lifetime : 
			die()


func fire(from_transform) :
	global_transform = from_transform
	dir = (-global_transform.basis.z).normalized()
	alive = true
	

func die() :
	emit_signal("bullet_ends", self)
	queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:
	
	if hit == false : 
		
		if body is RigidBody3D :
			body.apply_impulse(dir * speed * 2.0, body.global_position - global_position)
		
		hit = true
		dir = -dir
		var spm = smoke.process_material
		spm.direction = dir
		var spam = sparks.process_material
		spam.direction = dir
		anp.current_animation = "explode"
		alive = false
		sp.play()
		anp.seek(0)
		anp.play("explode")
		if body.is_in_group("player") :
			print(" bullet meets player")
		
			#return
		#die()


#func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	#if anim_name == "explode" :
		#print(self," finished exploding, bye now")
		#queue_free()


#func _on_smoke_finished() -> void:
	#die()
