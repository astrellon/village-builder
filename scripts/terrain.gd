extends Node3D

const TILE_SIZE: float = 1.0

@export var material: Material
@export var texture_tile_count = Vector2i(8, 4)
@export var texture_tile_size = Vector2i(16, 16)
@export var height_map: Image

@export var noise: FastNoiseLite

var rand = FastNoiseLite.new()
var _uv_size: Vector2 = Vector2.ONE

func calc_height_at(x: float, y: float) -> float:
	#var heightx = x * 0.5 - 2
	#var heighty = y * 0.5 - 2
	#return clampf(max(heightx, heighty), 0, 1)
	#@warning_ignore("narrowing_conversion")
	#var colour = self.height_map.get_pixel(x * 2, y * 2)
	#return colour.r * 5.0
	return self.noise.get_noise_2d(x, y) * 4.0

func create_terrain() -> TerrainData:
	const size = 64
	var types = PackedInt64Array()
	var heights = PackedFloat32Array()
	types.resize(size * size)
	heights.resize(size * size * 4)

	var index = 0
	for y in range(size):
		for x in range(size):
			#var n = (rand.get_noise_2d(x * 10, y * 10) + 1.0) / 2.0
			#var base_height = n * 4.0
			var type = int(fmod(x * 100.0, 3.0))

			#var height1 = base_height
			#var height2 = base_height + rand.get_noise_2d(x + 0.5, y)
			#var height3 = base_height + rand.get_noise_2d(x, y + 0.5)
			#var height4 = base_height + rand.get_noise_2d(x + 0.5, y + 0.5)
			var height1 = self.calc_height_at(x, y) + 3
			var height2 = self.calc_height_at(x + 1, y) + 3
			var height3 = self.calc_height_at(x, y + 1) + 3
			var height4 = self.calc_height_at(x + 1, y + 1) + 3

			var flip_orientation = index % 2 == 0

			#var heights = Vector4(height1, height2, height3, height4)

			var tile_type = TerrainData.create_type(flip_orientation, type, (type + 1) % 3, (type + 2) % 3, (type + 2) % 3, (type + 2) % 3, (type + 2) % 3)

			types[index] = tile_type

			var height_index = index * 4
			heights[height_index] = height1
			heights[height_index + 1] = height2
			heights[height_index + 2] = height3
			heights[height_index + 3] = height4
			index += 1

	return TerrainData.new(size, types, heights)

func create_cliff(surface_tool: SurfaceTool, dx: float, dy: float, p1: Vector3, p2: Vector3, to_cliff_height_1: float, to_cliff_height_2: float, type: int) -> void:
	if dx >= 0 && dy >= 0:
		return

	var uv_x = self._get_uv_x(type)

	var b1 = Vector3(p1.x, to_cliff_height_1 * TILE_SIZE, p1.z)
	var b2 = Vector3(p2.x, to_cliff_height_2 * TILE_SIZE, p2.z)

	var uv1 = Vector2(uv_x, p1.y * self._uv_size.y)
	var uv2 = Vector2(uv_x + self._uv_size.x, p2.y * self._uv_size.y)
	var uv3 = Vector2(uv_x, b1.y * self._uv_size.y)
	var uv4 = Vector2(uv_x + self._uv_size.x, b2.y * self._uv_size.y)

	if dx < 0 && dy < 0:
		append_quad(surface_tool, p1, uv1, p2, uv2, b1, uv3, b2, uv4)

	elif dx < 0:
		append_tri(surface_tool, p1, uv1, p2, uv2, b1, uv3)
	elif dy < 0:
		append_tri(surface_tool, p2, uv2, b2, uv4, b1, uv3)

static func set_vertex(surface_tool: SurfaceTool, v: Vector3, uv: Vector2) -> void:
	surface_tool.set_uv(uv)
	surface_tool.set_smooth_group(-1)
	surface_tool.add_vertex(v)

static func append_tri(surface_tool: SurfaceTool, v1: Vector3, uv1: Vector2, v2: Vector3, uv2: Vector2, v3: Vector3, uv3: Vector2) -> void:
	set_vertex(surface_tool, v1, uv1)
	set_vertex(surface_tool, v2, uv2)
	set_vertex(surface_tool, v3, uv3)

static func append_quad(surface_tool: SurfaceTool, v1: Vector3, uv1: Vector2, v2: Vector3, uv2: Vector2, v3: Vector3, uv3: Vector2, v4: Vector3, uv4: Vector2) -> void:
	append_tri(surface_tool, v1, uv1, v2, uv2, v3, uv3)
	append_tri(surface_tool, v2, uv2, v4, uv4, v3, uv3)

func _get_uv_x(type: int) -> float:
	return float(type % self.texture_tile_count.x) * self._uv_size.x

func _ready() -> void:

	var before_mem = Performance.get_monitor(Performance.MEMORY_STATIC)
	var before_time = Time.get_ticks_usec()
	var terrain = create_terrain()
	var after_mem = Performance.get_monitor(Performance.MEMORY_STATIC)
	var after_time = Time.get_ticks_usec()

	print("Time taken: %sus, memory before: %d, memory after: %d, memory diff: %d" % [(after_time - before_time), before_mem, after_mem, (after_mem - before_mem)])

	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var mi = MeshInstance3D.new()
	self.add_child(mi)

	self._uv_size = Vector2(1.0 / self.texture_tile_count.x, 1.0 / self.texture_tile_count.y)

	var uv_tl := Vector2.ZERO
	var uv_tr := Vector2.ZERO
	var uv_bl := Vector2.ZERO
	var uv_br := Vector2.ZERO

	for y in range(terrain.size):
		var py := y * TILE_SIZE

		for x in range(terrain.size):
			var tile := terrain.get_tile_data_types(x, y)

			var is_flipped = tile < 0
			var type1 := tile & 0xFF
			var type2 := (tile >> 8) & 0xFF
			var cliff_n := (tile >> 16) & 0xFF
			var cliff_e := (tile >> 24) & 0xFF
			var cliff_s := (tile >> 32) & 0xFF
			var cliff_w := (tile >> 40) & 0xFF

			var heights := terrain.get_tile_data_heights(x, y)
			var px := x * TILE_SIZE

			var uv_x1 := self._get_uv_x(type1)
			var uv_x2 := self._get_uv_x(type2)
			var uv_y := floorf(rand.get_noise_2d(x, y) * self.texture_tile_size.y * (self.texture_tile_count.y - 1)) * self._uv_size.y

			var p_tl := Vector3(px, heights.x * TILE_SIZE, py)
			var p_tr := Vector3(px + TILE_SIZE, heights.y * TILE_SIZE, py)
			var p_bl := Vector3(px, heights.z * TILE_SIZE, py + TILE_SIZE)
			var p_br := Vector3(px + TILE_SIZE, heights.w * TILE_SIZE, py + TILE_SIZE)

			if is_flipped:
				uv_tl = Vector2(uv_x1, uv_y)
				uv_br = Vector2(uv_x1 + self._uv_size.x, uv_y + self._uv_size.y)
				uv_bl = Vector2(uv_x1, uv_y + self._uv_size.y)
				append_tri(surface_tool, p_tl, uv_tl, p_br, uv_br, p_bl, uv_bl)

				uv_tl = Vector2(uv_x2, uv_y)
				uv_tr = Vector2(uv_x2 + self._uv_size.x, uv_y)
				uv_br = Vector2(uv_x2 + self._uv_size.x, uv_y + self._uv_size.y)
				append_tri(surface_tool, p_tl, uv_tl, p_tr, uv_tr, p_br, uv_br)
			else:
				uv_tl = Vector2(uv_x1, uv_y)
				uv_tr = Vector2(uv_x1 + self._uv_size.x, uv_y)
				uv_bl = Vector2(uv_x1, uv_y + self._uv_size.y)
				append_tri(surface_tool, p_tl, uv_tl, p_tr, uv_tr, p_bl, uv_bl)

				uv_tr = Vector2(uv_x2 + self._uv_size.x, uv_y)
				uv_br = Vector2(uv_x2 + self._uv_size.x, uv_y + self._uv_size.y)
				uv_bl = Vector2(uv_x2, uv_y + self._uv_size.y)
				append_tri(surface_tool, p_tr, uv_tr, p_br, uv_br, p_bl, uv_bl)

			var to_left := terrain.get_tile_data_heights(x - 1, y)
			var to_right := terrain.get_tile_data_heights(x + 1, y)
			var to_up := terrain.get_tile_data_heights(x, y - 1)
			var to_down := terrain.get_tile_data_heights(x, y + 1)

			var dx = to_left.y - heights.x
			var dy = to_left.w - heights.z
			self.create_cliff(surface_tool, dx, dy, p_tl, p_bl, to_left.y, to_left.w, cliff_w)

			dx = to_right.z - heights.w
			dy = to_right.x - heights.y
			self.create_cliff(surface_tool, dx, dy, p_br, p_tr, to_right.z, to_right.x, cliff_e)

			dx = to_up.w - heights.y
			dy = to_up.z - heights.x
			self.create_cliff(surface_tool, dx, dy, p_tr, p_tl, to_up.w, to_up.z, cliff_n)

			dx = to_down.x - heights.z
			dy = to_down.y - heights.w
			self.create_cliff(surface_tool, dx, dy, p_bl, p_br, to_down.x, to_down.y, cliff_s)

	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	mi.mesh = mesh
	mi.mesh.surface_set_material(0, self.material)
