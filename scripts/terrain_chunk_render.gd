extends Node3D

class_name TerrainChunkRender

const TILE_SIZE: float = 1.0

@export var material: Material
@export var texture_tile_count = Vector2i(8, 4)
@export var texture_tile_size = Vector2i(16, 16)

var _terrain: TerrainChunkData
var _uv_size: Vector2 = Vector2.ONE

var _static_body: StaticBody3D
var _collision_shape: ConcavePolygonShape3D
var _mesh_instance: MeshInstance3D
var _rendered_data_version: int = -1

func _process(_delta: float) -> void:
	self.rerender_mesh()

func _create_cliff(surface_tool: SurfaceTool, face_index: int, face_lookup: PackedByteArray, x: int, y: int, face_type: TerrainChunkData.FaceType, dx: float, dy: float, p1: Vector3, p2: Vector3, to_cliff_height_1: float, to_cliff_height_2: float, type: int) -> int:
	if dx >= 0 && dy >= 0:
		return face_index

	var uv_x = self._get_uv_x(type)

	var b1 = Vector3(p1.x, to_cliff_height_1 * TILE_SIZE, p1.z)
	var b2 = Vector3(p2.x, to_cliff_height_2 * TILE_SIZE, p2.z)

	var uv1 = Vector2(uv_x, p1.y * self._uv_size.y)
	var uv2 = Vector2(uv_x + self._uv_size.x, p2.y * self._uv_size.y)
	var uv3 = Vector2(uv_x, b1.y * self._uv_size.y)
	var uv4 = Vector2(uv_x + self._uv_size.x, b2.y * self._uv_size.y)

	if dx < 0 && dy < 0:
		_append_quad(surface_tool, p1, uv1, p2, uv2, b1, uv3, b2, uv4)
		face_index = _add_face_lookup(face_lookup, face_index, x, y, face_type, true)
	elif dx < 0:
		_append_tri(surface_tool, p1, uv1, p2, uv2, b1, uv3)
		face_index = _add_face_lookup(face_lookup, face_index, x, y, face_type, false)
	elif dy < 0:
		_append_tri(surface_tool, p2, uv2, b2, uv4, b1, uv3)
		face_index = _add_face_lookup(face_lookup, face_index, x, y, face_type, false)
	
	return face_index

static func _add_face_lookup(face_lookup: PackedByteArray, face_index: int, x: int, y: int, face_type: TerrainChunkData.FaceType, add_two: bool = false) -> int:
	var packed = TerrainChunkData.create_face_data(x, y, face_type)
	if face_index >= face_lookup.size():
		face_lookup.resize(face_lookup.size() + 1024)
	
	face_lookup.encode_s16(face_index, packed)
	if add_two:
		face_lookup.encode_s16(face_index + 2, packed)
		return face_index + 4
	return face_index + 2

static func _set_vertex(surface_tool: SurfaceTool, v: Vector3, uv: Vector2) -> void:
	surface_tool.set_uv(uv)
	surface_tool.set_smooth_group(-1)
	surface_tool.add_vertex(v)

static func _append_tri(surface_tool: SurfaceTool, v1: Vector3, uv1: Vector2, v2: Vector3, uv2: Vector2, v3: Vector3, uv3: Vector2) -> void:
	_set_vertex(surface_tool, v1, uv1)
	_set_vertex(surface_tool, v2, uv2)
	_set_vertex(surface_tool, v3, uv3)

static func _append_quad(surface_tool: SurfaceTool, v1: Vector3, uv1: Vector2, v2: Vector3, uv2: Vector2, v3: Vector3, uv3: Vector2, v4: Vector3, uv4: Vector2) -> void:
	_append_tri(surface_tool, v1, uv1, v2, uv2, v3, uv3)
	_append_tri(surface_tool, v2, uv2, v4, uv4, v3, uv3)

func _get_uv_x(type: int) -> float:
	return float(type % self.texture_tile_count.x) * self._uv_size.x

func create_for_terrain(terrain: TerrainChunkData) -> void:
	self._terrain = terrain
	self._uv_size = Vector2(1.0 / self.texture_tile_count.x, 1.0 / self.texture_tile_count.y)
	
	var face_lookup := PackedByteArray()
	var mesh = self._generate_mesh(face_lookup)
	
	self._collision_shape = ConcavePolygonShape3D.new()
	self._collision_shape.set_faces(mesh.get_faces())
	
	var collision = CollisionShape3D.new()
	collision.shape = self._collision_shape
	
	self._mesh_instance = MeshInstance3D.new()
	self._mesh_instance.mesh = mesh
	self._mesh_instance.material_override = self.material
	
	self._static_body = StaticBody3D.new()
	self._static_body.add_child(collision)
	self._static_body.add_child(self._mesh_instance)
	
	terrain.data_face_lookup = face_lookup
	self.add_child(self._static_body)
	
	self._rendered_data_version = terrain.data_version

func rerender_mesh() -> void:
	if self._rendered_data_version == self._terrain.data_version:
		return
		
	var face_lookup = self._terrain.data_face_lookup
	var before = Time.get_ticks_usec()
	var mesh = self._generate_mesh(face_lookup)
	var after = Time.get_ticks_usec()
	Output.print('Time to generate mesh: %sus' % (after - before))
	
	self._collision_shape.set_faces(mesh.get_faces())
	self._mesh_instance.mesh = mesh
	
	self._rendered_data_version = self._terrain.data_version

func _generate_mesh(face_lookup: PackedByteArray) -> Mesh:
	var face_lookup_size = self._terrain.size * self._terrain.size * (2 + 1)
	if face_lookup.size() < face_lookup_size:
		face_lookup.resize(face_lookup_size)
	var face_index = 0

	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var uv_tl := Vector2.ZERO
	var uv_tr := Vector2.ZERO
	var uv_bl := Vector2.ZERO
	var uv_br := Vector2.ZERO
	
	for y in range(self._terrain.size):
		var py := y * TILE_SIZE

		for x in range(self._terrain.size):
			var tile := self._terrain.get_tile_data_types(x, y)

			var is_flipped = tile < 0
			var type1 := tile & 0xFF
			var type2 := (tile >> 8) & 0xFF
			var cliff_n := (tile >> 16) & 0xFF
			var cliff_e := (tile >> 24) & 0xFF
			var cliff_s := (tile >> 32) & 0xFF
			var cliff_w := (tile >> 40) & 0xFF

			var heights := self._terrain.get_tile_data_heights(x, y)
			var px := x * TILE_SIZE

			var uv_x1 := self._get_uv_x(type1)
			var uv_x2 := self._get_uv_x(type2)
			#var uv_y := floorf(rand.get_noise_2d(x, y) * self.texture_tile_size.y * (self.texture_tile_count.y - 1)) * self._uv_size.y
			#var uv_y := floorf(rand.get_noise_2d(x, y) * self.texture_tile_size.y * (self.texture_tile_count.y - 1)) * self._uv_size.y
			const uv_y = 0.0

			var p_tl := Vector3(px, heights.x * TILE_SIZE, py)
			var p_tr := Vector3(px + TILE_SIZE, heights.y * TILE_SIZE, py)
			var p_bl := Vector3(px, heights.z * TILE_SIZE, py + TILE_SIZE)
			var p_br := Vector3(px + TILE_SIZE, heights.w * TILE_SIZE, py + TILE_SIZE)

			if is_flipped:
				uv_tl = Vector2(uv_x1, uv_y)
				uv_br = Vector2(uv_x1 + self._uv_size.x, uv_y + self._uv_size.y)
				uv_bl = Vector2(uv_x1, uv_y + self._uv_size.y)
				_append_tri(surface_tool, p_tl, uv_tl, p_br, uv_br, p_bl, uv_bl)
				face_index = _add_face_lookup(face_lookup, face_index, x, y, TerrainChunkData.FaceType.TYPE1)

				uv_tl = Vector2(uv_x2, uv_y)
				uv_tr = Vector2(uv_x2 + self._uv_size.x, uv_y)
				uv_br = Vector2(uv_x2 + self._uv_size.x, uv_y + self._uv_size.y)
				_append_tri(surface_tool, p_tl, uv_tl, p_tr, uv_tr, p_br, uv_br)
				face_index = _add_face_lookup(face_lookup, face_index, x, y, TerrainChunkData.FaceType.TYPE2)
			else:
				uv_tl = Vector2(uv_x1, uv_y)
				uv_tr = Vector2(uv_x1 + self._uv_size.x, uv_y)
				uv_bl = Vector2(uv_x1, uv_y + self._uv_size.y)
				_append_tri(surface_tool, p_tl, uv_tl, p_tr, uv_tr, p_bl, uv_bl)
				face_index = _add_face_lookup(face_lookup, face_index, x, y, TerrainChunkData.FaceType.TYPE1)

				uv_tr = Vector2(uv_x2 + self._uv_size.x, uv_y)
				uv_br = Vector2(uv_x2 + self._uv_size.x, uv_y + self._uv_size.y)
				uv_bl = Vector2(uv_x2, uv_y + self._uv_size.y)
				_append_tri(surface_tool, p_tr, uv_tr, p_br, uv_br, p_bl, uv_bl)
				face_index = _add_face_lookup(face_lookup, face_index, x, y, TerrainChunkData.FaceType.TYPE2)

			var to_left := self._terrain.get_tile_data_heights(x - 1, y)
			var to_right := self._terrain.get_tile_data_heights(x + 1, y)
			var to_up := self._terrain.get_tile_data_heights(x, y - 1)
			var to_down := self._terrain.get_tile_data_heights(x, y + 1)

			var dx = to_left.y - heights.x
			var dy = to_left.w - heights.z
			face_index = self._create_cliff(surface_tool, face_index, face_lookup, x, y, TerrainChunkData.FaceType.CLIFF_WEST, dx, dy, p_tl, p_bl, to_left.y, to_left.w, cliff_w)

			dx = to_right.z - heights.w
			dy = to_right.x - heights.y
			face_index = self._create_cliff(surface_tool, face_index, face_lookup, x, y, TerrainChunkData.FaceType.CLIFF_EAST, dx, dy, p_br, p_tr, to_right.z, to_right.x, cliff_e)

			dx = to_up.w - heights.y
			dy = to_up.z - heights.x
			face_index = self._create_cliff(surface_tool, face_index, face_lookup, x, y, TerrainChunkData.FaceType.CLIFF_NORTH, dx, dy, p_tr, p_tl, to_up.w, to_up.z, cliff_n)

			dx = to_down.x - heights.z
			dy = to_down.y - heights.w
			face_index = self._create_cliff(surface_tool, face_index, face_lookup, x, y, TerrainChunkData.FaceType.CLIFF_SOUTH, dx, dy, p_bl, p_br, to_down.x, to_down.y, cliff_s)

	print('Created terrain, num faces: %s' % face_index)
	
	surface_tool.generate_normals()
	return surface_tool.commit()
