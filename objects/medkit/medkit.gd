extends Node3D


@onready var respawn_timer = $RespawnTimer
@onready var pickup_sound = $PickupSound
@onready var area_3d = $Area3D

@export var heal_amount = 2


@rpc("any_peer", "call_local")
func pick_up():
	area_3d.set_deferred("monitoring", false)
	respawn_timer.start()
	hide()


func respawn():
	area_3d.set_deferred("monitoring", true)
	show()


func _on_area_3d_body_entered(body):
	if body is Player and body.is_multiplayer_authority():
		var used_kit = body.heal_damage(heal_amount)
		
		if used_kit:
			pickup_sound.play()
			pick_up.rpc_id(1)
