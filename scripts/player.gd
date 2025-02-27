extends PlatformerController2D

class_name Player2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0

var direction = 1

@export var input_dash : String = "dash"
@export var input_shoot : String = "fire"
@export var input_reload : String = "reload"

var bullet_path = preload("res://scenes/Bullet.tscn")
@onready var _animated_sprite = $AnimatedSprite2D

@onready var shoot_cooldown_timer = $ShootCooldownTimer
@onready var shoot_reload_timer = $ShootReloadTimer
@onready var ammo_label = $AmmoLabel
@onready var health_label = $HealthBar
@onready var game_time = $TimerBar

var millisecs = 0
var secs = 0
var minutes = 0

@export var shoot_cooldown_duration: float = 0.1
@export var shoot_reload_duration: float = 3.0
var Start_bullets = 50
var bullets
var health = 200
var facing_direction = 1

@export var dash_speed: float = 2000.0  # Speed of the dash
@export var dash_duration: float = 0.2  # Duration of the dash
@export var dash_cooldown: float = 1.0  # Cooldown between dashes

var is_dashing: bool = false  # Whether the player is currently dashing
var can_dash: bool = true  # Whether the player can dash
var dash_timer: Timer  # Timer for dash duration
var dash_cooldown_timer: Timer
var GameTimer : Timer

func _ready():
	dash_timer = Timer.new()
	dash_timer.wait_time = dash_duration
	dash_timer.one_shot = true
	dash_timer.timeout.connect(_on_dash_finished)
	add_child(dash_timer)

	dash_cooldown_timer = Timer.new()
	dash_cooldown_timer.wait_time = dash_cooldown
	dash_cooldown_timer.one_shot = true
	dash_cooldown_timer.timeout.connect(_on_dash_cooldown_finished)
	add_child(dash_cooldown_timer)
	
	GameTimer = Timer.new()
	GameTimer.wait_time = 1
	GameTimer.one_shot = true
	GameTimer.timeout.connect(clock_counter)
	add_child(GameTimer)
	
	shoot_cooldown_timer.wait_time = shoot_cooldown_duration
	shoot_cooldown_timer.one_shot = true
	shoot_reload_timer.wait_time = shoot_reload_duration
	shoot_reload_timer.one_shot = true
	bullets = Start_bullets
	update_ammo_label()
	update_healthBar()
	
	_animated_sprite.play("walk")
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_axis("move_left", "move_right")
	
	if direction == 1:
		facing_direction = direction
		_animated_sprite.flip_h = false
	elif direction == -1:
		facing_direction = direction
		_animated_sprite.flip_h = true
		
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if (Input.is_action_pressed(input_shoot) and bullets == 0) or Input.is_action_just_pressed(input_reload) and shoot_reload_timer.is_stopped() :
		print("reloading")
		shoot_reload_timer.start()
		reload()
		shoot_reload_timer.timeout.connect(update_ammo_label, CONNECT_ONE_SHOT)
		
	if Input.is_action_pressed(input_shoot) and shoot_cooldown_timer.is_stopped() and bullets > 0 and shoot_reload_timer.is_stopped():
		fire()
		shoot_cooldown_timer.start()
		
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		start_dash()

	# Apply dash movement
	if is_dashing:
		velocity = Vector2(direction * dash_speed, 0)  # Dash in the facing direction
	else:
		# Normal movement logic (existing code)
		pass
	clock_counter()
	move_and_slide()
	
func _process(delta: float) -> void:
	choose_animation()

func fire():
	var bullet = bullet_path.instantiate()
	bullet.dir = facing_direction
	bullet.global_position  = global_position
	print(bullets)
	get_parent().add_child(bullet)
	bullets -= 1
	
	if facing_direction == 1:
		bullet._sprite.flip_h = false
	elif facing_direction == -1:
		bullet._sprite.flip_h = true
	
	update_ammo_label()
	
	
func reload():
	ammo_label.text = "Reloading"
	bullets = Start_bullets
	
		
func update_ammo_label():
	ammo_label.text = "Ammo: " + str(bullets) + "/" + str(Start_bullets)
	
			
func update_healthBar():
	health_label.text = "Health: ❤️ " + str(health)

func start_dash():
	is_dashing = true
	can_dash = false
	dash_timer.start()
	set_invincible(true)  # Enable invincibility during dash
	
	modulate.a = 0.2 
	
	print("Dashing!")

func _on_dash_finished():
	is_dashing = false
	set_invincible(false)  # Disable invincibility after dash
	dash_cooldown_timer.start()
	
	modulate.a = 0.5
	
	print("Dash finished!")

func _on_dash_cooldown_finished():
	can_dash = true
	modulate.a = 1
	print("Dash cooldown finished!")

func set_invincible(is_invincible: bool):
	# Disable collision with enemies or hazards during dash
	if is_invincible:
		set_collision_mask_value(2, false)  # Disable collision with layer 2 (enemies)
	else:
		set_collision_mask_value(2, true)

func clock_counter():
	millisecs += 1
	if millisecs == 60:
		secs += 1
		millisecs = 0
	if secs == 60:
		secs = 0
		minutes += 1
	game_time.text = "%02d:%02d" % [minutes, secs]

func choose_animation():
	if !is_feet_on_ground():
		_animated_sprite.play("jump")
		if velocity.y < 0:
			_animated_sprite.frame = 0
			_animated_sprite.stop()
		elif velocity.y == 0:
			_animated_sprite.frame = 1
			_animated_sprite.stop()
		elif velocity.y > 0:
			_animated_sprite.frame = 2
			_animated_sprite.stop()
	else:
		if direction == 1 or direction == -1:
			_animated_sprite.play("walk")
		else:
			_animated_sprite.play("idle")
	
