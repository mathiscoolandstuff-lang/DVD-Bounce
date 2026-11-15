extends TextureButton

@export var dvd_player: CharacterBody2D
@export var dvd_textures: Array[Texture2D] = []
@export var cost: int = 100
@export var podium_texture: Texture2D

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
		
		var chosen_texture: Texture2D
		if dvd_textures.size() > 1:
			var available = dvd_textures.filter(func(tex): return tex != dvd_player.dvd_texture)
			chosen_texture = available.pick_random()
		else:
			chosen_texture = dvd_textures.pick_random()
		
		await play_crate_animation(chosen_texture)
		
		dvd_player.dvd_texture = chosen_texture
		is_opening = false
	else:
		var orig_x = position.x
		var shake = create_tween()
		shake.tween_property(self, "position:x", orig_x + 6, 0.05)
		shake.tween_property(self, "position:x", orig_x - 6, 0.05)
		shake.tween_property(self, "position:x", orig_x, 0.05)

func play_crate_animation(reward_texture: Texture2D) -> void:
	# 1. Fullscreen overlay above all 2D UI
	var overlay = CanvasLayer.new()
	overlay.layer = 25
	get_tree().current_scene.add_child(overlay)
	
	var dim = ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.09, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	
	# 2. 3D SubViewport
	var vpc = SubViewportContainer.new()
	vpc.set_anchors_preset(Control.PRESET_FULL_RECT)
	vpc.stretch = true
	overlay.add_child(vpc)
	
	var vp = SubViewport.new()
	vp.size = get_viewport_rect().size
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vpc.add_child(vp)
	
	# 3. WorldEnvironment + Studio Lights
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.95, 0.97, 1.0)
	env.ambient_light_energy = 1.4
	world_env.environment = env
	vp.add_child(world_env)
	
	var cam = Camera3D.new()
	cam.position = Vector3(0, 0.8, 5.2)
	cam.look_at(Vector3(0, -0.2, 0))
	vp.add_child(cam)
	
	var key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-40, 30, 0)
	key_light.light_energy = 1.6
	vp.add_child(key_light)
	
	var rim_light = OmniLight3D.new()
	rim_light.position = Vector3(0, 2.2, 1.5)
	rim_light.light_color = Color(0.4, 0.8, 1.0)
	rim_light.light_energy = 3.5
	vp.add_child(rim_light)
		# 4. Build the Podium from your PNG
	var podium = MeshInstance3D.new()
	var pod_quad = QuadMesh.new()
	pod_quad.size = Vector2(4.8, 2.1) # Adjust width/height to match your podium PNG shape
	podium.mesh = pod_quad

	var pod_mat = StandardMaterial3D.new()
	pod_mat.albedo_texture = podium_texture
	pod_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pod_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pod_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	podium.material_override = pod_mat
	podium.position = Vector3(0, -1.45, 1) # Slightly behind the DVD on Z-axis
	vp.add_child(podium)

		# 5. Build the 3D Crate using a crisp double-sided QuadMesh
	var crate = MeshInstance3D.new()
	var crate_quad = QuadMesh.new()
	crate_quad.size = Vector2(1.6, 1.6)
	crate.mesh = crate_quad
	
	var crate_mat = StandardMaterial3D.new()
	if texture_normal:
		crate_mat.albedo_texture = texture_normal
	else:
		crate_mat.albedo_color = Color(0.85, 0.6, 0.2)
	crate_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crate_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	crate_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	crate_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	crate.material_override = crate_mat
	
	crate.position = Vector3(0, 5.5, 0)
	crate.rotation_degrees = Vector3(15, 30, 0)
	vp.add_child(crate)
	
	# 6. Build the 3D DVD Showcase using a double-sided QuadMesh
	var dvd_disc = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(2.2, 1.4)
	dvd_disc.mesh = quad
	
	var disc_mat = StandardMaterial3D.new()
	disc_mat.albedo_texture = reward_texture
	disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	disc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	dvd_disc.material_override = disc_mat
	
	dvd_disc.position = Vector3(0, 1.4, 0)
	dvd_disc.visible = false
	vp.add_child(dvd_disc)

	
	# === STEP 1: CRATE FALLS FROM THE TOP ===
	var fall_tween = create_tween()
	fall_tween.tween_property(crate, "position", Vector3(0, 0.1, 0), 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await fall_tween.finished
	
	# === STEP 2: SPIN FASTER AND FASTER UNTIL EDGES BLUR ===
	var spin_tween = create_tween()
	spin_tween.tween_property(crate, "rotation_degrees:y", 9000.0, 2.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	spin_tween.parallel().tween_property(crate, "rotation_degrees:x", 1800.0, 2.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	spin_tween.parallel().tween_property(crate, "position:y", 0.9, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	spin_tween.parallel().tween_property(crate_mat, "emission_energy_multiplier", 5.0, 2.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	spin_tween.parallel().tween_property(crate, "scale", Vector3(1.25, 0.95, 1.25), 2.2)
	await spin_tween.finished
	
	# === STEP 3: EXPLOSION + SHARDS ===
	crate.visible = false
	dvd_disc.visible = true
	
	var shard_mesh = BoxMesh.new()
	shard_mesh.size = Vector3(0.2, 0.2, 0.2)
	var shard_mat = StandardMaterial3D.new()
	shard_mat.albedo_color = Color(1.0, 0.85, 0.25)
	shard_mat.emission_enabled = true
	shard_mat.emission = Color(1.0, 0.65, 0.15)
	shard_mat.emission_energy_multiplier = 2.5
	
	for i in range(36):
		var shard = MeshInstance3D.new()
		shard.mesh = shard_mesh
		shard.material_override = shard_mat
		shard.position = Vector3(0, 0.9, 0)
		vp.add_child(shard)
		
		var dir = Vector3(randf_range(-1, 1), randf_range(-0.3, 1.4), randf_range(-1, 1)).normalized()
		var target = shard.position + dir * randf_range(4.0, 7.5)
		var st = create_tween()
		st.tween_property(shard, "position", target, 0.8).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		st.parallel().tween_property(shard, "rotation_degrees", Vector3(720, 900, 540), 0.8)
		st.parallel().tween_property(shard, "scale", Vector3.ZERO, 0.8)
	
	dim.color = Color(1.0, 0.98, 0.9, 0.95)
	var flash_tween = create_tween()
	flash_tween.tween_property(dim, "color", Color(0.03, 0.04, 0.09, 0.85), 0.4)
	
	# === STEP 4: DVD FLOATS DOWN TO PODIUM & SPINS SLOWLY FOR 6 SECONDS ===
	var float_tween = create_tween()
	float_tween.tween_property(dvd_disc, "position:y", -0.35, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	float_tween.parallel().tween_property(dvd_disc, "rotation_degrees:y", 720.0, 3.0).set_trans(Tween.TRANS_LINEAR)
	await float_tween.finished
	
	var end_tween = create_tween()
	end_tween.tween_property(dim, "color:a", 0.0, 0.25)
	end_tween.parallel().tween_property(dvd_disc, "scale", Vector3.ZERO, 0.25)
	await end_tween.finished
	
	overlay.queue_free()
