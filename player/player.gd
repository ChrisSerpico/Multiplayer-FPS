extends CharacterBody3D
class_name Player


signal health_changed(new_health)
signal hit_shot()
signal killed(player_id: int, killed_by_id: int)


const DROPPED_PISTOL_SCENE = preload("res://weapons/pistol/pistol_obj.tscn")

@onready var camera = $Camera3D
@onready var animation_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D
@onready var mesh_instance_3d = $MeshInstance3D
@onready var pistol: Weapon = $Camera3D/Pistol
@onready var name_label = $Label3D
@onready var hit_sound = $HitSound
@onready var footstep_sound = $FootstepSound

var health = 3

const SPEED = 10.0
const JUMP_VELOCITY = 9.0
const CAMERA_SENSITIVITY = .0012

var gravity = 20.0


func _enter_tree():
	set_multiplayer_authority(str(name).to_int())


func _ready():
	if not is_multiplayer_authority():
		return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true


func _unhandled_input(event):
	if not is_multiplayer_authority():
		return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * CAMERA_SENSITIVITY)
		camera.rotate_x(-event.relative.y * CAMERA_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if Input.is_action_just_pressed("shoot") and animation_player.current_animation != "shoot":
		var hit_player = false
		play_shoot_effects.rpc()
		
		if raycast.is_colliding():
			var hit_object = raycast.get_collider()
			
			if hit_object is Player:
				hit_player = true
				hit_sound.play()
				hit_shot.emit()
				hit_object.receive_damage.rpc_id(hit_object.get_multiplayer_authority(), multiplayer.get_unique_id())
		
		pistol.play_fire_sound(hit_player)
		pistol.play_fire_sound.rpc()


func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if animation_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		animation_player.play("move")
		footstep_sound.walk.rpc()
	else:
		animation_player.play("idle")
		footstep_sound.stop_walking.rpc()

	move_and_slide()


@rpc("call_local")
func play_shoot_effects():
	animation_player.stop()
	animation_player.play("shoot")
	muzzle_flash.restart()


@rpc("any_peer")
func receive_damage(damager_id: int):
	health -= 1
	
	if health <= 0:
		die.rpc(damager_id)
		
		health = 3
		position = Vector3.ZERO
	
	health_changed.emit(health)


@rpc("any_peer", "call_local")
func die(killer_id: int):
	killed.emit(str(name).to_int(), killer_id)
	pistol.instantiate_dropped_version(get_parent(), get_real_velocity() * 10)


@rpc("any_peer", "call_local")
func set_color(new_color: Color):
	var material = StandardMaterial3D.new()
	material.albedo_color = new_color
	mesh_instance_3d.material_override = material


@rpc("any_peer", "call_local")
func set_player_name(name: String):
	name_label.text = name


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		animation_player.play("idle")
