#[compute]
#version 450


layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
//~ layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(rgba16f, set=0, binding=0) uniform image2D color_image; 
layout( set=0, binding=1) uniform sampler2D color_sampler; 

layout(rgba16f, set=1, binding=0) uniform image2DArray trail_image;
layout( set=1, binding=1) uniform sampler2DArray trail_sampler;
layout( set=1, binding=2) uniform sampler2D blue_noise_sampler;

layout( set=2, binding=0) uniform sampler2D depth_texture;

layout(rg16f, set=4, binding=0) uniform image2D velocity_image;
layout(rg16f, set=4, binding=1) uniform image2D normal_image;


layout(set=4, binding=2) uniform sampler2D velocity_sampler;
layout(set=4, binding=3) uniform sampler2D normal_sampler;



layout(set=3, binding=0) uniform miscBuffer {
	vec2 resolution;
	float time;
	float frame;
	float delta;
	float near;
	float far;
	float do_clear;
	
	} misc; 



layout(set=3, binding=1) uniform MatU {
	mat4 view;
	mat4 proj;
	
	mat4 invview;
	mat4 invproj;
	
	} mat; 


layout(set=3, binding=3) uniform prevMatU {
	mat4 view;
	mat4 proj;
		
	mat4 invview;
	mat4 invproj;
	
	} prevmat; 






layout(std140, set=3, binding=2) uniform paramsUniforms {
	
	vec3 vel_scale_fac;
	
	
	vec2 col_lum_bounds;

	vec2 col_depth_bounds;

	vec2 vel_lum_bounds;

	vec2 vel_depth_bounds;

	
	float vel_clamp;
	
	float vel_pix_size;
	
	float col_depth_smoothfac;
	float vel_depth_smoothfac;
	
	
	float col_depth_fac;
	float vel_depth_fac;
	
	float col_lum_fac;
	float vel_lum_fac;
	
	
	float ripples_on;

	float ripples_intensity;
	float ripples_freq;
	float ripples_numwaves;
	
	float op_op;
	float op_p1;
	float op_p2;
	float op_base;
	float op_fac;
	
	
	float vel_op_op;
	float vel_op_p1;
	float vel_op_p2;
	float vel_op_base;
	float vel_op_fac;
	

	
	float sobel_on;
	float sobel_width;
	float sobel_fac;
	
	float wind_on;
	float wind_fac;
	float wind_noise;
	float wind_noise_scale;
	float wind_noise_step;
	float wind_noise_smooth;
	float vortex;
	
	float master_fade;
	
	} params; 





#define DRAG_MULT 0.048



float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}



vec3 rgb_to_YCbCr(vec3 col){
	float Y = dot (col, vec3(0.2989 , 0.5866 , 0.1145 ));
	float Cb = dot (col, vec3(-0.1687 ,- 0.3313 ,0.5000 ));
	float Cr = dot (col, vec3(0.5000 , - 0.4184 , - 0.0816 ));
	
	return vec3(Y, Cb, Cr);
}





	
mat2 rotate2d(in float r){
    float c = cos(r);
    float s = sin(r);
    return mat2(c, -s, s, c);
}
	
mat3 rotate3d_Z(in float r){
    float c = cos(r);
    float s = sin(r);
    return mat3(c, -s, 0.0, s, c,0.0,1.0,0.0,0.0);
}

	

float Op_func(float l_in,  float f ){

	float p1;
	float p2;
	
	
	if(params.op_p1 == 0.0){
		p1 = f * params.col_depth_fac;
	}
	else if(params.op_p1 == 1.0){
		p1 = l_in * params.col_lum_fac;
	}
	else if(params.op_p1 == 2.0){
		//~ p1 = (1.0 - l_in) * params.col_lum_fac;
		p1 = (1.0 - min(1.0,l_in) ) * params.col_lum_fac;
	}
	

	if(params.op_p2 == 0.0){
		p2 =  f * params.col_depth_fac;
		}
	else if(params.op_p2 == 1.0){
		p2 = l_in * params.col_lum_fac;
	}
	else if(params.op_p2 == 2.0){
		//~ p2 = (1.0 - l_in) * params.col_lum_fac;
		p2 = (1.0 - min(1.0,l_in) ) * params.col_lum_fac;
	}
	

	
	
	float op;
	if(params.op_op == 0.0){
		op = p1;
		}
	else if(params.op_op == 1.0){
		op = min(p1, p2);
	}
	else if(params.op_op == 2.0){
		op = p1 * p2;
	}
	else if(params.op_op == 3.0){
		op =  p1 + p2;
	}
	
	else if(params.op_op == 4.0){
		op =  p1 - p2;
	}
	
	else if(params.op_op == 5.0){
		op =  max(p1, p2);
	}
	
	return op * params.op_fac + params.op_base;

}
	




float vel_Op_func(float l_in,  float f ){

	float p1;
	float p2;
	
	
	if(params.vel_op_p1 == 0.0){
		p1 = f * params.vel_depth_fac;
	}
	else if(params.vel_op_p1 == 1.0){
		p1 = l_in * params.vel_lum_fac;
	}
	else if(params.vel_op_p1 == 2.0){
		//~ p1 = (1.0 - l_in) * params.vel_lum_fac;
		p1 = (1.0 - min(1.0,l_in)) * params.vel_lum_fac;
	}
	


	if(params.vel_op_p2 == 0.0){
		p2 = f * params.vel_depth_fac;
		}
	else if(params.vel_op_p2 == 1.0){
		p2 = l_in * params.vel_lum_fac;
	}
	else if(params.vel_op_p2 == 2.0){
		//~ p2 = (1.0 - l_in) * params.vel_lum_fac;
		p2 = (1.0 - min(1.0,l_in)) * params.vel_lum_fac;
	}
	

	
	
	float op;
	if(params.vel_op_op == 0.0){
		op = p1;
		}
	else if(params.vel_op_op == 1.0){
		op = min(p1, p2);
	}
	else if(params.vel_op_op == 2.0){
		op = p1 * p2;
	}
	else if(params.vel_op_op == 3.0){
		op =  p1 + p2;
	}
	
	else if(params.vel_op_op == 4.0){
		op =  p1 - p2;
	}
	
	else if(params.vel_op_op == 5.0){
		op =  max(p1, p2);
	}
	
	return op * params.vel_op_fac + params.vel_op_base;

}
	







void clear_accums(ivec2 iuvs){
	
	vec4 col = imageLoad(trail_image, ivec3(iuvs, 0));
	vec4 vel = imageLoad(trail_image, ivec3(iuvs, 1));
	
	imageStore(trail_image, ivec3(iuvs, 0), col);
	imageStore(trail_image, ivec3(iuvs, 1), vel);
	
	
	}



float sobelDepth(sampler2D tex, vec2 coord, float pix_dist)
{
	
	vec2 fsize = vec2(textureSize(tex, 0));

	float w = 1.0 / fsize.x;
	float h = 1.0 / fsize.y;
	
	w *= pix_dist;
	h *= pix_dist;

	float[9] n;


	n[0] = texture(tex, coord + vec2( -w, -h)).x;
	n[1] = texture(tex, coord + vec2(0.0, -h)).x;
	n[2] = texture(tex, coord + vec2(  w, -h)).x;
	n[3] = texture(tex, coord + vec2( -w, 0.0)).x;
	n[4] = texture(tex, coord).x;
	n[5] = texture(tex, coord + vec2(  w, 0.0)).x;
	n[6] = texture(tex, coord + vec2( -w, h)).x;
	n[7] = texture(tex, coord + vec2(0.0, h)).x;
	n[8] = texture(tex, coord + vec2(  w, h)).x;


	float sobel_edge_h = n[2] + (2.0*n[5]) + n[8] - (n[0] + (2.0*n[3]) + n[6]);
  	float sobel_edge_v = n[0] + (2.0*n[1]) + n[2] - (n[6] + (2.0*n[7]) + n[8]);
	float sobel = sqrt((sobel_edge_h * sobel_edge_h) + (sobel_edge_v * sobel_edge_v));
	return sobel;

}




vec4 sample_blue_noise(vec2 uv, float scale, float frame_stride, vec2 screen_size){
	float bn_scale = scale;
	float bn_fr = floor(float(misc.frame) / frame_stride);
	
	vec2 bn_ratio = vec2(textureSize(blue_noise_sampler, 0)) / screen_size;

	float base = mod(bn_fr, bn_scale*bn_scale);
	float x_base = floor(base /bn_scale);
	float y_base = base - x_base * bn_scale;
	
	vec2 shift = vec2(x_base, y_base);
	vec2 bn_uv = uv / bn_ratio * (1.0/bn_scale) + shift * (1.0/bn_scale);
	
	vec4 bn = texture(blue_noise_sampler, bn_uv);
	return bn;

	
	}


vec3 get_world_pos(vec2 uv, float depth){
	vec4 upos = mat.view * mat.invproj * vec4(uv * 2.0 - 1.0, depth, 1.0);
	vec3 pp = upos.xyz / upos.w;
	return pp;
	
	}

vec3 get_world_pos_nd(vec2 uv){
	
	float depth = texture(depth_texture, uv).r;
	
	vec4 upos = mat.view * mat.invproj * vec4(uv * 2.0 - 1.0, depth, 1.0);
	vec3 pp = upos.xyz / upos.w;
	return pp;
	
	}



vec3 get_cam_pos(vec2 uv, float depth){
	vec4 upos = mat.invproj * vec4(uv * 2.0 - 1.0, depth, 1.0);
	vec3 cp = upos.xyz / upos.w;
	return cp;
	
	}



vec3 get_cam_pos_nd(vec2 uv){
	
	float depth = texture(depth_texture, uv).r;
	
	vec4 upos = mat.invproj * vec4(uv * 2.0 - 1.0, depth, 1.0);
	vec3 cp = upos.xyz / upos.w;
	return cp;
	
	}


vec4 clip_from_world(vec3 world_pos){
	
	//~ vec4 view_p = ((mat.view) * vec4(world_pos, 1.0));
	vec4 clip_p = mat.proj * mat.invview * vec4(world_pos, 1.0);
	return clip_p;
	//~ float zc = clip_p.z;
	//~ float wc = clip_p.w;

	}

vec4 world_from_clip(vec2 fuv){
	
	//~ vec4 view_p = ((mat.view) * vec4(world_pos, 1.0));
	vec4 depth = texture(depth_texture, fuv);
	vec4 world = mat.view * mat.invproj * vec4(fuv * 2.0 - 1.0, depth.r, 1.0);
	return world;
	//~ float zc = clip_p.z;
	//~ float wc = clip_p.w;

	}




vec3 get_world_normal(vec2 fuv){
	vec4 normal = texture(normal_sampler, fuv); 
	mat3 nmv = mat3(
		mat.view
		);	
	vec3 wn =  normalize( nmv * (normal.xyz - 0.5) );
	return wn;
	}

vec3 get_view_normal(vec2 fuv){
	vec4 normal = texture(normal_sampler, fuv); 
	
	vec3 wn =   (normal.xyz - 0.5) ;
	return wn;
	}


vec3 get_world_normal_nd(vec2 fuv, float delta){
	vec3 Nx = get_world_pos_nd(fuv + vec2(delta, 0.0)) - get_world_pos_nd(fuv - vec2(delta, 0.0));
	vec3 Ny = get_world_pos_nd(fuv + vec2(0.0, delta)) - get_world_pos_nd(fuv - vec2(0.0, delta));
	vec3 wn = cross(normalize(Nx), normalize(Ny));
	return wn;
	}







// *** https://www.shadertoy.com/view/MdXyzX *** // modified for 3d pos


// Calculates wave value and its derivative, 
// for the wave direction, position in space, wave frequency and time
//~ vec2 wavedx(vec2 position, vec3 direction, float frequency, float timeshift) {
vec2 wavedx(vec3 position, vec3 direction, float frequency, float timeshift) {
  float x = dot(direction, position) * frequency + timeshift;
  float wave = exp(sin(x) - 1.0);
  float dx = wave * cos(x);
  return vec2(wave, -dx);
}


float getOceanWaves(vec3 position, int iterations) {
  float wavePhaseShift = length(position) * 0.1; // this is to avoid every octave having exactly the same phase everywhere
  float iter = 0.0; // this will help generating well distributed wave directions
  
  
  //~ float frequency = 1.0; // frequency of the wave, this will change every iteration
  float frequency = params.ripples_numwaves; // frequency of the wave, this will change every iteration
  
  //~ float timeMultiplier = 2.0; // time multiplier for the wave, this will change every iteration
  float timeMultiplier = params.ripples_freq; // time multiplier for the wave, this will change every iteration
  
  float weight = 1.0;// weight in final sum for the wave, this will change every iteration
  float sumOfValues = 0.0; // will store final sum of values
  float sumOfWeights = 0.0; // will store final sum of weights
  for(int i=0; i < iterations; i++) {
    // generate some wave direction that looks kind of random
   
    //~ vec2 p = vec2(sin(iter), cos(iter));
    vec3 p = vec3(sin(iter), cos(iter), hash11(iter));
    
    // calculate wave data
    vec2 res = wavedx(position, p, frequency, misc.time * timeMultiplier + wavePhaseShift);

    // shift position around according to wave drag and derivative of the wave
    position += p * res.y * weight * DRAG_MULT;

    // add the results to sums
    sumOfValues += res.x * weight;
    sumOfWeights += weight;

    // modify next octave ;
    weight = mix(weight, 0.0, 0.2);
    frequency *= 1.18;
    timeMultiplier *= 1.07;

    // add some kind of random value to make next wave look random too
    iter += 1232.399963;
  }
  // calculate and return
  return sumOfValues / sumOfWeights;
}







void main() {
	
	
	float delta_fac = 1.0 / pow(1.0 , misc.delta * 120.0);
	
	
	ivec2 iuv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = imageSize(color_image);
	
	
	vec2 pixel_size = vec2(1.0) / vec2(size);
	
	if (misc.do_clear > 0.0) clear_accums(iuv);
		
	
	vec2 fuv = (vec2(iuv) + 0.5f) / vec2(size);
	vec4 depth = texture(depth_texture, fuv);
	
	
	// WORLD POSITION
	
	vec3 pp = get_world_pos(fuv, depth.r);
	
	
	
	
	
	// DEPTH
	
	vec3 cpp = get_cam_pos(fuv, depth.r);
	float cam_dist =length(cpp);
	
	
	float f2 = -cpp.z ;
	
	vec2 cuv = fuv *2.0 - 1.0;
	cuv.y *= float(size.y)/float(size.x);
	
	
	float h = params.vel_pix_size ;
	
	
	ivec2 hiuv = ivec2(floor(vec2(iuv)/h) * h);
	vec4 velocity = imageLoad(velocity_image, hiuv); 
	

	vec4 vel_accum = texture(trail_sampler, vec3(fuv, 1.0));
	vec4 vel_accum_out = vec4(1.0);
	
	

	vec4 color = texture(color_sampler, fuv);
	
	
	
	vec3 ycbcr = rgb_to_YCbCr(color.rgb);


	float lum = ycbcr.x;
	

	
	float l = smoothstep(params.col_lum_bounds.x, params.col_lum_bounds.y,lum );
	float f = smoothstep(params.col_depth_bounds.x   * params.col_depth_smoothfac, params.col_depth_bounds.y  * params.col_depth_smoothfac, f2) ;
	
	float l_v = smoothstep(params.vel_lum_bounds.x, params.vel_lum_bounds.y,lum);
	float f_v = smoothstep(params.vel_depth_bounds.x  * params.vel_depth_smoothfac, params.vel_depth_bounds.y * params.vel_depth_smoothfac, f2) ;
	
	
	float velint = length(vel_accum.xy);
	
	float vel_accum_blend = vel_Op_func(l_v, f_v) ;
	

	vel_accum_blend *= delta_fac;
	vel_accum_blend = clamp(vel_accum_blend, 0.005, 0.995);


	
	vel_accum = mix (velocity , vel_accum, vel_accum_blend);
	imageStore(trail_image, ivec3(iuv, 1), vel_accum);



	vel_accum.y *= -float(size.y/size.x) ;
	vel_accum.y -= float(size.y/size.x) * 0.5;

	vec3 vel_scale = params.vel_scale_fac ;



	if(params.ripples_on > 0.5){

	
		
		vec2 eps = vec2(0.1,0.0);
		int iter = 5;
		vec3 opp = pp *0.5;
		float owpx = getOceanWaves(opp.xyz + eps.xyy, iter);
		float owmx = getOceanWaves(opp.xyz - eps.xyy, iter);
		float owpy = getOceanWaves(opp.xyz + eps.yxy, iter);
		float owmy = getOceanWaves(opp.xyz - eps.yxy, iter);
		
		vec2 oceanNor = vec2(owpx - owmx, owpy - owmy) / (eps.x *2.0);
		
	
		vec2 turbs = oceanNor * 0.2 * params.ripples_intensity;
		vel_accum.xy = vel_accum.xy + (0.02 + smoothstep(0.01,0.1, length(vel_accum.xy)) * 1.0) * turbs ;
		
		
	}
	
	
	if (params.wind_on > 0.5){
		
			
		vec3 icpp = cpp;
		icpp.y *= -1;
		vec3 rcpp = floor(cpp * 16.0) / 16.0;
		vec3 wind_dir = vec3(0.0,0.0,1.0);
		
		vec4 wbn = sample_blue_noise(fuv, params.wind_noise_scale, params.wind_noise_step, size);
		vec3 forward_wind = (wind_dir  - icpp  ) * pow(wbn.xyz, vec3(params.wind_noise)) * (wbn.w ) + (wbn.xyz-0.5) * params.wind_noise_smooth ;
		
		vec2 rcuv = vec2(-cuv.y, cuv.x);
		
		vel_accum.xy +=  normalize(forward_wind.xy / -forward_wind.z) *0.01 * params.wind_fac * delta_fac;
		
		vel_accum.xy += rcuv*0.01*params.vortex;
		
	
		
		}
	


	vec2 vc = vec2(params.vel_clamp);
	vel_accum.xy = clamp(vel_accum.xy, -vc, vc);
	
	vel_accum.xy *= step(0.0001, length(vel_accum.xy));
	



	vec2 c_uvelr = (vel_accum.xy) * vel_scale.x ;
	vec2 c_uvelg = (vel_accum.xy) * vel_scale.y;
	vec2 c_uvelb = (vel_accum.xy) * vel_scale.z ;


	vec2 fxfuv = (vec2(iuv) + 0.5f)/vec2(size);
	
	vec2 dm_uvr = c_uvelr  + fxfuv ;
	vec2 dm_uvg = c_uvelg  + fxfuv ;
	vec2 dm_uvb = c_uvelb  + fxfuv ;
	
	vec4 vcol = texture(trail_sampler,vec3(dm_uvr, 0.0));
	vec4 vcolg = texture(trail_sampler,vec3(dm_uvg, 0.0));
	vec4 vcolb = texture(trail_sampler,vec3(dm_uvb, 0.0));
	
	vcol.g = vcolg.g;
	vcol.b = vcolb.b;



	float blendfunc =  Op_func(l, f);
	
	
	blendfunc *= delta_fac;
	

	blendfunc = clamp(blendfunc, 0.01, 0.995 );
	

	vec4 final_col = mix(color, vcol, blendfunc);


	if (params.sobel_on > 0.5){
		
		float sobEdge = sobelDepth(depth_texture, fuv, params.sobel_width);
		sobEdge *= 100.0;
		sobEdge *= step(0.009,sobEdge);

		vec3 sob_col = vec3(1.0 ); 

		final_col.rgb = mix(final_col.rgb, sob_col, sobEdge * params.sobel_fac);
	}
	
	
	
	


	imageStore(trail_image, ivec3(iuv, 0 ), final_col);
	
	
	final_col.rgb = mix(color.rgb, final_col.rgb,  params.master_fade);
    
  
	imageStore(color_image, iuv, final_col);

	
}
