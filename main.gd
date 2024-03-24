extends Node


@onready var main_menu = $CanvasLayer/MainMenu
@onready var display_name_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/DisplayNameEntry
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry

@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar
@onready var message_box: MessageBox = $CanvasLayer/HUD/MessageBox
@onready var hit_marker = $CanvasLayer/HUD/HitMarker

const PLAYER_SCENE = preload("res://player.tscn")
var player_data = {}

const PORT = 7777
var enet_peer = ENetMultiplayerPeer.new()


func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()


func _on_host_button_pressed():
	main_menu.hide()
	hud.show()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_disconnected.connect(remove_player)
	
	print(multiplayer.get_unique_id())
	add_player(multiplayer.get_unique_id())


func _on_join_button_pressed():
	main_menu.hide()
	hud.show()
	
	if address_entry.text == "":
		address_entry.text = "localhost" 
	
	enet_peer.create_client(address_entry.text, PORT)
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
	for existing_player in player_data.values():
		var existing_instance = existing_player.instance
		existing_instance.set_color.rpc_id(peer_id, existing_player.color)
		existing_instance.set_player_name.rpc_id(peer_id, existing_player.player_name)
	
	player_data[peer_id] = PlayerData.new(player, "Bozo the Clown", player_color)
	
	# setup for server player
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)
		player.hit_shot.connect(hit_marker.play_hit)
		
		if display_name_entry.text != "":
			update_player_data(1, display_name_entry.text)


func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
		message_box.add_text.rpc('Player ' + player_data[peer_id].player_name + ' has disconnected.')


func update_health_bar(health_value):
	health_bar.value = health_value


@rpc("any_peer")
func update_player_data(peer_id: int, new_name: String):
	if peer_id != 1:
		add_player(peer_id)
	
	var pd = player_data.get(peer_id)
	
	if new_name != "":
		pd.player_name = new_name
		pd.instance.set_player_name.rpc(new_name)
	
	message_box.add_text.rpc('Player ' + pd.player_name + ' has joined!')


func _on_multiplayer_spawner_spawned(node):
	if node is Player:
		if node.is_multiplayer_authority():
			node.health_changed.connect(update_health_bar)
			node.hit_shot.connect(hit_marker.play_hit)


func _on_connected_to_server():
	update_player_data.rpc_id(1, multiplayer.get_unique_id(), display_name_entry.text)
