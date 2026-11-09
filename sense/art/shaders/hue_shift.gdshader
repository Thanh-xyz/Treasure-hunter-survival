shader_type canvas_item;
// Rotates hue (degrees) and scales saturation of a CC0 sprite, e.g. the green Ninja Adventure
// dragon recoloured for the Infernal Dragon (plan phase E). Pixel alpha is untouched.

uniform float hue_degrees = 0.0;
uniform float saturation = 1.0;
// Only pixels at least this saturated are shifted, so pale details (faces, horns) keep their colour.
uniform float min_saturation = 0.4;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 hsv = rgb2hsv(tex.rgb);
	float weight = smoothstep(min_saturation - 0.1, min_saturation + 0.1, hsv.y);
	vec3 shifted = vec3(fract(hsv.x + hue_degrees / 360.0), clamp(hsv.y * saturation, 0.0, 1.0), hsv.z);
	COLOR = vec4(mix(tex.rgb, hsv2rgb(shifted), weight), tex.a) * COLOR;
}
