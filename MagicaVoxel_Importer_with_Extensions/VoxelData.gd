class_name VoxelData

var data = {};

func combine(model):
	var offset = (model.size / 2.0).floor();
	for voxel in model.voxels:
		data[voxel - offset] = model.voxels[voxel];

func combine_data(other):
	for voxel in other.data:
		data[voxel] = other.data[voxel];

func rotate(basis: Basis):
	var new_data = {};
	for voxel in data:
		var half_step = Vector3(0.5, 0.5, 0.5);
		var new_voxel = (basis.xform(voxel+half_step)-half_step).floor();
		new_data[new_voxel] = data[voxel];
	data = new_data;

func translate(translation: Vector3):
	var new_data = {};
	for voxel in data:
		var new_voxel = voxel + translation;
		new_data[new_voxel] = data[voxel];
	data = new_data;
