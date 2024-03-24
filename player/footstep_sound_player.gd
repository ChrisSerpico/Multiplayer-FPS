extends AudioStreamPlayer3D


var walking: bool = false


@rpc("any_peer", "call_local")
func walk():
	if walking:
		return
	
	play_sound()
	walking = true


@rpc("any_peer", "call_local")
func stop_walking():
	if not walking:
		return
	
	walking = false
	$Timer.stop()


func _on_timer_timeout():
	if walking:
		play_sound()


func play_sound():
	play()
	$Timer.start()
