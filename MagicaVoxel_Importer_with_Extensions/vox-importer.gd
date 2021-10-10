tool
extends EditorImportPlugin

func _init():
	print('MagicaVoxel Importer: Ready')

func get_importer_name():
	return 'MagicaVoxel.With.Extensions'

func get_visible_name():
	return 'MagicaVoxel Mesh'

func get_recognized_extensions():
	return [ 'vox' ]

func get_resource_type():
	return 'Mesh'

func get_save_extension():
	return 'mesh'

func get_preset_count():
	return 0

func get_preset_name(_preset):
	return 'Default'

func get_import_options(_preset):
	return [
		{
			'name': 'Scale',
			'default_value': 0.1
		},
		{
			'name': 'GreedyMeshGenerator',
			'default_value': true
		},
		{
			'name': 'SnapToGround',
			'default_value': false
		}
	]

func get_option_visibility(_option, _options):
	return true

func import(source_path, destination_path, options, _platforms, _gen_files):
	var mesh = VoxImporter.import_mesh(source_path,options)
	var full_path = "%s.%s" % [ destination_path, get_save_extension() ]
	return ResourceSaver.save(full_path, mesh)
