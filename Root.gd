extends Node

onready var UIMain = $VBoxContainer/HBoxContainer/UIPanel
onready var MainGame = $VBoxContainer/HBoxContainer/ViewportContainer/MainGame

func host(port: int, players: int):
    var peer = NetworkedMultiplayerENet.new()
    peer.create_server(port, players)
    get_tree().network_peer = peer

func client(ip: int, port: int):
    var peer = NetworkedMultiplayerENet.new()
    peer.create_client(ip, port)
    get_tree().network_peer = peer

func close_connection(id: int = -1):
    get_tree().network_peer = null

func new_game(game: Game):
    MainGame.new_game(game)

func error(title: String, message: String):
    $ErrorPopup.window_title = title
    $ErrorPopup/ErrorMessage.text = message
    $ErrorPopup.popup_centered()

func _on_FileParser_read(game) -> void:
    new_game(game)

func _on_TopMenu_load_game(file) -> void:
    $FileParser.read(file)

func _on_TopMenu_new_game() -> void:
    var game = Game.new()
    game.path = "New game"
    new_game(game)
