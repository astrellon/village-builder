class_name TerrainTileData

static var EMPTY = TerrainTileData.new(-1, Vector4.ZERO)

var type: int
var heights: Vector4

@warning_ignore("shadowed_variable")
func _init(type: int, heights: Vector4):
	self.type = type
	self.heights = heights
