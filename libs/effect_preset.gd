extends Resource

class_name effect_preset


@export var wave = {
	"on" : false,
	"base" : 0.1,
	"freq" : 1.0,
	"amp" : 0.2,
	"last_op_fac" : 0.4,
}

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
	"vel_op_base" : 0.9,
	"vel_op_fac" : 1.0,
	
	"sobel_on" : 0.0,
	"sobel_width" : 1.0,
	"sobel_fac" : 1.0,
	
	"wind_on" : 0.0,
	"wind_fac" : 1.0,
	"wind_noise" : 1.0,
	"wind_noise_scale" : 1.0,
	"wind_noise_step" : 1.0,
	"wind_noise_smooth" : 0.0,
	"vortex" : 0.0,
	
	"master_fade" : 1.0,
	
}
