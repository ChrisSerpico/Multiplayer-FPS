extends TextureRect


@onready var animation_player = $AnimationPlayer


func play_hit():
	animation_player.play("hit")
