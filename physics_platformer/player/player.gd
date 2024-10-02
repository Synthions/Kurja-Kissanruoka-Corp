class_name Player
extends RigidBody2D

@onready var healthBlocker := $"CanvasLayer/Area select/Selectable area/Void"

@onready var testtext := $CanvasLayer/TestText
const WALK_ACCEL = 1000.0
var WALK_DEACCEL = 100000.0
const WALK_MAX_VELOCITY = 200.0
const AIR_ACCEL = 250.0
const AIR_DEACCEL = 250.0
const JUMP_VELOCITY = 380.0
const STOP_JUMP_FORCE = 450.0
const MAX_SHOOT_POSE_TIME = 0.3
const MAX_FLOOR_AIRBORNE_TIME = 0.15
const ENEMY_COLLISION_DAMAGE = 10 #might want to vhange this
const BOSS_COLLISION_DAMAGE = 10

const BULLET_SCENE = preload("res://player/bullet.tscn")
const ENEMY_SCENE = preload("res://enemy/enemy.tscn")
const POPUP_SCENE = preload("res://Popups/Popup1.tscn")

@export var popup_scenes: Array[PackedScene] = []

var anim := ""
var siding_left := false
var jumping := false
var stopping_jump := false
var shooting := false

var invincible := false

var floor_h_velocity: float = 0.0

var airborne_time: float = 1e20
var shoot_time: float = 1e20

var health := 100

var blockerWidth: float

@onready var sound_jump := $SoundJump as AudioStreamPlayer2D
@onready var sound_shoot := $SoundShoot as AudioStreamPlayer2D
@onready var sprite := $Sprite2D as Sprite2D
@onready var sprite_smoke := sprite.get_node(^"Smoke") as CPUParticles2D
@onready var animation_player := $AnimationPlayer as AnimationPlayer
@onready var bullet_shoot := $BulletShoot as Marker2D
@onready var sound_damaged := $SoundDamaged as AudioStreamPlayer2D


func _ready() -> void:
	#var boss_node = get_node("/root/CityscapeStage/Boss")
	#boss_node.connect("boss_attack", _on_boss_attack_hit())
	blockerWidth = healthBlocker.scale.x
	update_health(100)
	#this is just making the body_entered call connect to on_body_entered in the code
	connect("body_entered", Callable(self, "_on_body_entered"))
		
		

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var velocity := state.get_linear_velocity()
	var step := state.get_step()

	var new_anim := anim
	var new_siding_left := siding_left

	# Get player input.
	var move_left := Input.is_action_pressed(&"move_left")
	var move_right := Input.is_action_pressed(&"move_right")
	var move_down := Input.is_action_pressed(&"move_down")
	var jump := Input.is_action_pressed(&"jump")
	var pressed_jump := Input.is_action_just_pressed(&"jump")
	var shoot := Input.is_action_pressed(&"shoot")
	var spawn := Input.is_action_just_pressed(&"spawn")
	var selfdamage := Input.is_action_just_pressed(&"selfdamage")
	var popup := Input.is_action_just_pressed(&"testpopup")
	var is_on_one_way_platform := false
	if spawn:
		_spawn_enemy_above.call_deferred()

	if selfdamage:
		selfdamage(10)

	if popup:
		_spawn_popup()

	# Deapply previous floor velocity.
	velocity.x -= floor_h_velocity
	floor_h_velocity = 0.0

	# Find the floor (a contact with upwards facing collision normal).
	var found_floor := false
	var floor_index := -1

	for contact_index in state.get_contact_count():
		var collision_normal := state.get_contact_local_normal(contact_index)
		var collider = state.get_contact_collider_object(contact_index)
		if collision_normal.dot(Vector2(0, -1)) > 0.6:
			found_floor = true
			floor_index = contact_index
			if collider is StaticBody2D and collider.is_in_group("one_way_platforms"):
				is_on_one_way_platform = true
				#print("Pancakes")
				break
	# A good idea when implementing characters of all kinds,
	# compensates for physics imprecision, as well as human reaction delay.
	if shoot and not shooting:
		_shot_bullet.call_deferred()
	else:
		shoot_time += step

	if found_floor:
		airborne_time = 0.0
	else:
		airborne_time += step # Time it spent in the air.

	var on_floor := airborne_time < MAX_FLOOR_AIRBORNE_TIME

	# Process jump.
	if jumping:
		if velocity.y > 0:
			# Set off the jumping flag if going down.
			jumping = false
		elif not jump:
			stopping_jump = true

		if stopping_jump:
			velocity.y += STOP_JUMP_FORCE * step

	if on_floor:
		# Process logic when character is on floor.
		if move_left and not move_right:
			if velocity.x > -WALK_MAX_VELOCITY:
				velocity.x -= WALK_ACCEL * step
		elif move_right and not move_left:
			if velocity.x < WALK_MAX_VELOCITY:
				velocity.x += WALK_ACCEL * step
		else:
			var xv := absf(velocity.x)
			xv -= WALK_DEACCEL * step
			if xv < 0:
				xv = 0
			velocity.x = signf(velocity.x) * xv

		# Check jump.
		if not jumping and jump and pressed_jump:
			velocity.y = -JUMP_VELOCITY
			jumping = true
			stopping_jump = false
			sound_jump.play()

		# Check siding.
		if velocity.x < 0 and move_left:
			new_siding_left = true
		elif velocity.x > 0 and move_right:
			new_siding_left = false
		if jumping:
			new_anim = "jumping"
		elif absf(velocity.x) < 0.1:
			if shoot_time < MAX_SHOOT_POSE_TIME:
				new_anim = "idle_weapon"
			else:
				new_anim = "idle"
		else:
			if shoot_time < MAX_SHOOT_POSE_TIME:
				new_anim = "run_weapon"
			else:
				new_anim = "run"
	else:
		# Process logic when the character is in the air.
		if move_left and not move_right:
			if velocity.x > -WALK_MAX_VELOCITY:
				velocity.x -= AIR_ACCEL * step
		elif move_right and not move_left:
			if velocity.x < WALK_MAX_VELOCITY:
				velocity.x += AIR_ACCEL * step
		else:
			var xv := absf(velocity.x)
			xv -= AIR_DEACCEL * step

			if xv < 0:
				xv = 0
			velocity.x = signf(velocity.x) * xv

		if velocity.y < 0:
			if shoot_time < MAX_SHOOT_POSE_TIME:
				new_anim = "jumping_weapon"
			else:
				new_anim = "jumping"
		else:
			if shoot_time < MAX_SHOOT_POSE_TIME:
				new_anim = "falling_weapon"
			else:
				new_anim = "falling"

	# Update siding.
	if new_siding_left != siding_left:
		if !new_siding_left:
			sprite.scale.x = -1
		else:
			sprite.scale.x = 1

		siding_left = new_siding_left

	# Change animation.
	if new_anim != anim:
		anim = new_anim
		animation_player.play(anim)

	shooting = shoot

	# Apply floor velocity.
	if found_floor:
		floor_h_velocity = state.get_contact_collider_velocity_at_position(floor_index).x
		velocity.x += floor_h_velocity

	# Finally, apply gravity and set back the linear velocity.
	velocity += state.get_total_gravity() * step
	state.set_linear_velocity(velocity)
	
	if is_on_one_way_platform and move_down:
		# Implement logic to fall through the platform
		position.y += 1  # Move player slightly down to trigger collision exit
		# Temporarily disable collision with one-way platforms
		set_collision_mask_value(2, false)  # Assuming one-way platforms are on layer 3
		await get_tree().create_timer(0.5).timeout
		set_collision_mask_value(2, true)  # Re-enable collision
		
	if position.y > 900: 
		selfdamage(100)


func _shot_bullet() -> void:
	shoot_time = 0
	var bullet := BULLET_SCENE.instantiate() as RigidBody2D
	var speed_scale: float
	if siding_left:
		speed_scale = -1.0
	else:
		speed_scale = 1.0

	bullet.position = position + bullet_shoot.position * Vector2(speed_scale, 1.0)
	get_parent().add_child(bullet)

	bullet.linear_velocity = Vector2(400.0 * speed_scale, -40)

	sprite_smoke.restart()
	sound_shoot.play()

	add_collision_exception_with(bullet) # Make bullet and this not collide.
	
	


func _spawn_enemy_above() -> void:
	var enemy := ENEMY_SCENE.instantiate() as RigidBody2D
	enemy.position = position + 50 * Vector2.UP
	get_parent().add_child(enemy)
	
func _spawn_popup() -> void:
	var popup := popup_scenes[randi() % popup_scenes.size()].instantiate() as Node2D
	popup.position = Vector2(randf_range(90, 715), randf_range(80, 400))
	$CanvasLayer.add_child(popup)
	

func damaged(dmg:int, damager: Node = null, knockback_force: int = 800):
	# Returns true if player recieved damage
	# Returns false if player had i-frames during damage (not hit)
	
	# Knockback is applied even if invincible
	if damager != null:
		if invincible: knockback_force *= 0.7 # while invincible player isn't inside a pinball machine
		var knockback_direction = damager.global_position.direction_to(global_position) * Vector2(1,0.5)
		if knockback_direction.y < 0: knockback_direction.y *= 0.5  # No spiking
		apply_impulse(knockback_direction * knockback_force)
	
	#Take damage
	if not invincible:
		health -= dmg
		sound_damaged.play()
		
		if health <= 0:
			health = 0
			die()
		else:
			invincibility()
			
		testtext.update_health(health)
		update_health(health)
		return true
	return false
		

func _on_boss_attack_hit():
	damaged(20)

func selfdamage(dmg:int):
	damaged(dmg)

func update_health(health: int) -> void:
	var multiplier = 1.0 - (health / 100.0)
	healthBlocker.scale.x = multiplier*blockerWidth

func die():
	respawn()

func respawn():
	get_tree().change_scene_to_file("res://respawn_menu.tscn")

func _on_body_entered(body: Node) -> void:
	if body is Enemy:
		damaged(ENEMY_COLLISION_DAMAGE, body)
	if body is Boss:
		damaged(ENEMY_COLLISION_DAMAGE, body)

func invincibility():
	invincible = true
	WALK_DEACCEL = 2000.0
	for i in range(16):
		await get_tree().create_timer(.05).timeout
		if i % 2 == 0:
			modulate.a = .5
		else:
			modulate.a = 1
		if i>7:
			WALK_DEACCEL = 100000.0
	invincible = false
