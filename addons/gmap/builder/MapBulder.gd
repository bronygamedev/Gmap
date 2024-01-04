@tool
extends ScrollContainer

var dropupIcon = load("res://addons/gmap/icons/dropup.svg")
var dropdownIcon = load("res://addons/gmap/icons/dropdown.svg")
var mapInfo:Dictionary
var MapOptions:Dictionary = {
	"is3D":false
}
var editor_fs = EditorInterface.get_resource_filesystem()

@onready var mapName = $VBoxContainer/MapInformation/MapName
@onready var mapAuthor = $VBoxContainer/MapInformation/MapAuthor
@onready var mapVersion = $VBoxContainer/MapInformation/MapVersion
@onready var mapOptionsButton = $VBoxContainer/MapOptions
@onready var mapOptionsContainer = $VBoxContainer/MapOptionsContainer
@onready var maps = $VBoxContainer/HBoxContainer/OptionButton
@onready var res = DirAccess.open("res://")
func _ready():
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("Maps"):
		dir .make_dir_recursive("Maps")
	updateSelector()
	editor_fs.scan()

func _on_map_options_pressed():
	mapOptionsContainer.visible = not mapOptionsContainer.visible
	if mapOptionsContainer.visible:
		mapOptionsButton.icon = dropupIcon
	else :
		mapOptionsButton.icon = dropdownIcon

func _on_3d_map_toggled(toggled_on):
	MapOptions.is3D = toggled_on

func _updateMapInfo():
	mapInfo = {
		"mapname":mapName.text,
		"mapauthor":mapAuthor.text,
		"mapversion":mapVersion.text,
	}

## updates the map selector
func updateSelector():
	maps.clear()
	maps.add_item("[select]")
	var dirs = DirAccess.open("res://Maps/").get_directories()
	for d in dirs:
		var f = FileAccess.open("res://Maps/{0}/map.json".format([d]),FileAccess.READ)
		var jsonData = JSON.parse_string(f.get_as_text())
		maps.add_item(jsonData.mapname)
	

func buildMap():
	_updateMapInfo()
	if mapInfo.mapname == "" or  mapInfo.mapauthor == "" or  mapInfo.mapversion == "":
		printerr("unconfugured")
		return
	print("building map")
	var writer = ZIPPacker.new()
	var files = DirAccess.get_files_at("res://Maps/{mapname}".format(mapInfo))
	var err := writer.open("res://{mapname}.gmap".format(mapInfo))
	if err != OK:
		return err
	for file in files:
		var filepath = "res://Maps/{0}/{1}".format([mapInfo.mapname,file])
		var f = FileAccess.open(filepath,FileAccess.READ)
		if file.ends_with(".tscn"):
			writer.start_file(file.replace(".tscn",".scn"))
			var scene = load(filepath)
			ResourceSaver.save(scene,filepath.replace(".tscn",".scn"))
			writer.write_file(FileAccess.get_file_as_bytes(filepath.replace(".tscn",".scn")))
			res.remove(filepath.replace(".tscn",".scn"))
		else:
			writer.start_file(file)
			writer.write_file(FileAccess.get_file_as_bytes(filepath))
	editor_fs.scan()
	print("done")
	
func creatMap():
	_updateMapInfo()
	if mapInfo.mapname == "" or  mapInfo.mapauthor == "" or  mapInfo.mapversion == "":
		printerr("unconfugured")
		return
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("Maps"):
		dir .make_dir_recursive("Maps")
	dir = DirAccess.open("res://Maps")
	dir.make_dir_recursive(mapInfo.mapname)
	var node = Node3D if MapOptions.is3D else Node2D
	var scene = PackedScene.new()
	var jsonfile = FileAccess.open("res://Maps/{mapname}/map.json".format(mapInfo),FileAccess.WRITE)
	jsonfile.store_string(JSON.stringify(mapInfo,"	"))
	jsonfile.close()
	node = node.new()
	node.name = mapInfo.mapname
	scene.pack(node)
	ResourceSaver.save(scene,"res://Maps/{mapname}/map.tscn".format(mapInfo))
	editor_fs.scan()
	updateSelector()


