extends Control


@onready var player_names = $PanelContainer/MarginContainer/HBoxContainer/PlayerNames
@onready var kills = $PanelContainer/MarginContainer/HBoxContainer/Kills
@onready var deaths = $PanelContainer/MarginContainer/HBoxContainer/Deaths

var scoreboard_label_scene = preload("res://ui/scoreboard/scoreboard_entry_label.tscn")
var tracked_players = {} # player peer id -> index


func _process(delta):
	if Input.is_action_pressed("show_score"):
		show()
	elif Input.is_action_just_released("show_score"):
		hide()


@rpc("any_peer", "call_local")
func add_player(player_peer_id: int, player_name: String):
	if tracked_players.has(player_peer_id):
		return
	
	var current_rows = player_names.get_child_count()
	tracked_players[player_peer_id] = current_rows
	
	var name_label = scoreboard_label_scene.instantiate() as Label
	var kills_label = scoreboard_label_scene.instantiate() as Label
	var deaths_label = scoreboard_label_scene.instantiate() as Label
	
	name_label.text = player_name
	kills_label.text = "0"
	deaths_label.text = "0"
	
	player_names.add_child(name_label)
	kills.add_child(kills_label)
	deaths.add_child(deaths_label)


@rpc("any_peer", "call_local")
func remove_player(player_peer_id: int):
	if not tracked_players.has(player_peer_id):
		return
	
	var index = tracked_players.get(player_peer_id)
	
	player_names.get_children()[index].queue_free()
	kills.get_children()[index].queue_free()
	deaths.get_children()[index].queue_free()
	
	tracked_players.erase(player_peer_id)
	
	# is this insane?
	for tracked_player_id in tracked_players:
		if tracked_players[tracked_player_id] > index:
			tracked_players[tracked_player_id] = tracked_players[tracked_player_id] - 1


@rpc("any_peer", "call_local")
func update_player_kda(player_peer_id: int, new_kills: int, new_deaths: int):
	if not tracked_players.has(player_peer_id):
		return
	
	var index = tracked_players.get(player_peer_id)
	
	var kills_label = kills.get_children()[index]
	var deaths_label = deaths.get_children()[index]
	
	kills_label.text = str(new_kills)
	deaths_label.text = str(new_deaths)
