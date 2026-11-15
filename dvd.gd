extends CharacterBody2D

signal dvd_unlocked(texture: Texture2D)

@export var speed: float = 300.0
@export var texture_levels: Dictionary[Texture2D, int] = {}

@export var dvd_texture: Texture2D:
	set(value):
		dvd_texture = value
		if is_node_ready() and sprite and dvd_texture:
			sprite.texture = dvd_texture
		update_dvd_level()
		unlock_dvd(dvd_texture)

@onready var sprite: Sprite2D = $Sprite2D

var money: int = 0
@export var dvd_level: int = 1
var money_label: Label
var money_ui: CanvasLayer
var unlocked_dvds: Array[Texture2D] = []

func _ready() -> void:
	if dvd_texture and sprite:
		sprite.texture = dvd_texture
		unlock_dvd(dvd_texture)
	update_dvd_level()
	
	money_ui = get_tree().current_scene.find_child("Money", true, false) as CanvasLayer
	if money_ui:
		money_label = money_ui.find_child("*", true, false) as Label
	
	var four_directions = [45.0, 135.0, 225.0, 315.0]
	var chosen_degrees = four_directions.pick_random()
	var direction = Vector2.from_angle(deg_to_rad(chosen_degrees))
	velocity = direction * speed
	
	update_money_ui()

func unlock_dvd(tex: Texture2D) -> void:
	if tex and not unlocked_dvds.has(tex):
		unlocked_dvds.append(tex)
		dvd_unlocked.emit(tex)

func _physics_process(delta: float) -> void:
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		money += 10 * dvd_level
		update_money_ui()

func update_dvd_level() -> void:
	if dvd_texture and texture_levels.has(dvd_texture):
		dvd_level = texture_levels[dvd_texture]
	else:
		dvd_level = 1

func update_money_ui() -> void:
	if money_label:
		money_label.text = "Money: $" + str(money)

func _on_button_pressed() -> void:
	print("hello")
	var shop_ui = $"../ShopUi"
	shop_ui.visible = !shop_ui.visible
	
	var dex_button = get_tree().current_scene.find_child("DVDDexButton", true, false)
	if dex_button:
		dex_button.visible = !shop_ui.visible

func _on_corners_body_entered(body: Node2D) -> void:
	money += dvd_level * 300
