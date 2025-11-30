float eval_curve_at(float[32] curve_values, float ratio) {
	float indexRatio = ratio * 32.0;
	int index = int(indexRatio);
	if (index <= 0) {
		return curve_values[0];
	}
	if (index >= 31) {
		return curve_values[31];
	}

	float in_between = fract(indexRatio);
	return mix(curve_values[index], curve_values[index + 1], in_between);
	//return in_between;
}
