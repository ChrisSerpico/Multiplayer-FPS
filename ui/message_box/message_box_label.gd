extends Label


@onready var animation_player = $AnimationPlayer


func _on_label_fade_out_timer_timeout():
	animation_player.play("fade_out")


func _on_animation_player_animation_finished(anim_name):
	queue_free()
