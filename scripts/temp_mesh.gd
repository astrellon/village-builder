class_name TempMesh

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
