extends SceneTree

func _initialize() -> void:
	var packer := PCKPacker.new()
	print("PCKPacker methods:")
	for m in packer.get_method_list():
		print("  %s" % m.name)
	quit(0)
