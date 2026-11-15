extends CharacterBody2D

signal dvd_unlocked(texture: Texture2D)

@export var speed: float = 300.0
@export var texture_levels: Dictionary[Texture2D, int] = {}

@export_group("Math DVD Power")
@export var math_dvd_texture: Texture2D
@export var rare_crate_button: TextureButton
@export var math_quiz_interval: float = 25.0

@export_group("Chemistry DVD Power")
@export var chemistry_dvd_texture: Texture2D
@export_range(0.0, 1.0) var potion_drop_chance: float = 0.5
@export var potion_texture: Texture2D

@export var dvd_texture: Texture2D:
	set(value):
		dvd_texture = value
		if is_node_ready() and sprite and dvd_texture:
			sprite.texture = dvd_texture
		update_dvd_level()
		update_power_timers()
		unlock_dvd(dvd_texture)

@onready var sprite: Sprite2D = $Sprite2D

var money: int = 0
@export var dvd_level: int = 1
var money_label: Label
var money_ui: CanvasLayer
var unlocked_dvds: Array[Texture2D] = []

var income_multiplier: int = 1
var speed_multiplier: float = 1.0
var math_timer: Timer
var quiz_active: bool = false

var math_questions: Array[Dictionary] = [
	{"q": "Solve for the positive root: x² + 15x - 16 = 0", "a": ["1", "x=1", "x = 1"]},
	{"q": "Solve for the smaller root: x² - 11x + 24 = 0", "a": ["3", "x=3", "x = 3"]},
	{"q": "Solve for the positive root: 2x² - 18 = 0", "a": ["3", "x=3", "x = 3"]},
	{"q": "Solve for x: 3(2x - 5) + 4 = 5x - 2", "a": ["9", "x=9", "x = 9"]},
	{"q": "If f(x) = 3x³ - 4x² + 7x - 9, what is f'(2)?", "a": ["27"]},
	{"q": "Solve for the larger root: x² + 5x - 36 = 0", "a": ["4", "x=4", "x = 4"]},
	{"q": "Solve for x: log₂(x + 6) = 4", "a": ["10", "x=10", "x = 10"]},
	{"q": "Solve for the positive root: 2x² + 7x - 15 = 0", "a": ["1.5", "3/2", "x=1.5", "x=3/2"]},
	{"q": "What is the discriminant (b² - 4ac) of 2x² + 9x - 5 = 0?", "a": ["121"]},
	{"q": "Solve for x: 4^(x - 1) = 64", "a": ["4", "x=4", "x = 4"]}
]

func _ready() -> void:
	if dvd_texture and sprite:
		sprite.texture = dvd_texture
		unlock_dvd(dvd_texture)
	update_dvd_level()
	
	money_ui = get_tree().current_scene.find_child("Money", true, false) as CanvasLayer
	if money_ui:
		money_label = money_ui.find_child("*", true, false) as Label
	
	math_timer = Timer.new()
	math_timer.wait_time = math_quiz_interval
	math_timer.timeout.connect(_on_math_timer_timeout)
	add_child(math_timer)
	update_power_timers()
	
	var four_directions = [45.0, 135.0, 225.0, 315.0]
	var chosen_degrees = four_directions.pick_random()
	var direction = Vector2.from_angle(deg_to_rad(chosen_degrees))
	velocity = direction * speed
	
	update_money_ui()

func update_power_timers() -> void:
	if not is_node_ready() or not math_timer:
		return
	if dvd_texture == math_dvd_texture and math_dvd_texture != null:
		if math_timer.is_stopped():
			math_timer.start(math_quiz_interval)
	else:
		math_timer.stop()

func unlock_dvd(tex: Texture2D) -> void:
	if tex and not unlocked_dvds.has(tex):
		unlocked_dvds.append(tex)
		dvd_unlocked.emit(tex)

func _physics_process(delta: float) -> void:
	if velocity != Vector2.ZERO:
		velocity = velocity.normalized() * (speed * speed_multiplier)
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		money += 10 * dvd_level * income_multiplier
		update_money_ui()

func update_dvd_level() -> void:
	if dvd_texture and texture_levels.has(dvd_texture):
		dvd_level = texture_levels[dvd_texture]
	else:
		dvd_level = 1

func update_money_ui() -> void:
	if money_label:
		var suffix = ""
		if income_multiplier > 1:
			suffix += " (2x CASH!)"
		if speed_multiplier > 1.0:
			suffix += " (5x SPEED!)"
		money_label.text = "Money: $" + str(money) + suffix

func _on_button_pressed() -> void:
	var shop_ui = $"../ShopUi"
	shop_ui.visible = !shop_ui.visible
	
	var dex_button = get_tree().current_scene.find_child("DVDDexButton", true, false)
	if dex_button:
		dex_button.visible = !shop_ui.visible

func _on_corners_body_entered(body: Node2D) -> void:
	money += dvd_level * 300 * income_multiplier
	update_money_ui()
	
	if dvd_texture == chemistry_dvd_texture and chemistry_dvd_texture != null:
		if randf() <= potion_drop_chance:
			spawn_chemistry_potion(global_position)

func _on_math_timer_timeout() -> void:
	if quiz_active or dvd_texture != math_dvd_texture:
		return
	show_math_quiz()

func show_math_quiz() -> void:
	quiz_active = true
	var item = math_questions.pick_random()
	
	var layer = CanvasLayer.new()
	layer.layer = 15
	get_tree().current_scene.add_child(layer)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 210)
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "MATH DVD CHALLENGE! (Win a Free Rare Chest)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var q_label = Label.new()
	q_label.text = item["q"]
	q_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(q_label)
	
	var input = LineEdit.new()
	input.placeholder_text = "Type your answer..."
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(input)
	input.grab_focus()
	
	var status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(hbox)
	
	var submit_btn = Button.new()
	submit_btn.text = "Submit Answer"
	hbox.add_child(submit_btn)
	
	var close_btn = Button.new()
	close_btn.text = "Skip"
	hbox.add_child(close_btn)
	
	var check_answer = func(_text = ""):
		var user_ans = input.text.strip_edges().to_lower()
		var accepted: Array = item["a"]
		if user_ans in accepted:
			status.text = "CORRECT! Opening Free Rare Chest..."
			submit_btn.disabled = true
			await get_tree().create_timer(0.8).timeout
			layer.queue_free()
			quiz_active = false
			grant_free_rare_chest()
		else:
			status.text = "Incorrect! Answer was: " + str(accepted[0])
			submit_btn.disabled = true
			await get_tree().create_timer(1.4).timeout
			layer.queue_free()
			quiz_active = false
	
	submit_btn.pressed.connect(check_answer)
	input.text_submitted.connect(check_answer)
	close_btn.pressed.connect(func():
		layer.queue_free()
		quiz_active = false
	)

func grant_free_rare_chest() -> void:
	if rare_crate_button and not rare_crate_button.dvd_textures.is_empty():
		var chosen = rare_crate_button.dvd_textures.pick_random()
		if rare_crate_button.has_method("play_crate_animation"):
			await rare_crate_button.play_crate_animation(chosen)
		dvd_texture = chosen
	else:
		print("WARNING: Assign 'Rare Crate Button' in DVD Inspector to open a free chest!")

func spawn_chemistry_potion(drop_pos: Vector2) -> void:
	var potion_type = randi_range(1, 3)
	
	var potion_btn = TextureButton.new()
	potion_btn.custom_minimum_size = Vector2(54, 54)
	potion_btn.ignore_texture_size = true
	potion_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	potion_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var tint = Color.GOLD if potion_type == 1 else (Color.LIME_GREEN if potion_type == 2 else Color.CYAN)
	
	if potion_texture:
		potion_btn.texture_normal = potion_texture
		potion_btn.modulate = tint
	else:
		var placeholder = ColorRect.new()
		placeholder.color = tint
		placeholder.custom_minimum_size = Vector2(44, 44)
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		potion_btn.add_child(placeholder)
	
	var viewport_size = get_viewport_rect().size
	potion_btn.position = Vector2(
		clamp(drop_pos.x - 27, 60, viewport_size.x - 110),
		clamp(drop_pos.y - 27, 60, viewport_size.y - 110)
	)
	
	var ui_layer = money_ui if money_ui else get_tree().current_scene
	ui_layer.add_child(potion_btn)
	
	var bob = potion_btn.create_tween().set_loops()
	bob.tween_property(potion_btn, "position:y", potion_btn.position.y - 8, 0.4)
	bob.tween_property(potion_btn, "position:y", potion_btn.position.y, 0.4)
	
	potion_btn.pressed.connect(func():
		activate_potion(potion_type)
		potion_btn.queue_free()
	)
	
	get_tree().create_timer(12.0).timeout.connect(func():
		if is_instance_valid(potion_btn):
			potion_btn.queue_free()
	)

func activate_potion(potion_type: int) -> void:
	match potion_type:
		1:
			money *= 2
			update_money_ui()
			show_floating_banner("POTION: DOUBLED YOUR MONEY! ($" + str(money) + ")", Color.GOLD)
		2:
			income_multiplier = 2*income_multiplier
			update_money_ui()
			show_floating_banner("POTION: " + str(income_multiplier) + "x INCOME FOR 30 SECONDS!", Color.LIME_GREEN)
			await get_tree().create_timer(30.0).timeout
			income_multiplier = 1
			update_money_ui()
		3:
			speed_multiplier = 5.0*speed_multiplier
			update_money_ui()
			show_floating_banner("POTION: " + str(speed_multiplier) + "x SPEED FOR 30 SECONDS!", Color.CYAN)
			await get_tree().create_timer(30.0).timeout
			speed_multiplier = 1.0
			update_money_ui()

func show_floating_banner(text_msg: String, color: Color) -> void:
	var banner = Label.new()
	banner.text = text_msg
	banner.modulate = color
	banner.position = Vector2(get_viewport_rect().size.x * 0.5 - 180, 90)
	var ui_layer = money_ui if money_ui else get_tree().current_scene
	ui_layer.add_child(banner)
	
	var tween = banner.create_tween()
	tween.tween_property(banner, "position:y", 50.0, 1.8)
	tween.parallel().tween_property(banner, "modulate:a", 0.0, 1.8)
	await tween.finished
	banner.queue_free()
