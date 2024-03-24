extends AudioStreamPlayer3D


var walking: bool = false


func walk():
	if walking:
		return
	
	play_sound()
	walking = true


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
