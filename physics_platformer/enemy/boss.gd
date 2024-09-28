class_name Boss
extends RigidBody2D

const WALK_SPEED = 50

enum State {
	WALKING,
	DYING,
}

var _state := State.WALKING

var direction := -2
var anim := ""
var sizescale := 2
var health := 200
var player_damage := 20
var invincible := false

@onready var rc_left := $RaycastLeft as RayCast2D
@onready var rc_right := $RaycastRight as RayCast2D


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var velocity := state.get_linear_velocity()
	var new_anim := anim

	if _state == State.DYING:
		new_anim = "explode"
	elif _state == State.WALKING:
		new_anim = "walk"

		var wall_side := 0.0

		for collider_index in state.get_contact_count():
			var collider := state.get_contact_collider_object(collider_index)
			var collision_normal := state.get_contact_local_normal(collider_index)

			if collider is Bullet and not (collider as Bullet).disabled:
				_bullet_collider.call_deferred(collider, state, collision_normal)
				break

			if collision_normal.x > 0.9:
				wall_side = 1.0
			elif collision_normal.x < -0.9:
				wall_side = -1.0

		if wall_side != 0 and wall_side != direction:
			direction = -direction
			($Sprite2D as Sprite2D).scale.x = -direction
		if direction < 0 and not rc_left.is_colliding() and rc_right.is_colliding():
			direction = -direction
			($Sprite2D as Sprite2D).scale.x = -direction
		elif direction > 0 and not rc_right.is_colliding() and rc_left.is_colliding():
			direction = -direction
			($Sprite2D as Sprite2D).scale.x = -direction

		velocity.x = direction / sizescale * WALK_SPEED

	if anim != new_anim:
		anim = new_anim
		($AnimationPlayer as AnimationPlayer).play(anim)

	state.set_linear_velocity(velocity)


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


func _bullet_collider(
	collider: Bullet,
	state: PhysicsDirectBodyState2D,
	collision_normal: Vector2
) -> void:
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
