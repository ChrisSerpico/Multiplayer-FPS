extends Node3D
class_name Weapon


const DUCK_AMOUNT = 6


@export var damage: int
@export var dropped_version_scene: PackedScene
@export var fire_sound: AudioStreamPlayer3D
@export var muzzle_flash: GPUParticles3D

var quiet = false


func instantiate_dropped_version(to_parent: Node, with_velocity: Vector3):
	var dropped_version = dropped_version_scene.instantiate() as RigidBody3D
	dropped_version.position = global_position
	dropped_version.rotation = global_rotation
	dropped_version.linear_velocity = with_velocity
	to_parent.add_child(dropped_version)


@rpc("call_local")
func play_fire_effects():
	$AnimationPlayer.stop()
	$AnimationPlayer.play("shoot")
	muzzle_flash.restart()


@rpc("any_peer")
func play_fire_sound(duck_sound: bool = false):
	if duck_sound and not quiet:
		fire_sound.volume_db -= DUCK_AMOUNT
		quiet = true
	
	fire_sound.play()


func get_current_animation():
	return $AnimationPlayer.current_animation


func play_animation(anim_name: String):
	$AnimationPlayer.play(anim_name)


func _on_fire_sound_finished():
	if quiet:
		quiet = false
		fire_sound.volume_db += DUCK_AMOUNT


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		$AnimationPlayer.play("idle")
