extends Node

class_name TerrainManager

@export var height_map: Image

@export var noise: FastNoiseLite

var terrain_data: TerrainData
var has_terrain_data = false

func calc_height_at(x: float, y: float) -> float:
	#var heightx = x * 0.5 - 2
	#var heighty = y * 0.5 - 2
	#return clampf(max(heightx, heighty), 0, 1)
	#@warning_ignore("narrowing_conversion")
	#var colour = self.height_map.get_pixel(x * 2, y * 2)
	#return colour.r * 5.0
	return self.noise.get_noise_2d(x, y) * 4.0

func create_terrain_chunk(size: int, position: Vector3i) -> TerrainChunkData:
	var types = PackedInt64Array()
	var heights = PackedFloat32Array()
	types.resize(size * size)
	heights.resize(size * size * 4)

	var index = 0
	for y in range(size):
		var gy = y + position.z * size
		
		for x in range(size):
			var gx = x + position.x * size
			
			var type = int(fmod(x * 100.0, 3.0))

			var height1 = self.calc_height_at(gx, gy) + 3
			var height2 = self.calc_height_at(gx + 1, gy) + 3
			var height3 = self.calc_height_at(gx, gy + 1) + 3
			var height4 = self.calc_height_at(gx + 1, gy + 1) + 3

			var flip_orientation = index % 2 == 0

			var tile_type = TerrainChunkData.create_type(flip_orientation, type, (type + 1) % 3, (type + 2) % 3, (type + 2) % 3, (type + 2) % 3, (type + 2) % 3)

			types[index] = tile_type

			var height_index = index * 4
			heights[height_index] = height1
			heights[height_index + 1] = height2
			heights[height_index + 2] = height3
			heights[height_index + 3] = height4
			index += 1

	return TerrainChunkData.new(position, size, types, heights)

func create_terrain() -> TerrainData:
	const size = 64
	var chunks: Dictionary[Vector3i, TerrainChunkData] = {}
	for x in range(-1, 2):
		for z in range(-1, 2):
			var position := Vector3i(x, 0, z)
			var chunk := self.create_terrain_chunk(size, position)
			chunks[position] = chunk
	
	return TerrainData.new(size, chunks)

func _ready() -> void:
	
	var before_memory = Performance.get_monitor(Performance.MEMORY_STATIC)
	var before = Time.get_ticks_usec()
	self.terrain_data = self.create_terrain()
	var after_memory = Performance.get_monitor(Performance.MEMORY_STATIC)
	var after = Time.get_ticks_usec()
	
	print('Time taken to create: %sms, memory %skb' % [(after - before) / 1000.0, (after_memory - before_memory) / 1000.0])
	self.has_terrain_data = true
