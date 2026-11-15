extends CharacterBody2D

@export var speed: float = 300.0

var money: int = 0
var dvd_level: int = 1
var money_label: Label
var money_ui: CanvasLayer

func _ready() -> void:
	# Automatically finds the CanvasLayer named "Money" anywhere in your current scene
	money_ui = get_tree().current_scene.find_child("Money", true, false) as CanvasLayer
	if money_ui:
		money_label = money_ui.find_child("*", true, false) as Label
	
	var four_directions = [45.0, 135.0, 225.0, 315.0]
	var chosen_degrees = four_directions.pick_random()
	var direction = Vector2.from_angle(deg_to_rad(chosen_degrees))
	velocity = direction * speed
	
	update_money_ui()

func _physics_process(delta: float) -> void:
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		money += 10 * dvd_level
		update_money_ui()

func update_money_ui() -> void:
	if money_label:
		money_label.text = "Money: $" + str(money)

func _on_button_pressed() -> void:
	print("hello")
	$"../ShopUi".visible = !$"../ShopUi".visible
	if money_ui:
		money_ui.visible = !money_ui.visible


func _on_corners_body_entered(body: Node2D) -> void:
	money += dvd_level * 300
