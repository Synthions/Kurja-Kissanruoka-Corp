class_name Boss
extends RigidBody2D

signal boss_attack(dmg:int)
signal boss_death()

const WALK_SPEED := 50
const SIZESCALE := 1
const ATTACK_COOLDOWN := 2.0
const BOSS_ATTACK_DAMAGE := 20
const JUMP_FORCE := -500
const JUMP_HEIGHT := 100
const JUMP_COOLDOWN := 3.0
const JUMP_DURATION := 3.0

enum State {
	SLEEP,
	IDLE,
	WALKING,
	JUMPING,
	ATTACKING,
	DYING,
}

var _state := State.SLEEP
var direction := -1
var anim := ""
var health := 200
var player_damage := 20
var invincible := false
var attack_timer := 0.0
var jump_timer := 0.0
var playerinhitbox := false

@onready var player = get_node("/root/CityscapeStage/Player")
@onready var rc_left := $RaycastLeft as RayCast2D
@onready var rc_right := $RaycastRight as RayCast2D
@onready var attack_hitbox := $AttackHitbox as Area2D


func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	var new_anim := anim
	attack_timer -= delta  # Use delta time for smoother countdown
	jump_timer -= delta
	
	match _state:
		State.IDLE:
			new_anim = "idle"
		State.SLEEP:
			new_anim = "idle"
		State.DYING:
			new_anim = "explode"
		State.WALKING:
			new_anim = "idle"
			#_handle_walking(state)
		State.JUMPING:
			new_anim = "jump"
			if rc_left.is_colliding() and rc_right.is_colliding():
				_state = State.IDLE
		State.ATTACKING:
			new_anim = "attack"
			print(attack_timer)
			if attack_timer <= 0:
				_state = State.IDLE
				attack_timer = ATTACK_COOLDOWN
	_handle_action_selection()
	if anim != new_anim:
		anim = new_anim
		($AnimationPlayer as AnimationPlayer).play(anim)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var velocity = state.get_linear_velocity()

	
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

func _handle_walking(state: PhysicsDirectBodyState2D) -> void:
	var velocity := state.get_linear_velocity()
	var wall_side := 0.0
	velocity.x = direction * WALK_SPEED
	state.set_linear_velocity(velocity)

func _handle_action_selection() -> void:
	var distance = global_position.distance_to(player.global_position)
	if distance <= 300 and _state == State.SLEEP:
		_jump_to_player()
	if _state != State.IDLE:
		return

	if player_on_left() and direction > 0:
		_flip_direction()
	elif  not player_on_left() and direction < 0:
		_flip_direction()
	if jump_timer <= 0 and randf() < 0.2:  # 10% chance to jump when cooldown is over
		_jump_to_player()
	elif attack_timer <= 0 and playerinhitbox:  # Attack when close and cooldown is over
		_attack()




func _jump() -> void:
	_state = State.JUMPING
	linear_velocity.y = JUMP_FORCE
	jump_timer = JUMP_COOLDOWN


func _attack() -> void:
	_state = State.ATTACKING
	attack_timer = $AnimationPlayer.get_animation("attack").length
	print("Atacking!")
	emit_signal("boss_attack", BOSS_ATTACK_DAMAGE)


func _flip_direction() -> void:
	direction = -direction
	($Sprite2D as Sprite2D).scale.x = -direction * SIZESCALE
	print("flipping!")

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
		emit_signal("boss_death")
		_state = State.DYING
		state.set_angular_velocity(signf(collision_normal.x) * 33.0)
		#physics_material_override.friction = 1
		state.get_linear_velocity().y = 10
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
		print("Player entered hitbox")
	else:
		print("Non-player body entered: ", body.name)

func _on_attack_hitbox_body_exited(body: Node2D) -> void:
	if body is Player:
		playerinhitbox = false
		print("Player exited hitbox")
	else:
		print("Non-player body exited: ", body.name)

func _jump_to_player():
	if player:
		_state = State.JUMPING
		jump_timer = JUMP_COOLDOWN
		print("Jumping!")
		var start_pos = global_position
		var end_pos = player.global_position

		# Calculate the jump arc
		var jump_velocity = Vector2(
			(end_pos.x - start_pos.x),
			-sqrt(2 * JUMP_HEIGHT * ProjectSettings.get_setting("physics/2d/default_gravity"))
		)
		linear_velocity = jump_velocity
		await get_tree().create_timer(JUMP_DURATION).timeout

func player_on_left():
	if player.global_position.x - global_position.x < 0:
		return true
	else: 
		return false
	
