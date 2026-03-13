extends Control

class_name vec_spinbox


signal value_changed

@onready var x = $x
@onready var y = $y
@onready var z = $z


var values = [0.0, 0.0, 0.0]

enum types{float, vec2, vec3}

@export var type : types
@export var param_key : String


func _ready() -> void:
	set_type(type)



func set_type(intype : int) :
	match intype : 
		0 :
			y.visible = false
			z.visible = false
		1 :
			y.visible = true
			z.visible = false
		2 :
			y.visible = true
			z.visible = true


func commit() :
	var resolved = null
	match type : 
		0 :
			resolved = float(values[0])
		1 :
			resolved = Vector2(values[0], values[1])
		2 :
			resolved = Vector3(values[0], values[1], values[2])
	
	emit_signal("value_changed", resolved)


func set_value(in_value) :
	if in_value is float :
		values[0] = in_value
	if in_value is Vector2 :
		values[0] = in_value.x
		values[1] = in_value.y
	if in_value is Vector3 :
		values[0] = in_value.x
		values[1] = in_value.y
		values[2] = in_value.z
	load_values_array()
	

func load_values_array() :
	x.value = values[0]
	y.value = values[1]
	z.value = values[2]


func _on_x_value_changed(value: float) -> void:
	values[0] = value
	commit()
	


func _on_y_value_changed(value: float) -> void:
	values[1] = value
	commit()


func _on_z_value_changed(value: float) -> void:
	values[2] = value
	commit()
