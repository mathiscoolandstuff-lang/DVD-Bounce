extends CharacterBody2D

@export var speed: float = 300.0

func _ready():
	var four_directions = [45.0, 135.0, 225.0, 315.0]
	var chosen_degrees = four_directions.pick_random()
	var direction = Vector2.from_angle(deg_to_rad(chosen_degrees))
	velocity = direction * speed

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())



	



func _on_button_pressed() -> void:
	print("hello")
	if $"../ShopUi".visible == false:
		$"../ShopUi".visible = true
	else:
		$"../ShopUi".visible = false
