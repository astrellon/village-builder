shader_type spatial;

uniform vec3 target_pos;
uniform float radius = 1.0;
uniform float[32] curve_values;

varying vec3 world_pos;

void vertex() {
	// Called for every vertex the material is visible on.
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX = VERTEX + NORMAL * 0.001;
}

float eval_curve_at(float ratio) {
	if (ratio <= 0.0) {
		return curve_values[0];
	}
	if (ratio >= 1.0) {
		return curve_values[31];
	}
	
	int index = int(ratio * 32.0);
	float in_between = fract(ratio * 32.0);
	return mix(curve_values[index], curve_values[index + 1], in_between);
}

void fragment() {
	// Called for every pixel the material is visible on.
	//vec3 vertex_world_pos = VERTEX;
	float dist = length(target_pos.xz - world_pos.xz);
	float ratio = 1.0 - dist / radius;
	if (ratio <= 0.0)
	{
		discard;
	}
	
	ALBEDO = vec3(1.0, 0.0, 0.0);
	ALPHA = eval_curve_at(ratio);
}
