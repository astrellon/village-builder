float eval_curve_at(float[32] curve_values, float ratio) {
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
