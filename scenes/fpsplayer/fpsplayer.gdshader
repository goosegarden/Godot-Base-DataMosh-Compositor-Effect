shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D d_texture : hint_depth_texture;

uniform vec4 edge_color : source_color;
uniform float threshold : hint_range(0.0, 1.0) = 0.2;
uniform float line_thickness : hint_range(0.0, 1.0) = 0.2;

const mat3 sobel_x = mat3(
    vec3(1.0, 2.0, 1.0),
    vec3(0.0, 0.0, 0.0),
    vec3(-1.0, -2.0, -1.0)
);

const mat3 sobel_y = mat3(
    vec3(1.0, 0.0, -1.0),
    vec3(2.0, 0.0, -2.0),
    vec3(1.0, 0.0, -1.0)
);

//void vertex() {
    //POSITION = vec4(VERTEX, 1.0);
//}

void fragment() {
    vec2 pixel_size = 1.0 / VIEWPORT_SIZE.xy;

    vec3 pixels[9];
    for (int i = 0; i < 9; i++) {
        vec2 offset = vec2(float(i % 3) - 1.0, float(i / 3) - 1.0);
        //pixels[i] = textureLod(d_texture, SCREEN_UV + offset * pixel_size, 0.0).rgb * 0.1;
        pixels[i] = textureLod(screen_texture, SCREEN_UV + offset * pixel_size, 0.0).rgb;
    }
    
    float gx = dot(sobel_x[0], vec3(pixels[0].r, pixels[1].r, pixels[2].r)) +
                dot(sobel_x[1], vec3(pixels[3].r, pixels[4].r, pixels[5].r)) +
                dot(sobel_x[2], vec3(pixels[6].r, pixels[7].r, pixels[8].r));

    float gy = dot(sobel_y[0], vec3(pixels[0].r, pixels[1].r, pixels[2].r)) +
                dot(sobel_y[1], vec3(pixels[3].r, pixels[4].r, pixels[5].r)) +
                dot(sobel_y[2], vec3(pixels[6].r, pixels[7].r, pixels[8].r));

    float gradient = sqrt(gx * gx + gy * gy);
    float edge_factor = smoothstep(threshold - line_thickness, threshold + line_thickness, gradient);

    vec3 color = mix(textureLod(screen_texture, SCREEN_UV, 0.0).rgb, edge_color.rgb, edge_factor);
    
    //ALBEDO = vec3(1.0,0.0,0.0);
    ALBEDO = vec3(color);
    //ALBEDO = texture(d_texture, SCREEN_UV).rgb;
}