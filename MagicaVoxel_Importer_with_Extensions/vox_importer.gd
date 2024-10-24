class_name VoxImporter

const debug_file = false
const debug_models = false

static func import_mesh_from_data(data:PackedByteArray,options={})->Mesh:
	var vox:VoxData = import_vox_from_data(data)
	var mesh = create_mesh(vox,options)
	return mesh

static func import_mesh(path,options={})->Mesh:
	var vox:VoxData = import_vox(path)
	
	var mesh = create_mesh(vox,options)
	return mesh

static func load_materials_from_data(data:PackedByteArray)->Dictionary:
	var vox:VoxData = import_vox_from_data(data)
	var voxel_data:Dictionary = unify_voxels(vox).data
	var mats:={}
	for k in voxel_data.keys():
		var surface_index = voxel_data[voxel_data]
		mats[surface_index]=vox.materials[surface_index]
	return mats

static func create_mesh(vox:VoxData,options={})->Mesh:
	var voxel_data:Dictionary = unify_voxels(vox).data
	var scale := 0.1
	if options.has("Scale"):
		scale = float(options.Scale)
	var greedy := true
	if options.has("GreedyMeshGenerator"):
		greedy = bool(options.GreedyMeshGenerator)
	var snaptoground := false
	if options.has("SnapToGround"):
		snaptoground = bool(options.SnapToGround)
	var mesh:Mesh
	if greedy:
		mesh = GreedyMeshGenerator.new().generate(vox, voxel_data, scale, snaptoground)
	else:
		mesh = CulledMeshGenerator.new().generate(vox, voxel_data, scale, snaptoground)
	return mesh

static func get_data(path:String)->PackedByteArray:
	var file := FileAccess.open(path, FileAccess.READ)
	if file.get_open_error() != OK:
		if file.is_open(): file.close()
		return PackedByteArray()
	
	return file.get_buffer(file.get_length())

static func import_vox(path:String)->VoxData:
	var data:PackedByteArray=get_data(path)
	return import_vox_from_data(data)

static func import_vox_from_data(data:PackedByteArray)->VoxData:
	var data_buffer = VoxFileData.DataBuffer.new(data)
	var vox_file_data = VoxFileData.new(data_buffer)
	var res:=[]
	for k in 4:
		res.push_back(vox_file_data.get_8())
	var version = vox_file_data.get_32()
	var identifier = PackedByteArray(res).get_string_from_ascii()
	var vox = VoxData.new()
	if identifier == 'VOX ':
		while vox_file_data.has_data_to_read():
			read_chunk(vox, vox_file_data)
	return vox

static func unify_voxels(vox: VoxData)->VoxelData:
	var node = vox.nodes[0] if vox.nodes.has(0) else null
	return get_voxels(node, vox)

static func read_chunk(vox: VoxData, file_data):
	var chunk_id = file_data.get_string(4)
	var chunk_size = file_data.get_32()
	#warning-ignore:unused_variable
	var childChunks = file_data.get_32()

	file_data.set_chunk_size(chunk_size)
	match chunk_id:
		'SIZE':
			vox.current_index += 1
			var model = vox.get_model()
			var x = file_data.get_32()
			var y = file_data.get_32()
			var z = file_data.get_32()
			model.size = Vector3(x, y, z)
			if debug_file: print('SIZE ', model.size)
		'XYZI':
			var model = vox.get_model()
			if debug_file: print('XYZI')
			for _i in range(file_data.get_32()):
				var x = file_data.get_8()
				var y = file_data.get_8()
				var z = file_data.get_8()
				var c = file_data.get_8()
				var voxel = Vector3(x, y, z)
				model.voxels[voxel] = c - 1
				if debug_file && debug_models: print('\t', voxel, ' ', c-1)
		'RGBA':
			vox.colors = []
			for _i in range(256):
				var r = float(file_data.get_8() / 255.0)
				var g = float(file_data.get_8() / 255.0)
				var b = float(file_data.get_8() / 255.0)
				var a = float(file_data.get_8() / 255.0)
				vox.colors.append(Color(r, g, b, a))
		'nTRN':
			var node_id = file_data.get_32()
			var attributes = file_data.get_vox_dict()
			var node = VoxNode.new(node_id, attributes)
			vox.nodes[node_id] = node

			var child = file_data.get_32()
			node.child_nodes.append(child)

			file_data.get_buffer(8)
			var num_of_frames = file_data.get_32()

			if debug_file:
				print('nTRN[', node_id, '] -> ', child)
				if (!attributes.is_empty()): print('\t', attributes)
			for _frame in range(num_of_frames):
				var frame_attributes = file_data.get_vox_dict()
				if (frame_attributes.has('_t')):
					var trans = frame_attributes['_t']
					node.position = string_to_vector3(trans)
					if debug_file: print('\tT: ', node.position)
				if (frame_attributes.has('_r')):
					var rot = frame_attributes['_r']
					node.rotation = byte_to_basis(int(rot))
					if debug_file: print('\tR: ', node.rotation)
		'nGRP':
			var node_id = file_data.get_32()
			var attributes = file_data.get_vox_dict()
			var node = VoxNode.new(node_id, attributes)
			vox.nodes[node_id] = node

			var num_children = file_data.get_32()
			for _c in num_children:
				node.child_nodes.append(file_data.get_32())
			if debug_file:
				print('nGRP[', node_id, '] -> ', node.child_nodes)
				if (!attributes.is_empty()): print('\t', attributes)
		'nSHP':
			var node_id = file_data.get_32()
			var attributes = file_data.get_vox_dict()
			var node = VoxNode.new(node_id, attributes)
			vox.nodes[node_id] = node

			var num_models = file_data.get_32()
			for _i in range(num_models):
				node.models.append(file_data.get_32())
				file_data.get_vox_dict()
			if debug_file:
				print('nSHP[', node_id,'] -> ', node.models)
				if (!attributes.is_empty()): print('\t', attributes)
		'MATL':
			var material_id = file_data.get_32() - 1
			var properties = file_data.get_vox_dict()
			vox.materials[material_id] = VoxMaterial.new(properties)
			if debug_file:
				print("MATL ", material_id)
				print("\t", properties)
		_:
			if debug_file: print(chunk_id)
	file_data.read_remaining()


static func get_voxels(node: VoxNode, vox: VoxData)->VoxelData:
	var data:VoxelData = VoxelData.new()
	if node:
		for model_index in node.models:
			var model = vox.models[model_index]
			data.combine(model)
		for child_index in node.child_nodes:
			var child = vox.nodes[child_index]
			var child_data = get_voxels(child, vox)
			data.combine_data(child_data)
		data.rotate(node.rotation.inverse())
		data.translate(node.position)
	return data


static func string_to_vector3(input: String) -> Vector3:
	var data = input.split_floats(' ')
	return Vector3(data[0], data[1], data[2])


static func byte_to_basis(data: int):
	var x_ind = ((data >> 0) & 0x03)
	var y_ind = ((data >> 2) & 0x03)
	var indexes = [0, 1, 2]
	indexes.erase(x_ind)
	indexes.erase(y_ind)
	var z_ind = indexes[0]
	var x_sign = 1 if ((data >> 4) & 0x01) == 0 else -1
	var y_sign = 1 if ((data >> 5) & 0x01) == 0 else -1
	var z_sign = 1 if ((data >> 6) & 0x01) == 0 else -1
	var result = Basis()
	result.x[0] = x_sign if x_ind == 0 else 0
	result.x[1] = x_sign if x_ind == 1 else 0
	result.x[2] = x_sign if x_ind == 2 else 0

	result.y[0] = y_sign if y_ind == 0 else 0
	result.y[1] = y_sign if y_ind == 1 else 0
	result.y[2] = y_sign if y_ind == 2 else 0

	result.z[0] = z_sign if z_ind == 0 else 0
	result.z[1] = z_sign if z_ind == 1 else 0
	result.z[2] = z_sign if z_ind == 2 else 0
	return result
