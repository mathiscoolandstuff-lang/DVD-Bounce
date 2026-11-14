extends CharacterBody2D

@export var speed: float = 300.0

func _ready():
	# 1. Define the 4 diagonal angles (in degrees)
	var four_directions = [45.0, 135.0, 225.0, 315.0]
	
	# 2. Pick one of the 4 angles at random
	var chosen_degrees = four_directions.pick_random()
	
	# 3. Convert to radians and set initial velocity
	var direction = Vector2.from_angle(deg_to_rad(chosen_degrees))
	velocity = direction * speed

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	
	# Bouncing off flat walls will naturally keep it locked to those 4 angles
	if collision:
		velocity = velocity.bounce(collision.get_normal())
