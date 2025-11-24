extends Node

class_name TerrainData

var size: int
var chunks: Dictionary[Vector3i, TerrainChunkData] = {}

@warning_ignore("shadowed_variable")
func _init(size: int, chunks: Dictionary[Vector3i, TerrainChunkData]) -> void:
	self.size = size
	self.chunks = chunks
