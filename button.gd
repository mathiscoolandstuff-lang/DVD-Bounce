extends BaseButton

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	print("DVD-Dex button clicked!")
	
	var root = get_tree().current_scene if get_tree().current_scene else get_tree().root
	
	# Try common name variations for the DVD Dex layer/node
	var dex_layer = root.find_child("DVD Dex", true, false)
	if not dex_layer:
		dex_layer = root.find_child("DVD-Dex", true, false)
	if not dex_layer:
		dex_layer = root.find_child("DVDDex", true, false)
	
	if not dex_layer:
		print("ERROR: Still couldn't find DVD Dex! Here are all nodes in the scene:")
		for child in root.get_children():
			print(" - ", child.name)
		return
	
	# Toggle visibility
	dex_layer.visible = !dex_layer.visible
	
	# Also make sure any child sprite inside it is visible
	for child in dex_layer.get_children():
		if child is CanvasItem:
			child.visible = true
	
	# Hide/show the Shop Button so menus don't overlap
	var shop_btn = root.find_child("Shop Button", true, false)
	if shop_btn:
		shop_btn.visible = !dex_layer.visible
