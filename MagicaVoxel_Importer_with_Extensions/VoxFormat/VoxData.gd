class_name VoxData

var models := {0: VoxModel.new()};
var current_index := -1;
#warning-ignore:unused_class_variable
var colors = null;
#warning-ignore:unused_class_variable
var nodes := {};
#warning-ignore:unused_class_variable
var materials := {};

func get_model()->VoxModel:
	if (!models.has(current_index)):
		models[current_index] = VoxModel.new();
	return models[current_index];
