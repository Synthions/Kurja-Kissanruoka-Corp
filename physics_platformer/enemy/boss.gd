class_name Boss
extends RigidBody2D

signal boss_attack(dmg:int)

const WALK_SPEED := 50
const SIZESCALE := 2
const ATTACK_COOLDOWN := 2.0
const BOSS_ATTACK_DAMAGE := 20
const JUMP_FORCE := -400
const JUMP_COOLDOWN = 3.0

enum State {
	IDLE,
	WALKING,
	JUMPING,
	ATTACKING,
	DYING,
}

var _state := State.WALKING
var direction := -1
var anim := ""
var health := 200
var player_damage := 20
var invincible := false
var attack_timer := 0.0
var jump_timer := 0.0
var playerinhitbox

@onready var player = get_node("/root/CityscapeStage/Player")
@onready var rc_left := $RaycastLeft as RayCast2D
@onready var rc_right := $RaycastRight as RayCast2D
@onready var attack_hitbox := $AttackHitbox as Area2D

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var velocity = state.get_linear_velocity()
	var new_anim := anim
	attack_timer -= state.step
	jump_timer -= state.step
	print(attack_timer)
	print(global_position.distance_to(player.global_position))

	match _state:
		State.DYING:
			new_anim = "explode"
		State.WALKING:
			new_anim = "walk"
			_handle_walking(state)
		State.JUMPING:
			new_anim = "jump"
			if rc_left.is_colliding() and rc_right.is_colliding():
				_state = State.WALKING
		State.ATTACKING:
			new_anim = "attack"
			if not $AnimationPlayer.is_playing():
				_state = State.WALKING

	_handle_action_selection()
	if anim != new_anim:
		anim = new_anim
		($AnimationPlayer as AnimationPlayer).play(anim)
	print("Current state: ", State.keys()[_state], ", Velocity: ", velocity)


func _handle_walking(state: PhysicsDirectBodyState2D) -> void:
	var velocity := state.get_linear_velocity()
	var wall_side := 0.0
	for collider_index in state.get_contact_count():
		var collider := state.get_contact_collider_object(collider_index)
		var collision_normal := state.get_contact_local_normal(collider_index)
		if collider is Bullet and not (collider as Bullet).disabled:
			_bullet_collider(collider, state, collision_normal)
			break
		if collision_normal.x > 0.9:
			wall_side = 1.0
		elif collision_normal.x < -0.9:
			wall_side = -1.0

	if wall_side != 0 and wall_side != direction:
		_flip_direction()
	if direction < 0 and not rc_left.is_colliding() and rc_right.is_colliding():
		_flip_direction()
	elif direction > 0 and not rc_right.is_colliding() and rc_left.is_colliding():
		_flip_direction()
	velocity.x = direction * WALK_SPEED
	print("Walking direction: ", direction, ", Speed: ", WALK_SPEED)
	state.set_linear_velocity(velocity)



func _handle_action_selection() -> void:
	if _state != State.WALKING:
		return

	if player:
		var distance = global_position.distance_to(player.global_position)
		if jump_timer <= 0 and randf() < 0.1:  # 10% chance to jump when cooldown is over
			_jump()
		elif attack_timer <= 0 and distance < 100:  # Attack when close and cooldown is over
			_attack()

func _jump() -> void:
	_state = State.JUMPING
	linear_velocity.y = JUMP_FORCE
	jump_timer = JUMP_COOLDOWN
	print("Jumping!")

func _attack() -> void:
	_state = State.ATTACKING
	print("Atacking!")
	attack_timer = ATTACK_COOLDOWN
	if playerinhitbox == true:
		emit_signal("boss_attack", BOSS_ATTACK_DAMAGE)
	

func _flip_direction() -> void:
	direction = -direction
	($Sprite2D as Sprite2D).scale.x = -direction * SIZESCALE
	print("fliping direction")

func _die() -> void:
	queue_free()

func _update_health(damage):
	if not invincible:
		health -= damage
		($SoundHit as AudioStreamPlayer2D).play()
		
		if health <= 0:
			health = 0
		else:
			invincibility()


func _pre_explode() -> void:
	#make sure nothing collides against this
	$Shape1.queue_free()
	$Shape2.queue_free()
	$Shape3.queue_free()
	($SoundExplode as AudioStreamPlayer2D).play()


func _bullet_collider(collider: Bullet, state: PhysicsDirectBodyState2D, collision_normal: Vector2) -> void:
	_update_health(player_damage)
	if health <= 0:
		_state = State.DYING
		state.set_angular_velocity(signf(collision_normal.x) * 33.0)
		physics_material_override.friction = 1
		collider.disable()
		



func invincibility():
	invincible = true
	for i in range(16):
		await get_tree().create_timer(.05).timeout
		if i % 2 == 0:
			modulate.a = .5
		else:
			modulate.a = 1
	invincible = false


func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body is Player:
		playerinhitbox = true
	else:
		pass

func _on_attack_hitbox_body_exited(body: Node2D) -> void:
	if body is Player:
		playerinhitbox = false
	else:
		pass
