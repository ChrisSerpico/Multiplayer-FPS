extends VBoxContainer
class_name MessageBox


const message_box_label_scene = preload("res://ui/message_box/message_box_label.tscn")


@rpc('call_local')
func add_text(text: String):
	var new_label = message_box_label_scene.instantiate()
	new_label.text = text
	add_child(new_label)
