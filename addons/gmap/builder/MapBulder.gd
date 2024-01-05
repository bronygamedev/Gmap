@tool
extends ScrollContainer
class_name gmap_dock

var map:String = "[select]"
var dropupIcon = load("res://addons/gmap/icons/dropup.svg")
var dropdownIcon = load("res://addons/gmap/icons/dropdown.svg")
var editor_fs = EditorInterface.get_resource_filesystem()
var mapInfo:gmapconf = gmapconf.new()
var MapOptions:Dictionary = {
	"is3D":false
}

@onready var mapNameLine = $VBoxContainer/MapInformation/MapName
@onready var mapAutorline = $VBoxContainer/MapInformation/MapAuthor
@onready var mapVersion := [$VBoxContainer/MapInformation/GridContainer/MAJOR,$VBoxContainer/MapInformation/GridContainer/MINOR,$VBoxContainer/MapInformation/GridContainer/PATCH]
@onready var maps = $VBoxContainer/HBoxContainer/OptionButton
@onready var res = DirAccess.open("res://")

func _ready():

	if not res.dir_exists("Maps"):
		res.make_dir_recursive("Maps")
	updateSelector()
	editor_fs.scan()


func _on_map_selected(index):
	map = maps.get_item_text(index)
	if map == "[select]":
		mapAutorline.text = ''
		mapNameLine.text = ''
		mapVersion[0].selected = 0
		mapVersion[1].selected = 0
		mapVersion[2].selected = 0
		return

	mapInfo = load("res://Maps/{0}/map.res".format([map]))
	mapAutorline.text = mapInfo.author
	mapNameLine.text = mapInfo.name
	mapVersion[0].selected = mapInfo.version[0]
	mapVersion[1].selected = mapInfo.version[1]
	mapVersion[2].selected = mapInfo.version[2]
	
	

## updates the map selector
func updateSelector():
	maps.clear()
	maps.add_item("[select]")
	var dirs = DirAccess.open("res://Maps/").get_directories()
	for d in dirs:
		mapInfo = load("res://Maps/{0}/map.res".format([d]))
		maps.add_item(mapInfo.name)
	_on_map_selected(0)

func buildMap():
	if map == "[select]":
		printerr("please select a valid map")
		return
	print("building map")
	var writer = ZIPPacker.new()
	var files = DirAccess.get_files_at("res://Maps/{0}".format([mapInfo.name]))
	var err := writer.open("res://{0}.gmap".format([mapInfo.name]))
	if err != OK:
		return err
	for file in files:
		var filepath = "res://Maps/{0}/{1}".format([mapInfo.name,file])
		var f = FileAccess.open(filepath,FileAccess.READ)
		print(file)
		match file.get_extension():
			"tscn":
				writer.start_file(file.replace(".tscn",".scn"))
				var scene = load(filepath)
				print(scene)
				ResourceSaver.save(scene,filepath.replace(".tscn",".scn"))
				writer.write_file(FileAccess.get_file_as_bytes(filepath.replace(".tscn",".scn")))
				res.remove(filepath.replace(".tscn",".scn"))
			_:
				writer.start_file(file)
				writer.write_file(FileAccess.get_file_as_bytes(filepath))
		writer.close_file()
		f.close()
	editor_fs.scan()
	writer.close()
	print("done")
	
func creatMap():
	if mapNameLine.text == "" or  mapAutorline.text == "":
		printerr("unconfigured")
		return
	mapInfo = gmapconf.new()
	mapInfo.name = mapNameLine.text
	mapInfo.author = mapAutorline.text
	mapInfo.version[0] = mapVersion[0].selected
	mapInfo.version[1] = mapVersion[1].selected
	mapInfo.version[2] = mapVersion[2].selected
	if not res.dir_exists("Maps"):
		res.make_dir_recursive("Maps")
	var dir = DirAccess.open("res://Maps")
	dir.make_dir_recursive(mapInfo.name)
	var node = Node3D if MapOptions.is3D else Node2D
	var scene = PackedScene.new()
	ResourceSaver.save(mapInfo,"res://Maps/{0}/map.res".format([mapInfo.name]),ResourceSaver.FLAG_COMPRESS)
	node = node.new()
	node.name = mapInfo.name
	scene.pack(node)
	ResourceSaver.save(scene,"res://Maps/{0}/map.tscn".format([mapInfo.name]))
	editor_fs.scan()
	updateSelector()
	print("created map " + mapInfo.name)




