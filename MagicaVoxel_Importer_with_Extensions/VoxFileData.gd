class_name VoxFileData


var chunk_size := 0
var data_buffer := DataBuffer.new()

class DataBuffer:
	var data: Array
	var pos:=0
	
	func _init(new_data=data,new_pos=pos):
		data=new_data
		pos=new_pos
		
	func get_size()->int:
		return data.size()
	
	func get_position()->int:
		return pos
	
	func get_8()->int:
		pos+=1
		return data[pos-1]
	
	func get_16()->int:

		var a = get_8()
		var b = get_8()

		var res = b
		res <<= 8
		res |= a

		return res
	
	func get_32()->int:
		var a = get_16()
		var b = get_16()

		var res = b
		res <<= 16
		res |= a
		return res
	
	func get_buffer(length)->PackedByteArray:
		pos+=length
		return PackedByteArray(data.slice(pos-length,pos-1))

func _init(new_data: DataBuffer):
	data_buffer = new_data
	chunk_size = 0

func has_data_to_read()->bool:
	return data_buffer.get_position() < data_buffer.get_size()

func set_chunk_size(size):
	chunk_size = size

func get_8()->int:
	chunk_size -= 1
	return data_buffer.get_8()
	
func get_32()->int: 
	chunk_size -= 4;
	return data_buffer.get_32()
	
func get_buffer(length:int)->PackedByteArray:
	chunk_size -= length
	return data_buffer.get_buffer(length)

func read_remaining():
	get_buffer(chunk_size)
	chunk_size = 0

func get_string(length:int)->String:
	return get_buffer(length).get_string_from_ascii()

func get_vox_string()->String:
	var length = get_32()
	return get_string(length)

func get_vox_dict()->Dictionary:
	var result = {}
	var pairs = get_32()
	for _p in range(pairs):
		var key = get_vox_string()
		var value = get_vox_string()
		result[key] = value
	return result
