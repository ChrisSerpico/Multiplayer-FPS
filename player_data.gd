extends Resource
class_name PlayerData


var instance: Player
var player_name: String
var color: Color


func _init(init_instance: Player, name: String, init_color: Color):
	instance = init_instance
	player_name = name
	color = init_color
