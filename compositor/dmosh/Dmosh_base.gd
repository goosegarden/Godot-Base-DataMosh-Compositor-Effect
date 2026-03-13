@tool
extends CompositorEffect
class_name DtMoshBase


#var cu2 = preload("res://libs/compUtils3.gd").new()


var scene_uniform_data = null

var blue_noise_tex_u

var prm_buffer 
var prm_uniform

var misc_buffer
var misc_uniform



var matrices_buffer
var prev_matrices_buffer
var matrices_uniform
var prev_matrices_uniform

var color_uniform : RDUniform = RDUniform.new()
var colsamp_uniform : RDUniform = RDUniform.new()


var depth_uniform : RDUniform = RDUniform.new()

var trail_color_uniform : RDUniform = RDUniform.new()
var trail_colsamp_uniform : RDUniform = RDUniform.new()
var velocity_uniform : RDUniform = RDUniform.new()
var velsamp_uniform : RDUniform = RDUniform.new()

var normal_uniform : RDUniform = RDUniform.new()
var norsamp_uniform : RDUniform = RDUniform.new()


var color_uniform_set: RID
var depth_uniform_set: RID
var trail_color_uniform_set: RID
var velocity_set: RID
var misc_uniform_set: RID




	

var rd : RenderingDevice

var shader : RID
var out_pipeline : RID


var nearest_sampler : RID
var nearest_sampler2 : RID
var nearest_sampler3 : RID


var mutex : Mutex = Mutex.new()
var shader_is_dirty : bool = true

var cp_tex : RID
var tex_init = false
var delay_timer = 0.0
var trail_idx = 0.0
var last_tick = 0.0
var delta = 0.0
var frame = 0

var prev_mat_buffer = null

var do_clear_on = false

@export var mp = {

	"vel_scale_fac" : Vector3(0.75,0.75,0.75),
	"col_lum_bounds" : Vector2(0.3, 0.6),
	
	"col_depth_bounds" : Vector2(0.0, 4.0),

	"vel_lum_bounds" : Vector2(0.3, 0.6),
		
	"vel_depth_bounds" : Vector2(0.0, 4.0),
	
	"vel_clamp" : 0.9,
	"vel_pix_size" : 4.0,

	"col_depth_smoothfac" : 0.08, #-1.0 -> 1.0 ?
	"vel_depth_smoothfac" : 0.08, #-1.0 -> 1.0 ?
	
	"col_depth_fac" : 1.0, #-1.0 -> 1.0 ?
	"vel_depth_fac" : 1.0, #-1.0 -> 1.0 ?

	
	"col_lum_fac" : 1.0,
	"vel_lum_fac" : 1.0,

	"ripples_on" : 0.0,
	"ripples_intensity" : 0.0,
	"ripples_freq" : 5.0,
	"ripples_numwaves" : 5.0,

	
	"op_op" : 0.0,
	"op_p1" : 0.0,
	"op_p2" : 0.0,
	"op_base" : 0.9,
	"op_fac" : 1.0,

	"vel_op_op" : 0.0,
	"vel_op_p1" : 0.0,
	"vel_op_p2" : 0.0,
	"vel_op_base" : 0.1,
	"vel_op_fac" : 0.4,
	

	"sobel_on" : 0.0,
	"sobel_width" : 1.0,
	"sobel_fac" : 1.0,

	"wind_on" : 0.0,
	"wind_fac" : 0.1,
	"wind_noise" : 1.0,
	"wind_noise_scale" : 2.0,
	"wind_noise_step" : 8.0,
	"wind_noise_smooth" : 0.1,
	"vortex" : 0.0,
	
	
	"master_fade" : 1.0,
	
}




@export var reload : bool : 
	set(value):
		print("call reload")
		_initialize_compute()



func _init() -> void:

	# ~ default_mp = mp.duplicate(true)

	needs_motion_vectors = true
	needs_normal_roughness = true
	effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	RenderingServer.call_on_render_thread(_initialize_compute)
	
	
	
	var sampler_state = RDSamplerState.new()
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	nearest_sampler = rd.sampler_create(sampler_state)
	
	
	var sampler_state2 = RDSamplerState.new()
	sampler_state2.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_state2.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_state2.border_color = RenderingDevice.SAMPLER_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK

	sampler_state2.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	sampler_state2.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	nearest_sampler2 = rd.sampler_create(sampler_state2)
	
	
	var sampler_state3 = RDSamplerState.new()
	sampler_state3.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_state3.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_state3.border_color = RenderingDevice.SAMPLER_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK

	sampler_state3.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	sampler_state3.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	nearest_sampler3 = rd.sampler_create(sampler_state3)
	
	
	# ~ var bnt = cu2.loadTexture("res://assets/graphics/LDR_RGBA_0.png")
	var bnt = loadTexture("res://compositor/dmosh/LDR_RGBA_0.png")
	#var bnt = loadTexture("res://assets/graphics/LDR_RGBA_0.png")
	blue_noise_tex_u = SamplerUniform.new(rd, bnt, 2)
	
	var fba = PackedFloat32Array()
	fba.resize(88)
	# ~ fba.fill(0.0)
	var fpba = fba.to_byte_array()
	prm_buffer =  rd.uniform_buffer_create(fpba.size(), fpba)
	prm_uniform = RDUniform.new()
	prm_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	prm_uniform.binding = 2
	prm_uniform.add_id(prm_buffer)
	
	
	var mf = PackedFloat32Array()
	mf.resize(8)
	misc_buffer =  rd.uniform_buffer_create(32, mf.to_byte_array())
	
	misc_uniform  = RDUniform.new()
	misc_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	misc_uniform.binding = 0
	misc_uniform.add_id(misc_buffer)
	
	var pb = PackedByteArray()
	pb.resize(256)
	matrices_buffer =  rd.uniform_buffer_create(256, pb)
	prev_matrices_buffer =  rd.uniform_buffer_create(256, pb)
	
	matrices_uniform = RDUniform.new()
	matrices_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	matrices_uniform.binding = 1
	matrices_uniform.add_id(matrices_buffer)
	
	prev_matrices_uniform = RDUniform.new()
	prev_matrices_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	prev_matrices_uniform.binding = 3
	prev_matrices_uniform.add_id(prev_matrices_buffer)
	
	
	

	#var color_uniform : RDUniform = RDUniform.new()
	color_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	color_uniform.binding = 0
	
	#var colsamp_uniform : RDUniform = RDUniform.new()
	colsamp_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	colsamp_uniform.binding = 1
	
	
	depth_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	depth_uniform.binding = 0
	
	trail_color_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	trail_color_uniform.binding = 0
	
	trail_colsamp_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	trail_colsamp_uniform.binding = 1
	
	velocity_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	velocity_uniform.binding = 0
	
	velsamp_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	velsamp_uniform.binding = 2
	
	normal_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	normal_uniform.binding = 1

	norsamp_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	norsamp_uniform.binding = 3



func _initialize_compute()->void:
	rd = RenderingServer.get_rendering_device()
	
	if !rd:
		return

	var shader_file: RDShaderFile = load("res://compositor/dmosh/Dmosh_base.glsl")

	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	out_pipeline = rd.compute_pipeline_create(shader)
	



func get_params_uniform() :
	var params_array = []
	
	for key in mp :
		var p = mp[key]
		if p is Vector2 :
			params_array.append(p.x)
			params_array.append(p.y)
		elif p is Vector3 :
			params_array.append(p.x)
			params_array.append(p.y)
			params_array.append(p.z)
			params_array.append(0.0)
		else : 
			params_array.append(p)
	params_array.resize(88)
	var fpa = PackedFloat32Array(params_array)
	var fpba = fpa.to_byte_array()
	rd.buffer_update(prm_buffer, 0, fpba.size(), fpba)



func loadTexture(imagepath) :
	var picture = load(imagepath) 
	var img = picture.get_image()
	img.decompress()
	img.convert(Image.FORMAT_RGBAF)
	var img_pba = img.get_data()
	var width = picture.get_width()
	var height = picture.get_height()
	
	var fmt = RDTextureFormat.new()
	fmt.width = width
	fmt.height = height
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	#fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_SRGB
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	var tex = rd.texture_create(fmt, RDTextureView.new(), [img_pba])
	return tex


class SamplerUniform  :
	
	var image
	var sampler
	var uniform
	var rd 
	func _init(inrd : RenderingDevice, input_image , binding = 0 ) :
		rd = inrd
		
		var sampler_state = RDSamplerState.new()
		sampler_state.border_color = RenderingDevice.SAMPLER_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK
		sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
		sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
		sampler_state.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
		sampler_state.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
		sampler = rd.sampler_create(sampler_state)
		uniform  = RDUniform.new()
		uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
		uniform.binding = binding
		uniform.add_id(sampler)
		# ~ if input_image != null :
		image = input_image
		uniform.add_id(image)
	




func get_matrices_buffer(render_scene_data):
		var invcam_tr = render_scene_data.get_cam_transform()
		var proj = render_scene_data.get_cam_projection()
		
		var view_tr = invcam_tr.inverse()
		var invproj = proj.inverse()
		

		var invcam_mat = [
			invcam_tr.basis.x.x, invcam_tr.basis.x.y, invcam_tr.basis.x.z, 0.0, 
			invcam_tr.basis.y.x, invcam_tr.basis.y.y, invcam_tr.basis.y.z, 0.0, 
			invcam_tr.basis.z.x, invcam_tr.basis.z.y, invcam_tr.basis.z.z, 0.0, 
			invcam_tr.origin.x, invcam_tr.origin.y, invcam_tr.origin.z, 1.0, 
		]
		
		var proj_mat = [
			proj.x.x, proj.x.y, proj.x.z,  proj.x.w, 
			proj.y.x, proj.y.y, proj.y.z,proj.y.w, 
			proj.z.x, proj.z.y, proj.z.z, proj.z.w, 
			proj.w.x, proj.w.y, proj.w.z, proj.w.w, 
		]
		
		
		var view_mat = [
			view_tr.basis.x.x, view_tr.basis.x.y, view_tr.basis.x.z, 0.0, 
			view_tr.basis.y.x, view_tr.basis.y.y, view_tr.basis.y.z, 0.0, 
			view_tr.basis.z.x, view_tr.basis.z.y, view_tr.basis.z.z, 0.0, 
			view_tr.origin.x, view_tr.origin.y, view_tr.origin.z, 1.0, 
		]
		
		var invproj_mat = [
			invproj.x.x, invproj.x.y, invproj.x.z,  invproj.x.w, 
			invproj.y.x, invproj.y.y, invproj.y.z,invproj.y.w, 
			invproj.z.x, invproj.z.y, invproj.z.z, invproj.z.w, 
			invproj.w.x, invproj.w.y, invproj.w.z, invproj.w.w, 
		]
		
		
		
		
		var icma = PackedFloat32Array(invcam_mat).to_byte_array()
		var pma = PackedFloat32Array(proj_mat).to_byte_array()
		
		var vma = PackedFloat32Array(view_mat).to_byte_array()
		var ipma = PackedFloat32Array(invproj_mat).to_byte_array()
		
		var pb = PackedByteArray()
		pb.append_array(icma)
		pb.append_array(pma)
		
		pb.append_array(vma)
		pb.append_array(ipma)
		
		rd.buffer_update(matrices_buffer, 0, 256, pb)


func update_matrices_uniforms(render_scene_data) :
	prev_matrices_buffer = matrices_buffer
	get_matrices_buffer(render_scene_data)


func get_misc_uniform(size, rsd,  binding : int) :
	
	var proj = rsd.get_cam_projection()
	var near = proj.get_z_near()
	var far = proj.get_z_far()
	
	var do_clear = 0.0
	if do_clear_on : 
		do_clear = 1.0
		do_clear_on = false
	var misc = [size.x, size.y, Time.get_ticks_msec()*0.001, frame, delta, near, far, do_clear]
	misc.resize(8)
	var mf = PackedFloat32Array(misc)
	var mfb = mf.to_byte_array()
	rd.buffer_update(misc_buffer, 0, mfb.size(), mfb)


	



func _render_callback(p_effect_callback_type:int, p_render_data: RenderData)->void:	
	if rd and p_effect_callback_type == CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT:
	# ~ if rd and p_effect_callback_type == CompositorEffect.EFFECT_CALLBACK_TYPE_POST_SKY:
		
		
		var render_scene_buffers : RenderSceneBuffersRD = p_render_data.get_render_scene_buffers()
		if render_scene_buffers:

			var size:Vector2i = render_scene_buffers.get_internal_size()
			if size.x == 0 and size.y == 0:
				return
			
			frame += 1
			
			var tick = Time.get_ticks_msec() *0.001
			delta = tick - last_tick
			last_tick = tick
			
			@warning_ignore("integer_division")
			var x_groups:int = (size.x - 1) / 8 + 1
			# ~ var x_groups:int = size.x
			@warning_ignore("integer_division")
			var y_groups:int = (size.y - 1) / 8 + 1
			# ~ var y_groups:int = size.y

			
			# ~ var downsize = Vector2i((size.x ) / downSample_scale +1, (size.y ) / downSample_scale  +1)
			# ~ var downgroups = Vector2i((downsize.x - 1) / 8 , (downsize.y - 1) / 8 )+ Vector2i(1,1)
			
			var view_count:int = render_scene_buffers.get_view_count()
			for view in range(view_count):
				var input_image: RID = render_scene_buffers.get_color_layer(view)
				var depth_image: RID = render_scene_buffers.get_depth_layer(view)
				var velocity_buffer: RID = render_scene_buffers.get_velocity_layer(view)
				var normals_buffer = render_scene_buffers.get_texture("forward_clustered", "normal_roughness")

				
				
				
				if not tex_init : 
				
					var tf = rd.texture_get_format(input_image)
					# ~ tf.array_layers = 9
					tf.array_layers = 2
					tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D_ARRAY
					cp_tex = rd.texture_create(tf, RDTextureView.new())
					tex_init = true
				
					
				
				# ~ # SCREEN COLOR UNIFORM
				

				color_uniform.clear_ids()
				color_uniform.add_id(input_image)

				# SCREEN COLOR SAMPLER UNIFORM

				colsamp_uniform.clear_ids()
				colsamp_uniform.add_id(nearest_sampler2)
				colsamp_uniform.add_id(input_image)
				color_uniform_set = UniformSetCacheRD.get_cache(shader, 0, [ color_uniform, colsamp_uniform ])

				# DEPTH BUFFER UNIFORM

				depth_uniform.clear_ids()
				depth_uniform.add_id(nearest_sampler)
				depth_uniform.add_id(depth_image)
				depth_uniform_set = UniformSetCacheRD.get_cache(shader, 2, [ depth_uniform ])
				
				
				# TRAILS COLOR UNIFORM

				trail_color_uniform.clear_ids()
				trail_color_uniform.add_id(cp_tex)

				trail_colsamp_uniform.clear_ids()
				trail_colsamp_uniform.add_id(nearest_sampler3)
				trail_colsamp_uniform.add_id(cp_tex)
				
				trail_color_uniform_set = UniformSetCacheRD.get_cache(shader, 1, [ trail_color_uniform, trail_colsamp_uniform, blue_noise_tex_u.uniform ])
				
				# VELOCTY UNIFORM

				velocity_uniform.clear_ids()
				velocity_uniform.add_id(velocity_buffer)
				
				velsamp_uniform.clear_ids()
				velsamp_uniform.add_id(nearest_sampler3)
				velsamp_uniform.add_id(velocity_buffer)
				
				# NORMALS UNIFORM
				

				normal_uniform.clear_ids()
				normal_uniform.add_id(normals_buffer)
				
				norsamp_uniform.clear_ids()
				norsamp_uniform.add_id(nearest_sampler3)
				norsamp_uniform.add_id(normals_buffer)
				
				
				
				velocity_set = UniformSetCacheRD.get_cache(shader, 4, [ velocity_uniform, normal_uniform, velsamp_uniform, norsamp_uniform ])

				var render_scene_data = p_render_data.get_render_scene_data()
			
				
				update_matrices_uniforms(render_scene_data)
				
				get_params_uniform()
				
				get_misc_uniform(size, render_scene_data, 0)
				
				
				misc_uniform_set = UniformSetCacheRD.get_cache(shader, 3, [  misc_uniform, prm_uniform,   matrices_uniform, prev_matrices_uniform ])

				var compute_list := rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, out_pipeline)
				rd.compute_list_bind_uniform_set(compute_list, color_uniform_set, 0)
				rd.compute_list_bind_uniform_set(compute_list, trail_color_uniform_set, 1)
				rd.compute_list_bind_uniform_set(compute_list, depth_uniform_set, 2)
				rd.compute_list_bind_uniform_set(compute_list, misc_uniform_set, 3)
				rd.compute_list_bind_uniform_set(compute_list, velocity_set, 4)


				
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
				
				rd.compute_list_end()
				
		

# Check if our shader has changed and needs to be recompiled.
func _check_shader() -> bool:
	if not rd:
		return false
	var new_shader_code : String = ""
	mutex.lock()
	if shader_is_dirty:
		print("shader is dirty")
		shader_is_dirty = false
	mutex.unlock()
	if new_shader_code.is_empty():
		return out_pipeline.is_valid()
	if shader.is_valid():
		rd.free_rid(shader)
		shader = RID()
		out_pipeline = RID()
	var shader_source : RDShaderSource = RDShaderSource.new()
	shader_source.language = RenderingDevice.SHADER_LANGUAGE_GLSL
	shader_source.source_compute = new_shader_code
	var shader_spirv : RDShaderSPIRV = rd.shader_compile_spirv_from_source(shader_source)

	if shader_spirv.compile_error_compute != "":
		push_error(shader_spirv.compile_error_compute)
		push_error("In: " + new_shader_code)
		return false

	shader = rd.shader_create_from_spirv(shader_spirv)
	if not shader.is_valid():
		return false

	out_pipeline = rd.compute_out_pipe_line_create(shader)
	return out_pipeline.is_valid()



func _notification(what:int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if shader.is_valid():
			rd.free_rid(shader)
		#cu2.free()
