extends Node3D

class_name TerrainRender

@export var material: Material
@export var texture_tile_count = Vector2i(8, 4)
@export var texture_tile_size = Vector2i(16, 16)
@export var terrain_manager: TerrainManager

var _rendered_terrain = false
var _chunks: Dictionary[Vector3i, TerrainChunkRender] = {}

func _process(_delta: float) -> void:
	if self._rendered_terrain || self.terrain_manager == null || !self.terrain_manager.has_terrain_data:
		return

	self._render_terrain(self.terrain_manager.terrain_data)
	self._rendered_terrain = true

func _render_terrain(terrain_data: TerrainData) -> void:
	for pos in terrain_data.chunks:
		var chunk_data = terrain_data.chunks[pos]
		var chunk_render = self._render_terrain_chunk(chunk_data)
		self._chunks[pos] = chunk_render
	
func _render_terrain_chunk(terrain_chunk_data: TerrainChunkData) -> TerrainChunkRender:
	var pos = terrain_chunk_data.position
	var render = TerrainChunkRender.new()
	render.position = Vector3(pos.x * terrain_chunk_data.size, pos.y * terrain_chunk_data.size, pos.z * terrain_chunk_data.size)
	
	render.material = self.material
	render.texture_tile_count = self.texture_tile_count
	render.texture_tile_size = self.texture_tile_size
	
	self.add_child(render)
	render.create_for_terrain(terrain_chunk_data)
	return render
