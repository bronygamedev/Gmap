extends Node
class_name gmap

func loadmap(path:String,installdir = "user://Maps"):
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("Maps"):
		dir .make_dir_recursive("Maps")
	print("loading map")
	var reader := ZIPReader.new()
	var err := reader.open(path)
	if err != OK:
		return "file not found"
	var gmconftmp = FileAccess.open("user://gmconftmp.res",FileAccess.WRITE)
	gmconftmp.store_buffer(reader.read_file('map.res'))
	gmconftmp.close()
	var mapinfo:gmapconf = load("user://gmconftmp.res")
	dir.make_dir("Maps/{0}".format([mapinfo.name]))
	for file in reader.get_files():
		var f = FileAccess.open(installdir + "/{0}/{1}".format([mapinfo.name,file]),FileAccess.WRITE_READ)
		f.store_buffer(reader.read_file(file))
	print("map installed")
