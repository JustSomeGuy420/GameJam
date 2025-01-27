extends PlatformerController2D

class_name Enemy2D

const SPEED = 100.0
const JUMP_VELOCITY = -400.0
var direction = 1  # 1 for moving right, -1 for moving left
var health = 200
@onready var health_label = $Health

@onready var _animated_sprite = $AnimatedSprite2D
@onready var _player: Player2D = get_parent().find_child("Player2D")

func _ready() -> void:
	add_to_group("enemy")
	_animated_sprite.play("default")
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	# if Input.is_action_just_pressed("jump") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = 1
	if position.x < _player.position.x:
		direction = 1
		_animated_sprite.flip_h = false
	elif position.x > _player.position.x:
		direction = -1
		_animated_sprite.flip_h = true
		
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()

func take_damage(amount:int):
	health -= amount
	modulate = Color(1, 0, 0)  # Turn red
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)  # Return to normal color
	
	if health <= 0:
		die()
		
	update_healthBar()	

func update_healthBar():
	health_label.text = "Health: ❤️ " + str(health)

func die():
	print("Enemy died!")
	queue_free()
