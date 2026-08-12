extends CharacterBody2D


const SPEED = 300.0
const ATTACK_COOLDOWN = 0.3
const MAX_HEALTH = 3
const INVULNERABILITY_DURATION = 0.5

signal health_changed(current_health: int)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_attacking: bool = false
var attack_cooldown_timer: float = 0.0
var last_direction: String = "down"

var current_health: int = MAX_HEALTH
var is_dead: bool = false
var invulnerability_timer: float = 0.0
var is_invulnerable: bool = false


func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)

	# Ensure attack animations don't loop so animation_finished fires correctly
	animated_sprite.sprite_frames.set_animation_loop("attack_up", false)
	animated_sprite.sprite_frames.set_animation_loop("attack_down", false)
	animated_sprite.sprite_frames.set_animation_loop("attack_left", false)
	animated_sprite.sprite_frames.set_animation_loop("death_down", false)
	animated_sprite.sprite_frames.set_animation_loop("death_left", false)
	animated_sprite.sprite_frames.set_animation_loop("death_up", false)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Update invulnerability timer
	if invulnerability_timer > 0:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			is_invulnerable = false
			animated_sprite.modulate.a = 1.0
		else:
			# Flash effect during invulnerability
			animated_sprite.modulate.a = 0.5 if fmod(invulnerability_timer * 10.0, 2.0) < 1.0 else 1.0

	# Update cooldown timer
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	var direction_x := Input.get_axis("ui_left", "ui_right")
	var direction_y := Input.get_axis("ui_up", "ui_down")

	# Movement is always allowed
	if direction_x != 0 or direction_y != 0:
		velocity = Vector2(direction_x, direction_y).normalized() * SPEED
	else:
		velocity = Vector2.ZERO

	# Update last facing direction only when not attacking
	if not is_attacking:
		if direction_y < 0:
			last_direction = "up"
		elif direction_y > 0:
			last_direction = "down"
		elif direction_x < 0:
			last_direction = "left"
		elif direction_x > 0:
			last_direction = "right"

	# Handle attack input
	if Input.is_action_pressed("attack") and not is_attacking and attack_cooldown_timer <= 0:
		_start_attack()
	elif not is_attacking:
		_update_movement_animation(direction_x, direction_y)

	move_and_slide()


func take_damage(amount: int) -> void:
	if is_dead or is_invulnerable:
		return

	current_health -= amount
	health_changed.emit(current_health)

	if current_health <= 0:
		die()
	else:
		# Start invulnerability
		is_invulnerable = true
		invulnerability_timer = INVULNERABILITY_DURATION


func die() -> void:
	is_dead = true
	is_invulnerable = false
	invulnerability_timer = 0.0
	velocity = Vector2.ZERO
	animated_sprite.modulate.a = 1.0

	var anim_name: String
	var flip: bool = false

	match last_direction:
		"up":
			anim_name = "death_up"
		"down":
			anim_name = "death_down"
		"left":
			anim_name = "death_left"
			flip = false
		"right":
			anim_name = "death_left"
			flip = true

	animated_sprite.play(anim_name)
	animated_sprite.flip_h = flip


func _start_attack() -> void:
	is_attacking = true

	var anim_name: String
	var flip: bool = false

	match last_direction:
		"up":
			anim_name = "attack_up"
		"down":
			anim_name = "attack_down"
		"left":
			anim_name = "attack_left"
			flip = false
		"right":
			anim_name = "attack_left"
			flip = true

	# Calculate cooldown: max(0.3, animation duration)
	var frame_count := animated_sprite.sprite_frames.get_frame_count(anim_name)
	var anim_speed := animated_sprite.sprite_frames.get_animation_speed(anim_name)
	var anim_duration := frame_count / anim_speed if anim_speed > 0 else 0.0
	attack_cooldown_timer = maxf(ATTACK_COOLDOWN, anim_duration)

	animated_sprite.play(anim_name)
	animated_sprite.flip_h = flip


func _update_movement_animation(direction_x: float, direction_y: float) -> void:
	if direction_y < 0:
		animated_sprite.play("up")
		animated_sprite.flip_h = false
	elif direction_y > 0:
		animated_sprite.play("down")
		animated_sprite.flip_h = false
	elif direction_x < 0:
		animated_sprite.play("left")
		animated_sprite.flip_h = false
	elif direction_x > 0:
		animated_sprite.play("left")
		animated_sprite.flip_h = true
	else:
		animated_sprite.pause()


func _on_animation_finished() -> void:
	if animated_sprite.animation.begins_with("attack_"):
		is_attacking = false
	elif animated_sprite.animation.begins_with("death_"):
		get_tree().reload_current_scene()
