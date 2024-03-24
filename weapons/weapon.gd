extends Node3D
class_name Weapon


const DUCK_AMOUNT = 6


@export var dropped_version_scene: PackedScene
@export var fire_sound: AudioStreamPlayer3D

var quiet = false


func instantiate_dropped_version(to_parent: Node, with_velocity: Vector3):
	var dropped_version = dropped_version_scene.instantiate() as RigidBody3D
	dropped_version.position = global_position
	dropped_version.rotation = global_rotation
	dropped_version.linear_velocity = with_velocity
	to_parent.add_child(dropped_version)


@rpc("any_peer")
func play_fire_sound(duck_sound: bool = false):
	if duck_sound and not quiet:
		fire_sound.volume_db -= DUCK_AMOUNT
		quiet = true
	
	fire_sound.play()


func _on_fire_sound_finished():
	if quiet:
		quiet = false
		fire_sound.volume_db += DUCK_AMOUNT
