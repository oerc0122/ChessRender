extends Node

signal sync_games(id)

const PLAYERS = 2
const HOST_ID = 1
var pw: String = ""
var my_id: int
var targetIP: String
var targetPort: int

func _ready() -> void:
    get_tree().connect("network_peer_connected", self, "_player_connected")
    get_tree().connect("network_peer_disconnected", self, "_close_connection")
    get_tree().connect("connection_failed", self, "_connection_failed")
    get_tree().connect("server_disconnected", self, "_server_disconnected")
    self._close_connection()

func host(port: int, pwIn: String):
    _close_connection() # In case of restart
    var peer = NetworkedMultiplayerENet.new()
    peer.create_server(port, PLAYERS)
    get_tree().set_network_peer(peer)
    my_id = HOST_ID
    self.pw = pwIn

func client(ip: String, port: int, pwIn: String):
    _close_connection() # In case of restart
    self.targetIP = ip
    self.targetPort = port
    self.pw = pwIn
    get_tree().connect("connected_to_server", self, "_connected_to_server")
    var peer = NetworkedMultiplayerENet.new()
    peer.create_client(self.targetIP, self.targetPort)
    get_tree().set_network_peer(peer)

func _check_pw(id, pwIn):
    if pwIn != pw:
        rpc_id(id, "error", "Cannot join", "Passwords don't match")
    get_tree().network_peer.disconnect_peer(id)

remote func _close_connection():
    if get_tree().network_peer:
        get_tree().network_peer.close_connection()
    var peer = NetworkedMultiplayerENet.new()
    peer.create_server(10000, 1)
    get_tree().set_network_peer(peer)

func _player_connected(id: int):
    emit_signal("sync_games", id)

func _connection_failed():
    _close_connection()
    error("Connection failed", "Could not establish connection to %s:%d" % [self.targetIP, self.targetPort]) 

func _connected_to_server():
    self.my_id = get_tree().get_network_unique_id()
    rpc_id(HOST_ID, "check_pw", self.my_id, self.pw)
    
func error(title, message):
    get_parent().error(title, message)
