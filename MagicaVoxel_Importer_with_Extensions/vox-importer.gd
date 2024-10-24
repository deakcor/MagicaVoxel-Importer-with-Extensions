@tool
extends EditorImportPlugin

func _init():
	print('MagicaVoxel Importer: Ready')

func _get_importer_name():
	return 'MagicaVoxel.With.Extensions'

func _get_visible_name():
	return 'MagicaVoxel Mesh'

func _get_recognized_extensions():
	return [ 'vox' ]

func _get_resource_type():
	return 'Mesh'

func _get_save_extension():
	return 'mesh'

func _get_preset_count():
	return 0

func _get_preset_name(_preset):
	return 'Default'

func _get_import_options(_preset):
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

func _get_option_visibility(_option, _options):
	return true

func import(source_path, destination_path, options, _platforms, _gen_files):
	var mesh = VoxImporter.import_mesh(source_path,options)
	var full_path = "%s.%s" % [ destination_path, _get_save_extension() ]
	return ResourceSaver.save(full_path, mesh)
