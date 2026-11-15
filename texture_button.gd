extends TextureButton

@export var dvd_player: CharacterBody2D
@export var dvd_textures: Array[Texture2D] = []
@export var cost: int = 100
@export var unlock_display_size: float = 400

var is_opening: bool = false

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if is_opening or not dvd_player or dvd_textures.is_empty():
		return
	
	if dvd_player.money >= cost:
		is_opening = true
		dvd_player.money -= cost
		dvd_player.update_money_ui()
		
		# 1. Pick the random DVD texture
		var chosen_texture: Texture2D
		if dvd_textures.size() > 1:
			var available = dvd_textures.filter(func(tex): return tex != dvd_player.dvd_texture)
			chosen_texture = available.pick_random()
		else:
			chosen_texture = dvd_textures.pick_random()
		
		# 2. Play the crate opening animation before/while equipping
		await play_crate_animation(chosen_texture)
		
		# 3. Equip the DVD and unlock it in the Dex
		dvd_player.dvd_texture = chosen_texture
		is_opening = false
	else:
		# Shake the crate button slightly if the player can't afford it!
		var orig_x = position.x
		var shake = create_tween()
		shake.tween_property(self, "position:x", orig_x + 6, 0.05)
		shake.tween_property(self, "position:x", orig_x - 6, 0.05)
		shake.tween_property(self, "position:x", orig_x, 0.05)

func play_crate_animation(reward_texture: Texture2D) -> void:
	# Create a temporary popup layer on top of everything
	var overlay = CanvasLayer.new()
	overlay.layer = 10
	get_tree().current_scene.add_child(overlay)
	
	# Dark background dim
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	
	# Center container for the crate / reward sprite
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	var display_icon = TextureRect.new()
	display_icon.texture = texture_normal # Starts showing the crate image
	display_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display_icon.custom_minimum_size = Vector2(unlock_display_size, unlock_display_size)
	display_icon.pivot_offset = Vector2(unlock_display_size * 0.5, unlock_display_size * 0.5)
	display_icon.scale = Vector2(0.2, 0.2)
	center.add_child(display_icon)
	
	# Step A: Crate pops onto screen
	var tween = create_tween()
	tween.tween_property(display_icon, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Step B: Crate shakes left and right with suspense!
	for i in range(5):
		tween.tween_property(display_icon, "rotation_degrees", 14.0, 0.06)
		tween.tween_property(display_icon, "rotation_degrees", -14.0, 0.06)
	tween.tween_property(display_icon, "rotation_degrees", 0.0, 0.05)
	
	# Step C: Flash white and swap the crate sprite into the rolled DVD!
	tween.tween_property(display_icon, "modulate", Color(3, 3, 3, 1), 0.1)
	tween.tween_callback(func(): display_icon.texture = reward_texture)
	tween.tween_property(display_icon, "scale", Vector2(1.35, 1.35), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(display_icon, "modulate", Color(1, 1, 1, 1), 0.25)
	
	# Hold on screen briefly so the player sees what they got, then clean up
	tween.tween_interval(0.9)
	await tween.finished
	overlay.queue_free()
