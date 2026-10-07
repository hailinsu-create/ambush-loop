shader_type spatial;
render_mode specular_schlick_ggx;
varying vec3 world_at;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() { world_at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 vec2 p = world_at.xz;
 vec2 slab = vec2(p.x + mod(floor(p.y / 3.0), 2.0) * 1.5, p.y);
 vec2 seam_distance = min(fract(slab / 3.0), 1.0 - fract(slab / 3.0));
 vec2 aa = max(fwidth(slab / 3.0), vec2(0.001));
 float seam = 1.0 - smoothstep(0.003, 0.003 + max(aa.x, aa.y), min(seam_distance.x,seam_distance.y));
 float grain = hash(floor(p * 16.0)) * 0.010;
 float patch = hash(floor(slab / 3.0)) * 0.025;
 vec3 concrete = vec3(0.085, 0.110, 0.125) + patch + grain;
 float lane = smoothstep(1.0, 1.15, abs(p.x + 6.5)) * (1.0 - smoothstep(1.20, 1.32, abs(p.x + 6.5)));
 float dash = step(0.43, fract((p.y + 10.0) / 2.4));
 float marking = lane * dash * 0.48;
 ALBEDO = mix(concrete * (1.0 - seam * 0.16), vec3(0.36,0.32,0.19), marking);
 ROUGHNESS = 0.92;
}
