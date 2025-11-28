class_name TerrainChunkData

enum FaceType { TYPE1 = 1, TYPE2 = 2, CLIFF_NORTH = 3, CLIFF_EAST = 4, CLIFF_SOUTH = 5, CLIFF_WEST = 6 }

var position: Vector3i
var size: int
var data_types: PackedInt64Array
var data_heights: PackedVector4Array
var data_face_lookup: PackedByteArray = PackedByteArray()
var data_version: int = 0

@warning_ignore("shadowed_variable")
func _init(position: Vector3i, size: int, data_types: PackedInt64Array, data_heights: PackedVector4Array):
	self.position = position
	self.size = size
	self.data_types = data_types
	self.data_heights = data_heights

func get_tile_data_types(x: int, y: int) -> int:
	if x < 0 || x >= self.size || y < 0 || y >= self.size:
		return 0
	
	var index := x + y * self.size
	return self.data_types.get(index)

func get_face_data(face_index: int) -> int:
	var index = face_index * 2
	if index < 0 || index >= self.data_face_lookup.size():
		return 0
	return self.data_face_lookup.decode_s16(index)

func get_tile_data_heights(x: int, y: int) -> Vector4:
	if x < 0 || x >= self.size || y < 0 || y >= self.size:
		return Vector4.ZERO
	
	var index := x + y * self.size
	return self.data_heights[index]

func set_heights(x: int, y: int, heights: Vector4) -> void:
	var index := x + y * self.size;
	self.data_heights[index] = heights
	
	var type := self.data_types[index]
	if type < 0:
		type &= 0x7FFFFFFFFFFFFFFF
	else:
		type |= 1 << 63
	self.data_types[index] = type
	
	self.data_version += 1

func brush_types(local_pos: Vector3, shape: TerrainBrushShape, type: int, type_mask: int) -> void:
	var index := 0
	var has_change := false
	for z in range(self.size):
		for x in range(self.size):
			var types := self.data_types[index]
			var heights := self.data_heights[index]
			var average_height := (heights.x + heights.y + heights.z + heights.w) * 0.25
			
			var center_point := Vector3(x + 0.5, average_height, z + 0.5)
			var diff = shape.evaluate(local_pos, center_point)
			if diff > 0.25:
				var new_type := change_type(types, type, type_mask)
				if new_type != types:
					has_change = true
					self.data_types[index] = new_type
			
			index += 1
	
	if has_change:
		self.data_version += 1

func brush_heights(local_pos: Vector3, shape: TerrainBrushShape, height_scale: float, use_whole_tile: bool) -> void:
	var index := 0
	var has_change := false
	for z in range(self.size):
		for x in range(self.size):
			var heights := self.data_heights[index]
			
			if use_whole_tile:
				var average_height := (heights.x + heights.y + heights.z + heights.w) * 0.25
				var center_point := Vector3(x + 0.5, average_height, z + 0.5)
				var diff = shape.evaluate(local_pos, center_point) * height_scale
				if !is_zero_approx(diff):
					heights.x += diff
					heights.y += diff
					heights.z += diff
					heights.w += diff
					
					self.data_heights[index] = heights
					has_change = true
			else:
				var original_heights := heights
				var height1 := Vector3(x, heights.x, z)
				heights.x += shape.evaluate(local_pos, height1) * height_scale
				
				var height2 := Vector3(x + 1, heights.y, z)
				heights.y += shape.evaluate(local_pos, height2) * height_scale
				
				var height3 := Vector3(x, heights.z, z + 1)
				heights.z += shape.evaluate(local_pos, height3) * height_scale
				
				var height4 := Vector3(x + 1, heights.w, z + 1)
				heights.w += shape.evaluate(local_pos, height4) * height_scale
				
				if heights != original_heights:
					self.data_heights[index] = heights
					has_change = true
				
			index += 1
	
	if has_change:
		self.data_version += 1

@warning_ignore("shadowed_variable")
static func create_type(is_flipped: bool, type1: int, type2: int, cliff_n: int, cliff_e: int, cliff_s: int, cliff_w: int) -> int:
	var flipped_bit = 1 << 63 if is_flipped else 0
	var a = type1 & 0xFF
	var b = (type2 & 0xFF) << 8
	var c = (cliff_n & 0xFF) << 16
	var d = (cliff_e & 0xFF) << 24
	var e = (cliff_s & 0xFF) << 32
	var f = (cliff_w & 0xFF) << 40
	return a | b | c | d | e | f | flipped_bit

static func change_type(original_type: int, type: int, type_mask: int) -> int:
	var flipped_bit = original_type & (1 << 63)
	var type1 := type if type_mask & 0x01 else original_type & 0xFF
	var type2 := type if type_mask & 0x02 else (original_type >> 8) & 0xFF
	var cliff_n := type if type_mask & 0x04 else (original_type >> 16) & 0xFF
	var cliff_e := type if type_mask & 0x08 else (original_type >> 24) & 0xFF
	var cliff_s := type if type_mask & 0x0F else (original_type >> 32) & 0xFF
	var cliff_w := type if type_mask & 0x10 else (original_type >> 40) & 0xFF
	
	return type1 | (type2 << 8) | (cliff_n << 16) | (cliff_e << 24) | (cliff_s << 32) | (cliff_w << 40) | flipped_bit

static func create_face_data(x: int, y: int, face_type: FaceType) -> int:
	var a = x & 0x3F
	var b = (y & 0x3F) << 6
	var c = (int(face_type) & 0x7) << 12
	
	return a | b | c
