/*

Subpixel-Perfect Display by unfa (https://unfa.xyz)

Based on Godot Engine 4.3.stable's StandardMaterial3D
Written for Liblast (https://libla.st) on 2024-09-14/15

This shader generates a subpixel grid based on UV1 and uses partial derivatives to maintain minimal aliasing
with maxium clarity. It took a lot of work to make this look so natural, which you'll realize once you dig through the code.
Lots of mysterious numbers here sorry - this shacer is not parametrizable, but it will adjust to whatever texture resolution you give it.

Biggest challenges here were:
1. Achieving an acceptable level of aliasing in motion and with TAA (the first iteration using step() was worsened by TAA)
2. Making the source texture use filtering far out but then fade to "pixelated" up close. This is done with UV manipulation and a single texture lookup.
	However getting the coordinates to line up between filtered and "un-filtered" UVs, sub-pixel alignment, strange artifacts...
3. Achieving a relatively uniform apparent surface brightness at various distances.
	As it turns out it's really difficult to make a black board with bright dots appear comparable in brightness to a uniform "flat" texture. Forgive some variance there.

The shader could most definitely be optimized, simplified and parametrized, I just think getting it this good was an overkill already.
On a Radeon RX6800 XT it costs ~2 ms fullscreen at ~1440p (less than that, because Godot UI gets in the way a bit) which is a lot unfortunately.
I can't test this in VR, but I assume it could be really nice to have for diegetic displays in there.

Anyway, if you find this useful or inspiring, let me know! And definitely let me know if you managed to improve it further!

Also - huge thanks to Ben Golus for inspiration:
https://bgolus.medium.com/the-best-darn-grid-shader-yet-727f9278b9d8

- unfa

*/
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_nearest, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_nearest, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform sampler2D texture_emission : source_color, hint_default_black, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 emission : source_color;
uniform float emission_energy : hint_range(0.0, 100.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
}

// a shortcut for smoothstep that takes threshold/width ratehr than tresh1/thresh2
float aastep(float threshold, float width, float value) {
	//return step(threshold, value); // uncomment to compare how anti-aliased edges look vs non-anti-aliased ones
	return smoothstep(threshold - width/2.0, threshold + width / 2.0, value);
}

// a combination of two aasteps that takes a range out of the intut
float aastrip(float threshold1, float threshold2, float step_width,  float value) {
	return aastep(threshold1, step_width, value) * (1.0 - aastep(threshold2, step_width, value));
}


void fragment() {
	//// This is all StandardShader3D
	vec2 base_uv = UV; // somehow somewhere we double the UVs ,so let's fix that here... for now

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;


	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	//// The display fun begins here
	
	// Copy the base UV, before we mess with it
	vec2 raster_uv = base_uv;
	// store input texture resolution
	ivec2 resolution = textureSize(texture_emission, 0);
	vec2 texel_size = vec2(1.0) / vec2(resolution * 2);

	bool preview_enabled = false;
	vec3 preview;

	vec2 base_uv_pixelated = base_uv;
	base_uv_pixelated = floor(base_uv * vec2(resolution)
		+ vec2(1.0 / 3.0 , 0))
		/ vec2(resolution);
	// base_uv that forces hard edges between texel
	// offset the image to align with the raster, but clamp off so it doesn't wrap around the screen
	base_uv = clamp(base_uv - vec2(0.7 / 3.0, 0.5) / vec2(resolution), vec2(0,0), vec2(1,1));
	// calculate how much pielation adn raster should be applied based on scren-space UV derivatives
	//                          this 0.01 offset prevents pixels from never getting fully black in close-ups
	float pixelation_factor = 1.05 - clamp(max(
		fwidth(UV.x) * float(resolution.x),
		fwidth(UV.y) * float(resolution.y)) * 0.9, 0, 1);

	// sample the emission texture with optional pixelation
	float texture_pixelation_factor = 1.0;
	texture_pixelation_factor = smoothstep(0.75, 0.9, pixelation_factor);
	vec3 emission_tex = texture(texture_emission, (mix(base_uv, base_uv_pixelated, pow(texture_pixelation_factor, 0.5)) + texel_size)).rgb;

	// This will hold our subpixel RGB raster mask
	vec3 raster;

	// calculate how much width do we need to render smooth anti-aliased edges
	vec2 step_width;
	step_width.x = pow(fwidth(raster_uv.x) * float(resolution.x * 8), 1.8);
	step_width.y = pow(fwidth(raster_uv.y) * float(resolution.y * 12), 1);

	// slice 3 strips from the subpixel columns for R, G and B subpixels
	raster.r = aastrip(1.2, 1.8, step_width.x, mod(raster_uv.x * float(resolution.x * 3) - 1.0, 3.0));
	raster.g = aastrip(1.2, 1.8, step_width.x, mod(raster_uv.x * float(resolution.x * 3) + 0.0, 3.0));
	raster.b = aastrip(1.2, 1.8, step_width.x, mod(raster_uv.x * float(resolution.x * 3) + 1.0, 3.0));

	// calculate a mask that separates subpixels
	float raster_mask = pow(
		smoothstep(0.2, step_width.x * 128.0,
		sin(mod((UV.x * float(resolution.x * 3)), 1.0) * 3.2))
		* smoothstep(0.2, step_width.y * 32.0,
		sin(mod(UV.y * float(resolution.y), 1.0) * 3.2))
		, 0.25) * (1.0 + pow(pixelation_factor, 0.000000001) * 6.0);

	// blend the raster_mask with the RGB raster
	vec3 raster_combined = clamp(mix(vec3(1.0), (raster * 0.5), pixelation_factor) * 1.0, 0.0, 1.0);
	raster_combined *= clamp(mix(1.0, raster_mask, pow(texture_pixelation_factor, 0.33)), 0, 1);
	raster_combined = clamp(raster_combined, 0, 1);

	float screen_emission = 1.0;

	screen_emission = 0.5 +
	smoothstep(0.01, 1.4, pow(pixelation_factor, 2.2))
	+ (pow(pixelation_factor, 1.7) * 0.5 - 0.3)
	+ pow(texture_pixelation_factor, 0.35)
	+ pow(
		aastrip(1.055,1.1, 0.5, pixelation_factor + 0.07)
		, 1.5) * 100.0
	+ pow(
		aastrip(0.95,1.03, 0.18, pixelation_factor + 0.085)
		, 3.5) * 40.0;

	EMISSION = (emission.rgb * emission_tex * raster_combined) * (emission_energy * screen_emission);

	if (preview_enabled == true) {
		EMISSION = preview;
	}

}
