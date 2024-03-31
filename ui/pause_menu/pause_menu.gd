extends Control


@onready var volume_slider = $PanelContainer/MarginContainer/VBoxContainer/VolumeSlider
@onready var audio_bus_index = AudioServer.get_bus_index("Master")


# Called when the node enters the scene tree for the first time.
func _ready():
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(audio_bus_index))


func _on_volume_slider_value_changed(value):
	AudioServer.set_bus_volume_db(audio_bus_index, linear_to_db(volume_slider.value))


func _unhandled_input(event):
	if event.is_action_pressed("quit"):
		if visible:
			hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			show()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
