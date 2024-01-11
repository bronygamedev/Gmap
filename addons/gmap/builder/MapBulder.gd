@tool
extends ScrollContainer
class_name gmap_dock

var templates:Maps
var templatesNames:Array[String]
var selectedTemplate
var template:PackedByteArray
var map:String = "[select]"
var dropupIcon = load("res://addons/gmap/icons/dropup.svg")
var dropdownIcon = load("res://addons/gmap/icons/dropdown.svg")
var editor_fs = EditorInterface.get_resource_filesystem()
var mapInfo:gmapconf = gmapconf.new()
var gotTemplates:bool = false 
var haveTemplate:bool = false

@onready var http := $VBoxContainer/HTTPRequest
@onready var mapNameLine = $VBoxContainer/MapInformation/MapName
@onready var mapAutorline = $VBoxContainer/MapInformation/MapAuthor
@onready var mapVersion := [$VBoxContainer/MapInformation/GridContainer/MAJOR,$VBoxContainer/MapInformation/GridContainer/MINOR,$VBoxContainer/MapInformation/GridContainer/PATCH]
@onready var templateSelector = $VBoxContainer/mapTemplate/OptionButton
@onready var maps = $VBoxContainer/HBoxContainer/OptionButton
@onready var res = DirAccess.open("res://")
@onready var user = DirAccess.open("user://")

func _ready():
	if not res.dir_exists("Maps"):
		res.make_dir_recursive("Maps")
	updateMapSelector()
	getTemplates()
	updateTemplateSelector()
	editor_fs.scan()

func _on_templates_request_complete(result, response_code, headers, body):
	if user.file_exists("templates.tres"):
		user.remove("templates.tres")
	var file = FileAccess.open("user://templates.tres",FileAccess.WRITE_READ)
	file.store_buffer(body)
	file.close()
	templates = load("user://templates.tres")
	gotTemplates = true
	http.request_completed.disconnect(_on_templates_request_complete)
	
func _on_template_get_request_complete(result, response_code, headers, body):
	template = body
	haveTemplate = true
	http.request_completed.disconnect(_on_template_get_request_complete)

func _on_template_option_item_selected(index):
	selectedTemplate = templateSelector.get_item_text(index)

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

func _on_file_changed():
	if not res.dir_exists("Maps"):
		res.make_dir_recursive("Maps")
	editor_fs.scan()

func getTemplates():
	http.request_completed.connect(_on_templates_request_complete)
	http.request("https://raw.githubusercontent.com/Kaifungamedev/GmapTemplates/main/templates.tres")

## updates the template selector
func updateTemplateSelector():
	templates = load("user://templates.tres")
	while not gotTemplates:
		await get_tree().process_frame
	templateSelector.clear()
	templateSelector.add_item("[select]")
	for map in templates.maps:
		templateSelector.add_item(map)

## updates the map selector
func updateMapSelector():
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
	if not res.dir_exists("Maps"):
		res.make_dir_recursive("Maps")
	if mapNameLine.text == "" or  mapAutorline.text == "":
		printerr("unconfigured")
		return
	if selectedTemplate == null or selectedTemplate == "[select]":
		printerr("Please select a map")
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
	http.request_completed.connect(_on_template_get_request_complete)
	http.request("https://raw.githubusercontent.com/Kaifungamedev/GmapTemplates/main/{0}.tscn".format([selectedTemplate]))
	while not haveTemplate:
		await get_tree().process_frame
	var mapfile := FileAccess.open("res://Maps/{0}/map.tscn".format([mapInfo.name]),FileAccess.WRITE)
	mapfile.store_buffer(template)
	mapfile.close()
	ResourceSaver.save(mapInfo,"res://Maps/{0}/map.res".format([mapInfo.name]),ResourceSaver.FLAG_COMPRESS)
	editor_fs.scan()
	updateMapSelector()
	print("created map " + mapInfo.name)
