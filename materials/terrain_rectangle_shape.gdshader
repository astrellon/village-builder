shader_type spatial;

#include "terrain_brush_common.gdshaderinc"

uniform vec3 target_pos;
uniform vec2 half_size = vec2(1.0, 1.0);
uniform float[32] curve_values;

varying vec3 world_pos;

void vertex() {
	// Called for every vertex the material is visible on.
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX = VERTEX + NORMAL * 0.001;
}

void fragment() {
	// Called for every pixel the material is visible on.
	//vec3 vertex_world_pos = VERTEX;
	vec2 diff = abs(target_pos.xz - world_pos.xz);
	if (diff.x > half_size.x || diff.y > half_size.y)
	{
		discard;
	}
	
	float max_dim = max(diff.x / half_size.x, diff.y / half_size.y);
	float ratio = 1.0 - max_dim;
	
	ALBEDO = vec3(1.0, 0.0, 0.0);
	ALPHA = eval_curve_at(curve_values, ratio);
}
