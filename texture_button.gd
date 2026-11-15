extends TextureButton

@export var dvd_player: CharacterBody2D
@export var dvd_textures: Array[Texture2D] = []
@export var cost: int = 100

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	print("Shop item clicked!")
	if not dvd_player:
		print("ERROR: Dvd Player is empty!")
		return
	if dvd_textures.is_empty():
		print("ERROR: Dvd Textures list is empty!")
		return
	
	if dvd_player.money >= cost:
		dvd_player.money -= cost
		dvd_player.update_money_ui()
		
		var chosen_texture: Texture2D
		if dvd_textures.size() > 1:
			var available = dvd_textures.filter(func(tex): return tex != dvd_player.dvd_texture)
			chosen_texture = available.pick_random()
		else:
			chosen_texture = dvd_textures.pick_random()
		
		dvd_player.dvd_texture = chosen_texture
		print("Changed DVD texture to: ", chosen_texture.resource_path)
	else:
		print("Not enough money! Need $", cost, " but only have $", dvd_player.money)
