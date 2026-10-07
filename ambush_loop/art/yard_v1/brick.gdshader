shader_type spatial;
varying vec3 world_at;
varying vec3 world_normal;
void vertex() {
 world_at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
 world_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
}
void fragment() {
 vec2 p = vec2(abs(world_normal.x) > 0.5 ? world_at.z : world_at.x, world_at.y);
 float row = floor(p.y / 0.22);
 vec2 brick = vec2(p.x / 0.58 + mod(row,2.0) * 0.5, p.y / 0.22);
 vec2 edge = min(fract(brick), 1.0 - fract(brick));
 float mortar = 1.0 - smoothstep(0.028, 0.055 + max(fwidth(brick.x),fwidth(brick.y)), min(edge.x,edge.y));
 float variation = fract(sin(dot(floor(brick),vec2(17.7,83.2))) * 8713.3);
 vec3 color = mix(vec3(0.09,0.11,0.125),vec3(0.16,0.125,0.095),variation);
 color *= mix(0.76,1.0,smoothstep(0.0,0.3,world_at.y));
 ALBEDO = mix(color,vec3(0.065,0.085,0.095),mortar * 0.72);
 ROUGHNESS = 0.94;
}
