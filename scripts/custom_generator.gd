extends VoxelGeneratorScript

class_name CustomGenerator

@export var noise: FastNoiseLite

func _get_used_channels_mask() -> int:
	return 1 << VoxelBuffer.CHANNEL_SDF

func _generate_block(out_buffer: VoxelBuffer, origin_in_voxels: Vector3i, lod: int) -> void:
	var bs = out_buffer.get_size()
	
	for z in bs.z:
		for x in bs.x:
			for y in bs.y:
				var position = Vector3(origin_in_voxels) + Vector3(x << lod, y << lod, z << lod)
				var n = self.noise.get_noise_3d(position.x, position.y, position.z) + position.y * 0.05
				var value = -1 if n < 0 else 1
				out_buffer.set_voxel_f(value, x, y, z, VoxelBuffer.CHANNEL_SDF)
