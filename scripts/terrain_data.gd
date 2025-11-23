class_name TerrainData

var size: int
var data_types: PackedInt64Array
var data_heights: PackedFloat32Array

@warning_ignore("shadowed_variable")
func _init(size: int, data_types: PackedInt64Array, data_heights):
	self.size = size
	self.data_types = data_types
	self.data_heights = data_heights

func get_tile_data_types(x: int, y: int) -> int:
	if x < 0 || x >= self.size || y < 0 || y >= self.size:
		return 0
	
	var index := x + y * self.size
	return self.data_types.get(index)

func get_tile_data_heights(x: int, y: int) -> Vector4:
	if x < 0 || x >= self.size || y < 0 || y >= self.size:
		return Vector4.ZERO
	
	var index := (x + y * self.size) * 4
	var height1 = self.data_heights.get(index)
	var height2 = self.data_heights.get(index + 1)
	var height3 = self.data_heights.get(index + 2)
	var height4 = self.data_heights.get(index + 3)
	
	return Vector4(height1, height2, height3, height4)

@warning_ignore("shadowed_variable")
static func create_type(is_flipped: bool, type1: int, type2: int, cliff_n: int, cliff_e: int, cliff_s: int, cliff_w: int) -> int:
	var flipped_bit = 1 << 63 if is_flipped else 0
	var a = type1 & 0xFF
	var b = (type2 << 8) & 0xFF00
	var c = (cliff_n << 16) & 0xFF0000
	var d = (cliff_e << 24) & 0xFF000000
	var e = (cliff_s << 32) & 0xFF00000000
	var f = (cliff_w << 40) & 0xFF0000000000
	return a | b | c | d | e | f | flipped_bit
