extends Node


@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry

@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar
@onready var message_box: MessageBox = $CanvasLayer/HUD/MessageBox

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
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())


func _on_join_button_pressed():
	main_menu.hide()
	hud.show()
	
	if address_entry.text == "":
		address_entry.text = "localhost" 
	
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer


func add_player(peer_id):
	var player = PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	add_child(player)
	
	var player_color = Color(randf(), randf(), randf())
	player.set_color.rpc(player_color)
	
	for existing_player in player_data.values():
		existing_player.instance.set_color.rpc_id(peer_id, existing_player.color)
	
	player_data[peer_id] = PlayerData.new(player, player_color)
	
	# connect health bar for server player
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)
	else:
	# sends whenever the server adds a player that isn't the server player		
		message_box.add_text.rpc('Player ' + player.name + ' has joined!')


func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
		message_box.add_text.rpc('Player ' + player.name + ' has disconnected.')


func update_health_bar(health_value):
	health_bar.value = health_value


func _on_multiplayer_spawner_spawned(node):
	if node is Player:
		if node.is_multiplayer_authority():
			node.health_changed.connect(update_health_bar)
