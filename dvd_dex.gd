extends CanvasLayer

@export var columns: int = 10:
	set(value):
		columns = value
		if grid: grid.columns = columns

@export var grid_top_left: Vector2 = Vector2(185, 62):
	set(value):
		grid_top_left = value
		if grid: grid.position = grid_top_left

@export var icon_size: Vector2 = Vector2(68, 80):
	set(value):
		icon_size = value
		if grid:
			for child in grid.get_children():
				child.custom_minimum_size = icon_size

@export var horizontal_gap: int = 10:
	set(value):
		horizontal_gap = value
		if grid: grid.add_theme_constant_override("h_separation", horizontal_gap)

@export var vertical_gap: int = 14:
	set(value):
		vertical_gap = value
		if grid: grid.add_theme_constant_override("v_separation", vertical_gap)

var grid: GridContainer
var dvd_player: CharacterBody2D

func _ready() -> void:
	grid = GridContainer.new()
	grid.columns = columns
	grid.position = grid_top_left
	grid.add_theme_constant_override("h_separation", horizontal_gap)
	grid.add_theme_constant_override("v_separation", vertical_gap)
	add_child(grid)
	
	dvd_player = get_tree().current_scene.find_child("DVD", true, false) as CharacterBody2D
	if dvd_player:
		dvd_player.dvd_unlocked.connect(_on_dvd_unlocked)
		for tex in dvd_player.unlocked_dvds:
			_on_dvd_unlocked(tex)

func _on_dvd_unlocked(tex: Texture2D) -> void:
	var btn = TextureButton.new()
	btn.texture_normal = tex
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.custom_minimum_size = icon_size
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	btn.pressed.connect(func(): _on_dex_item_clicked(tex))
	grid.add_child(btn)

func _on_dex_item_clicked(tex: Texture2D) -> void:
	if dvd_player:
		dvd_player.dvd_texture = tex
		print("Equipped DVD from Dex: ", tex.resource_path)
