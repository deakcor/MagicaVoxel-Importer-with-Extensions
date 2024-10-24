class_name VoxNode

var id: int;
var attributes = {};
var child_nodes = [];
var models = [];
var position = Vector3(0, 0, 0);
var rotation = Basis();

func _init(id, attributes):
	self.id = id;
	self.attributes = attributes;
