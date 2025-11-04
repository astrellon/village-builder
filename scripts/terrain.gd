extends Node3D

const TILE_SIZE: float = 1.0

@export var material: Material
@export var texture_tile_count = Vector2i(8, 4)
@export var texture_tile_size = Vector2i(16, 16)

class TempMesh:
	var verts: PackedVector3Array
	var uvs: PackedVector2Array
	var normals: PackedVector3Array
	var indices: PackedInt32Array
	
	@warning_ignore("shadowed_variable")
	func _init(verts: PackedVector3Array, uvs: PackedVector2Array, normals: PackedVector3Array, indices: PackedInt32Array) -> void:
		self.verts = verts
		self.uvs = uvs
		self.normals = normals
		self.indices = indices

func create_terrain() -> TerrainData:
	const size = 8
	var result: Array[TerrainTileData] = []
	result.resize(size * size)
	
	var index = 0
	for y in range(size):
		for x in range(size):
			var height = x * 0.2 + y
			var type = x % 3
			
			var tile = TerrainTileData.new(int(type), Vector4(height + 0.2, height, height, height + 0.2))
			
			result[index] = tile
			index += 1
	
	return TerrainData.new(size, result)

static func add_indicies(indices: PackedInt32Array, current_index: int, to_add: int) -> int:
	for delta in range(to_add):
		indices.append(current_index + delta)
	
	return current_index + to_add
	
static func append_tri_vec3(list: PackedVector3Array, v1: Vector3, v2: Vector3, v3: Vector3) -> void:
	list.append(v1)
	list.append(v2)
	list.append(v3)

static func append_quad_vec3(list: PackedVector3Array, v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3) -> void:
	list.append(v1)
	list.append(v2)
	list.append(v3)
	
	list.append(v2)
	list.append(v4)
	list.append(v3)

static func append_quad_normals(list: PackedVector3Array, n1: Vector3, n2: Vector3) -> void:
	list.append(n1)
	list.append(n1)
	list.append(n1)
	
	list.append(n2)
	list.append(n2)
	list.append(n2)

static func append_tri_vec2(list: PackedVector2Array, v1: Vector2, v2: Vector2, v3: Vector2) -> void:
	list.append(v1)
	list.append(v2)
	list.append(v3)

static func append_quad_vec2(list: PackedVector2Array, v1: Vector2, v2: Vector2, v3: Vector2, v4: Vector2) -> void:
	list.append(v1)
	list.append(v2)
	list.append(v3)
	
	list.append(v2)
	list.append(v4)
	list.append(v3)
	
static func create_cliff(temp_mesh: TempMesh, tri_index: int, dx: float, dy: float, normal: Vector3, p1: Vector3, p2: Vector3, to_cliff_height_1: float, to_cliff_height_2: float, uv_size: Vector2, uv_x: float) -> int:
	if dx < 0 || dy < 0:
		var b1 = Vector3(p1.x, to_cliff_height_1 * TILE_SIZE, p1.z)
		var b2 = Vector3(p2.x, to_cliff_height_2 * TILE_SIZE, p2.z)
		
		var uv1 = Vector2(uv_x, p1.y * uv_size.y)
		var uv2 = Vector2(uv_x + uv_size.x, p2.y * uv_size.y)
		var uv3 = Vector2(uv_x, b1.y * uv_size.y)
		var uv4 = Vector2(uv_x + uv_size.x, b2.y * uv_size.y)
		
		if dx < 0 && dy < 0:
			append_quad_vec3(temp_mesh.verts, p1, p2, b1, b2)
			append_quad_vec2(temp_mesh.uvs, uv1, uv2, uv3, uv4)
			
			for __ in range(6): temp_mesh.normals.append(normal)
			
			return add_indicies(temp_mesh.indices, tri_index, 6)
		elif dx < 0:
			append_tri_vec3(temp_mesh.verts, p1, p2, b1)
			append_tri_vec2(temp_mesh.uvs, uv1, uv2, uv3)
			
			for __ in range(3): temp_mesh.normals.append(normal)
			
			return add_indicies(temp_mesh.indices, tri_index, 3)
		elif dy < 0:
			append_tri_vec3(temp_mesh.verts, p2, b2, b1)
			append_tri_vec2(temp_mesh.uvs, uv2, uv4, uv3)
			
			for __ in range(3): temp_mesh.normals.append(normal)
			
			return add_indicies(temp_mesh.indices, tri_index, 3)
	
	return tri_index

func _ready() -> void:
	var terrain = create_terrain()
	var rand = FastNoiseLite.new()
	
	var mi = MeshInstance3D.new()
	self.add_child(mi)
	
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	var temp_mesh = TempMesh.new(verts, uvs, normals, indices)
	
	var uv_size = Vector2(1.0 / self.texture_tile_count.x, 1.0 / self.texture_tile_count.y)
	
	var index = 0
	var tri_index = 0
	for y in range(terrain.size):
		var py = y * TILE_SIZE
		
		for x in range(terrain.size):
			var tile = terrain.data[index]
			index += 1
			
			var heights = tile.heights
			var px = x * TILE_SIZE
			
			var p1 = Vector3(px, heights.x * TILE_SIZE, py)
			var p2 = Vector3(px + TILE_SIZE, heights.y * TILE_SIZE, py)
			var p3 = Vector3(px, heights.z * TILE_SIZE, py + TILE_SIZE)
			var p4 = Vector3(px + TILE_SIZE, heights.w * TILE_SIZE, py + TILE_SIZE)
			append_quad_vec3(verts, p1, p2, p3, p4)
			
			var uv_x = float(tile.type % self.texture_tile_count.x) * uv_size.x
			var uv_y = floor(rand.get_noise_2d(x, y) * self.texture_tile_size.y * (self.texture_tile_count.y - 1)) * uv_size.y
			
			var uv1 = Vector2(uv_x, uv_y)
			var uv2 = uv1 + Vector2(uv_size.x, 0)
			var uv3 = uv1 + Vector2(0, uv_size.y)
			var uv4 = uv1 + uv_size
			append_quad_vec2(uvs, uv1, uv2, uv3, uv4)
			
			var normal1 = ((p3 - p2).cross(p2 - p1)).normalized()
			var normal2 = ((p3 - p4).cross(p4 - p2)).normalized()
			append_quad_normals(normals, normal1, normal2)
			
			tri_index = add_indicies(indices, tri_index, 6)
			
			var to_left = terrain.get_tile_data(x - 1, y)
			var to_right = terrain.get_tile_data(x + 1, y)
			var to_up = terrain.get_tile_data(x, y - 1)
			var to_down = terrain.get_tile_data(x, y + 1)
			
			var dx = to_left.heights.y - heights.x
			var dy = to_left.heights.w - heights.z
			tri_index = create_cliff(temp_mesh, tri_index, dx, dy, Vector3.LEFT, p1, p3, to_left.heights.y, to_left.heights.w, uv_size, uv_x)
			
			dx = to_right.heights.z - heights.w
			dy = to_right.heights.x - heights.y
			tri_index = create_cliff(temp_mesh, tri_index, dx, dy, Vector3.RIGHT, p4, p2, to_right.heights.z, to_right.heights.x, uv_size, uv_x)
			
			dx = to_up.heights.w - heights.y
			dy = to_up.heights.z - heights.x
			tri_index = create_cliff(temp_mesh, tri_index, dx, dy, Vector3.BACK, p2, p1, to_up.heights.w, to_up.heights.z, uv_size, uv_x)
			
			dx = to_down.heights.y - heights.x
			dy = to_down.heights.x - heights.y
			tri_index = create_cliff(temp_mesh, tri_index, dx, dy, Vector3.BACK, p3, p4, to_down.heights.y, to_down.heights.x, uv_size, uv_x)
			
			#if dx < 0 || dy < 0:
				#var b1 = Vector3(p1.x, to_left.heights.y * TILE_SIZE, p1.z)
				#var b2 = Vector3(p3.x, to_left.heights.w * TILE_SIZE, p3.z)
				#
				#uv1 = Vector2(uv_x, p1.y * uv_size.y)
				#uv2 = Vector2(uv_x + uv_size.x, p3.y * uv_size.y)
				#uv3 = Vector2(uv_x, b1.y * uv_size.y)
				#uv4 = Vector2(uv_x + uv_size.x, b2.y * uv_size.y)
				#
				#if dx < 0 && dy < 0:
					#append_quad_vec3(verts, p1, p3, b1, b2)
					#append_quad_vec2(uvs, uv1, uv2, uv3, uv4)
					#
					#for __ in range(6): normals.append(Vector3.LEFT)
					#
					#tri_index = add_indicies(indices, tri_index, 6)
				#elif dx < 0:
					#append_tri_vec3(verts, p1, p3, b1)
					#append_tri_vec2(uvs, uv1, uv2, uv3)
					#
					#for __ in range(3): normals.append(Vector3.LEFT)
					#
					#tri_index = add_indicies(indices, tri_index, 3)
				#elif dy < 0:
					#append_tri_vec3(verts, p3, b2, b1)
					#append_tri_vec2(uvs, uv2, uv4, uv3)
					#
					#for __ in range(3): normals.append(Vector3.LEFT)
					#
					#tri_index = add_indicies(indices, tri_index, 3)
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	array_mesh.surface_set_material(0, self.material)
	
	mi.mesh = array_mesh
