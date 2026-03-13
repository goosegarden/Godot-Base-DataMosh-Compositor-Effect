extends Control

#signal update_params

var params

var presets_path ="res://compositor/dmosh/presets/"
@onready var presets_list = $ColorRect/presets_list

@onready var wave_value_lb = $wave_cr/wave_value_lb

@onready var op_fac_vsb = $op_fac_lb/op_fac_vsb
#var last_op_fac

@onready var match_params = {
	
	"vel_scale_fac" : $vel_scale_fac_lb/vsb,
	"col_lum_bounds" : $col_lum_bounds_lb/vsb,
	
	"col_depth_bounds" : $col_depth_bounds_lb/col_depth_bounds_vsb,

	"vel_lum_bounds" : $vel_lum_bounds_lb2/vsb,
		
	"vel_depth_bounds" : $vel_depth_bounds_lb2/vsb,
	
	"vel_clamp" : 0.9,
	"vel_pix_size" : $vel_pixelate/vsb,

	"col_depth_smoothfac" : $col_depth_smoothfac_lb/col_depth_bounds_vsb,
	"vel_depth_smoothfac" : $vel_depth_smoothfac_lb2/vsb,
	
	"col_depth_fac" : $col_depth_fac_lb/vsb,
	"vel_depth_fac" : $vel_depth_fac_lb2/vsb,

	
	"col_lum_fac" : $col_lum_fac_lb/vsb,
	"vel_lum_fac" : $vel_lum_fac_lb2/vsb,

	"ripples_on" : $ripples_on/vsb,
	"ripples_intensity" : $ripples_intensty/vsb,
	"ripples_freq" : $ripples_frequency/vsb,
	"ripples_numwaves" : $ripples_numwaves/vsb,

	
	"op_op" : $color_op_lb/op_op_ob ,
	"op_p1" : $color_op_lb2/op_p1_ob,
	"op_p2" : $color_op_lb3/op_p2_ob,
	"op_base" : $op_base_lb/op_base_vsb,
	"op_fac" : $op_fac_lb/op_fac_vsb,

	"vel_op_op" : $vel_op_lb4/vel_op_op_ob,
	"vel_op_p1" : $vel_op_lb5/vel_op_p1_ob,
	"vel_op_p2" : $vel_op_lb6/vel_op_p2_ob,
	"vel_op_base" : $vel_op_base_lb2/op_base_vsb,
	"vel_op_fac" :  $vel_op_fac_lb2/op_fac_vsb,
	

	"sobel_on" : $sobel_on/vsb,
	"sobel_width" : 1.0,
	"sobel_fac" : $sobel_fac/vsb,

	"wind_on" : $wind_on/vsb,
	"wind_fac" : $wind_fac/vsb,
	"wind_noise" : 1.0,
	"wind_noise_scale" : 2.0,
	"wind_noise_step" : 8.0,
	"wind_noise_smooth" : 0.1,
	"vortex" : $vortex/vsb,
	
	
	"master_fade" : 1.0,
}



var current_wave = {
	"on" : false,
	"base" : 0.1,
	"freq" : 1.0,
	"amp" : 0.2,
	"last_op_fac" : 0.4,
}


@onready var match_wave = {
	"on" : $wave_cr/wave_on_cb ,
	"base" : $wave_cr/Label3/wave_base_sp ,
	"freq" : $wave_cr/Label/wave_freq_sb,
	"amp" : $wave_cr/Label2/wave_amp_sb,
}




func load() -> void:
	var vsbs = find_children("*", "vec_spinbox")
	for vsb in vsbs :
		#vsb.param_key
		vsb.set_value(params[vsb.param_key])
		vsb.value_changed.connect(_on_params_changed.bind(vsb))
	var obs = find_children("*", "OptionButton")
	#print(obs)
	for ob in obs : 
		var k = ob.name.rstrip("_ob")
		ob.selected = int(params[k])
		
	load_presets_list()
	update_wave_gui()
		
		

func _process(delta: float) -> void:
	if current_wave.on == true : 
		var val = current_wave.base + (0.5 + sin(Time.get_ticks_msec()* PI * 2.0 * 0.001 * current_wave.freq) *0.5) * current_wave.amp
		#val += current_wave.last_op_fac
		#params.op_fac = val
		op_fac_vsb.set_value(val + current_wave.last_op_fac)
		wave_value_lb.text = str(snapped(val,0.0001) )


func _on_params_changed(value , vsb) :
	params[vsb.param_key] = value


func update_wave_gui() :
	#$wave_cr/wave_on_cb.button_pressed
	match_wave.on.set_pressed_no_signal(bool(current_wave.on))
	#match_wave.on.button_pressed = bool(current_wave.on)
	match_wave.base.value = current_wave.base
	match_wave.amp.value = current_wave.amp
	match_wave.freq.value = current_wave.freq
			

func load_presets_list() :
	presets_list.clear()
	var dir = DirAccess.open(presets_path)
	var modif_array = []
	var mod_dict = {}
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				pass
			else:
				if file_name.get_extension() == "res" :
					var fname = file_name.get_basename()
					presets_list.add_item(fname)
					
					var modif = FileAccess.get_modified_time(presets_path+file_name)
					modif *= 10
					while modif_array.has(modif) :
						modif += 1
					modif_array.append(modif)
					mod_dict[modif] = fname
			file_name = dir.get_next()
	
	else:
		print("An error occurred when trying to access the path : ",presets_path)



func load_preset(preset_name) :
	var npr = ResourceLoader.load(presets_path+preset_name+".res")
	var new_params = npr.mp.duplicate(true)
	current_wave = npr.wave.duplicate(true)
	update_wave_gui()

	for k in new_params :
		params[k] = new_params[k]
		var gui_p = match_params[k]
		if gui_p is vec_spinbox :
			gui_p.set_value(params[k])
		elif gui_p is OptionButton :
			gui_p.selected = int(params[k])
	$save_preset_bt/LineEdit.text = npr.resource_name
	



func save_preset() :
	var preset_name = $save_preset_bt/LineEdit.text
	var dra = DirAccess.open(presets_path)
	if preset_name == "" or dra.file_exists(presets_path+preset_name+".res") :
		preset_name += str(Time.get_date_string_from_system())
	var npr = effect_preset.new()
	#print(npr)
	
	npr.mp = params.duplicate(true)
	npr.wave = current_wave.duplicate(true)
	#print(npr.mp)
	npr.resource_name = preset_name
	npr.resource_path = presets_path+preset_name+".res"
	
	ResourceSaver.save(npr)
	load_presets_list()
	



func _on_color_op_ob_item_selected(index: int) -> void:
	params["op_op"] = float(index)


func _on_color_op_p_1_ob_item_selected(index: int) -> void:
	params["op_p1"] = float(index)


func _on_color_op_p_2_ob_item_selected(index: int) -> void:
	params["op_p2"] = float(index)


func _on_save_preset_bt_pressed() -> void:
	save_preset()
	#var preset_name = $save_preset_bt/LineEdit.text
	##print("saving preset : ",preset_name)
	#var npr = effect_preset.new()
	##print(npr)
	#
	#npr.mp = params.duplicate(true)
	##print(npr.mp)
	#npr.resource_name = preset_name
	#npr.resource_path = presets_path+preset_name+".res"
	#
	#ResourceSaver.save(npr)
	#load_presets_list()
	


func _on_vel_op_op_ob_item_selected(index: int) -> void:
	params["vel_op_op"] = float(index)


func _on_vel_op_p_1_ob_item_selected(index: int) -> void:
	params["vel_op_p1"] = float(index)


func _on_vel_op_p_2_ob_item_selected(index: int) -> void:
	params["vel_op_p2"] = float(index)


func _on_presets_list_item_activated(index: int) -> void:
	var item_name = presets_list.get_item_text(index)
	load_preset(item_name)


func _on_wave_on_cb_toggled(toggled_on: bool) -> void:
	current_wave.on = toggled_on
	if not current_wave.on :
		wave_value_lb.text = str(0.0)
		params.op_fac = current_wave.last_op_fac
		op_fac_vsb.set_value(current_wave.last_op_fac)
	else : 
		current_wave["last_op_fac"] = params.op_fac


func _on_wave_freq_sb_value_changed(value: float) -> void:
	current_wave.freq = value


func _on_wave_amp_sb_value_changed(value: float) -> void:
	current_wave.amp = value

func _on_wave_base_sp_value_changed(value: float) -> void:
	current_wave.base = value
