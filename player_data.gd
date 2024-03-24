extends Resource
class_name PlayerData


var instance: Player
var color: Color


func _init(init_instance: Player, init_color: Color):
	instance = init_instance
	color = init_color
