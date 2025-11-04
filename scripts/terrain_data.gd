class_name TerrainData

var size: int
var data: Array[TerrainTileData]

@warning_ignore("shadowed_variable")
func _init(size: int, data: Array[TerrainTileData]):
	self.size = size
	self.data = data

func get_tile_data(x: int, y: int) -> TerrainTileData:
	if x < 0 || x >= self.size || y < 0 || y >= self.size:
		return TerrainTileData.EMPTY
	
	return self.data[x + y * self.size]
