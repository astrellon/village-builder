extends Node

class_name TerrainData

var size: int
var chunks: Dictionary[Vector3i, TerrainChunkData] = {}

@warning_ignore("shadowed_variable")
func _init(size: int, chunks: Dictionary[Vector3i, TerrainChunkData]) -> void:
	self.size = size
	self.chunks = chunks
	
func brush_flat(world_pos: Vector3, height: float) -> void:
	var chunk_index := self.get_chunk_index(world_pos)
	if !self.chunks.has(chunk_index):
		return
	
	var chunk_offset := chunk_index * self.size
	
	var local_position_x := floori(world_pos.x) - chunk_offset.x
	var local_position_y := floori(world_pos.z) - chunk_offset.y
	
	var chunk := self.chunks[chunk_index]
	chunk.set_heights(local_position_x, local_position_y, Vector4.ONE * height)

func get_chunk_index(world_pos: Vector3) -> Vector3i:
	var chunk_index := world_pos / self.size
	return Vector3i(floori(chunk_index.x), floori(chunk_index.y), floori(chunk_index.z))
