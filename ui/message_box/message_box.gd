extends VBoxContainer
class_name MessageBox


const LABEL_SCENE = preload("res://ui/message_box/message_box_label.tscn")


@rpc('call_local')
func add_text(text: String):
	var new_label = LABEL_SCENE.instantiate()
	new_label.text = text
	add_child(new_label)
