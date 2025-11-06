class_name TerrainTileData

static var EMPTY = TerrainTileData.new(-1, false, Vector4.ZERO)

var type: int
var flip_orientation: bool
var heights: Vector4

@warning_ignore("shadowed_variable")
func _init(type: int, flip_orientation: bool, heights: Vector4):
	self.type = type
	self.flip_orientation = flip_orientation
	self.heights = heights
