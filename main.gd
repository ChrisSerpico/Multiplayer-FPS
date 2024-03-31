extends Node


@onready var main_menu = $CanvasLayer/MainMenu
@onready var display_name_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/DisplayNameEntry
@onready var host_port_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/HostPortEntry
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var join_port_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/JoinPortEntry

@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar
@onready var message_box: MessageBox = $CanvasLayer/HUD/MessageBox
@onready var hit_marker = $CanvasLayer/HUD/HitMarker

@onready var scoreboard = $CanvasLayer/Scoreboard

const PLAYER_SCENE = preload("res://player/player.tscn")
var player_data = {}

const DEFAULT_IP = "localhost"
const DEFAULT_PORT = 7777
var enet_peer = ENetMultiplayerPeer.new()


func _on_host_button_pressed():
	main_menu.hide()
	hud.show()
	
	enet_peer.create_server(host_port_entry.value)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())


func _on_join_button_pressed():
	main_menu.hide()
	hud.show()
	
	if address_entry.text == "":
		address_entry.text = "localhost" 
	
	enet_peer.create_client(address_entry.text, join_port_entry.value)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)


func add_player(peer_id):
	var player = PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	add_child(player)
	
	var player_color = Color(randf(), randf(), randf())
	player.set_color.rpc(player_color)
	
	# when a player joins, call rpcs on the instances of existing players so 
	# the new player's version of their instances matches
	for existing_player_id in player_data:
		var existing_player = player_data[existing_player_id]
		var existing_instance = existing_player.instance
		existing_instance.set_color.rpc_id(peer_id, existing_player.color)
		existing_instance.set_player_name.rpc_id(peer_id, existing_player.player_name)
		existing_instance.equip_weapon.rpc_id(peer_id, existing_instance.current_weapon_index)
		scoreboard.add_player.rpc_id(peer_id, existing_player_id, existing_player.player_name)
		scoreboard.update_player_kda.rpc_id(peer_id, existing_player_id, existing_player.kills, existing_player.deaths)
	
	player_data[peer_id] = PlayerData.new(player, "Bozo the Clown", player_color)
	player.killed.connect(_on_player_killed)
	
	# setup for server player
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)
		player.hit_shot.connect(hit_marker.play_hit)
		update_player_data(1, display_name_entry.text)


func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		message_box.add_text.rpc('Player ' + player_data[peer_id].player_name + ' has disconnected.')
		scoreboard.remove_player.rpc(peer_id)
		player_data.erase(peer_id)
		player.queue_free()


# This should probably be moved 
func update_health_bar(health_value):
	health_bar.value = health_value


@rpc("any_peer")
func update_player_data(peer_id: int, new_name: String):
	if peer_id != 1:
		add_player(peer_id)
	
	var pd = player_data.get(peer_id)
	
	if new_name != "":
		pd.player_name = new_name
	pd.instance.set_player_name.rpc(pd.player_name)
	
	message_box.add_text.rpc('Player ' + pd.player_name + ' has joined!')
	scoreboard.add_player.rpc(peer_id, pd.player_name)


func _on_multiplayer_spawner_spawned(node):
	if node is Player:
		if node.is_multiplayer_authority():
			node.health_changed.connect(update_health_bar)
			node.hit_shot.connect(hit_marker.play_hit)


func _on_connected_to_server():
	update_player_data.rpc_id(1, multiplayer.get_unique_id(), display_name_entry.text)


@rpc("any_peer")
func _on_player_killed(killed_id: int, killer_id: int):
	var killed = player_data.get(killed_id)
	var killer = player_data.get(killer_id)
	
	message_box.add_text.rpc(killer.player_name + ' killed ' + killed.player_name + '!')
	killed.deaths += 1
	killer.kills += 1
	
	scoreboard.update_player_kda.rpc(killed_id, killed.kills, killed.deaths)
	scoreboard.update_player_kda.rpc(killer_id, killer.kills, killer.deaths)


func _on_quit_button_pressed():
	get_tree().quit()


func _on_pause_menu_disconnect_pressed():
	get_tree().quit()
