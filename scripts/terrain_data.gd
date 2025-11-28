extends Node

class_name TerrainData

var size: int
var chunks: Dictionary[Vector3i, TerrainChunkData] = {}

@warning_ignore("shadowed_variable")
func _init(size: int, chunks: Dictionary[Vector3i, TerrainChunkData]) -> void:
	self.size = size
	self.chunks = chunks

func brush_types(world_pos: Vector3, shape: TerrainBrushShape, type: int, type_mask: int) -> void:
	var action = func _action(local_pos: Vector3, chunk: TerrainChunkData) -> void:
		chunk.brush_types(local_pos, shape, type, type_mask)
	self._apply_to_chunks(world_pos, shape, action)

func brush_heights(world_pos: Vector3, shape: TerrainBrushShape, height_scale: float, use_whole_tile: bool) -> void:
	var action = func _action(local_pos: Vector3, chunk: TerrainChunkData) -> void:
		chunk.brush_heights(local_pos, shape, height_scale, use_whole_tile)
	self._apply_to_chunks(world_pos, shape, action)

func _apply_to_chunks(world_pos: Vector3, shape: TerrainBrushShape, action: Callable) -> void:
	var shape_size := shape.size()
	if is_zero_approx(shape_size.length()):
		return
	
	var half_size := shape_size * 0.5
	
	var min_chunk_index := self.get_chunk_index(world_pos - half_size)
	var max_chunk_index := self.get_chunk_index(world_pos + half_size)
	
	for z in range(min_chunk_index.z, max_chunk_index.z + 1):
		for y in range(min_chunk_index.y, max_chunk_index.y + 1):
			for x in range(min_chunk_index.x, max_chunk_index.x + 1):
				var chunk_index := Vector3i(x, y, z)
				if !self.chunks.has(chunk_index):
					continue
					
				var chunk_offset := Vector3(chunk_index) * self.size
				var local_pos := world_pos - chunk_offset
				
				var chunk := self.chunks[chunk_index]
				action.call(local_pos, chunk)

func get_chunk_index(world_pos: Vector3) -> Vector3i:
	var chunk_index := world_pos / self.size
	return Vector3i(floori(chunk_index.x), floori(chunk_index.y), floori(chunk_index.z))
