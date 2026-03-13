extends Node3D




@onready var compfx = $WorldEnvironment.compositor.compositor_effects[0] 
@onready var params = compfx.mp
@onready var player = $PlayerController
@onready var gui = $EffectGUI

enum modes  {game, gui}

var current_mode = modes.game



func _ready() -> void:
	gui.params = params
	gui.load()
	set_mode_game()
	#print(gui.params)
	
	
	

func _process(delta: float) -> void:
	
	
	
	if Input.is_action_just_pressed("ui_focus_next") :
	#if Input.is_action_just_pressed("ui_toggle") :
		toggle_mode()
	
	#var f = sin(Time.get_ticks_msec()*0.001)
	#params.op_base = 0.2 + f *0.8


func toggle_mode() :
	if current_mode == modes.game :
		set_mode_gui()
	else : 
		set_mode_game()
	
	
func set_mode_gui() :
	current_mode = modes.gui
	gui.visible = true
	gui.process_mode = Node.PROCESS_MODE_INHERIT
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player.deactivate()
	
	
func set_mode_game() :
	current_mode = modes.game
	gui.visible = false
	gui.process_mode = Node.PROCESS_MODE_DISABLED
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player.activate()


#func _on_effect_gui_update_params(key, value) -> void:
	#params[key] = value
