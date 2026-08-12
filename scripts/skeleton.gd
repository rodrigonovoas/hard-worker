extends CharacterBody2D

const SPEED = 80.0
const PATROL_DISTANCE = 100.0
const DAMAGE = 1
const DAMAGE_COOLDOWN = 0.5
const SPAWN_PROTECTION = 0.15

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D

var direction: float = -1.0  # -1 = left, 1 = right
var start_position: Vector2
var is_dead: bool = false
var damage_cooldown: float = 0.0
var spawn_protection_timer: float = SPAWN_PROTECTION
var current_animation: String = "idle"


func _ready() -> void:
	start_position = global_position
	animated_sprite.play("idle")
	animated_sprite.flip_h = false
	current_animation = "idle"
	add_to_group("enemies")
	area_2d.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Spawn protection countdown
	if spawn_protection_timer > 0:
		spawn_protection_timer -= delta

	if damage_cooldown > 0:
		damage_cooldown -= delta

	# Patrol back and forth
	var distance_from_start = global_position.x - start_position.x

	if distance_from_start <= -PATROL_DISTANCE:
		direction = 1.0
	elif distance_from_start >= PATROL_DISTANCE:
		direction = -1.0

	velocity.x = direction * SPEED
	velocity.y = 0.0

	# Update animation and flip
	var target_anim := "walk"
	var target_flip := direction > 0

	if current_animation != target_anim or animated_sprite.flip_h != target_flip:
		animated_sprite.play(target_anim)
		animated_sprite.flip_h = target_flip
		current_animation = target_anim

	move_and_slide()

	# Deal damage to player on touch
	for body in area_2d.get_overlapping_bodies():
		if body == self:
			continue
		if body.has_method("take_damage") and damage_cooldown <= 0:
			body.take_damage(DAMAGE)
			damage_cooldown = DAMAGE_COOLDOWN


func _on_body_entered(body: Node2D) -> void:
	if body == self:
		return
	if body.has_method("take_damage") and damage_cooldown <= 0:
		body.take_damage(DAMAGE)
		damage_cooldown = DAMAGE_COOLDOWN


func take_damage(amount: int) -> void:
	if is_dead:
		return
	if spawn_protection_timer > 0:
		return

	is_dead = true
	velocity = Vector2.ZERO
	animated_sprite.play("death")
	animated_sprite.animation_finished.connect(_on_death_finished)


func _on_death_finished() -> void:
	queue_free()
