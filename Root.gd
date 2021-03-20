extends Node

onready var UIMain = $VBoxContainer/HBoxContainer/UIPanel
onready var MainGame = $VBoxContainer/HBoxContainer/ViewportContainer/MainGame
onready var GamesList = $GamesDialog/ScrollContainer/VBoxContainer


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

func _on_FileParser_read(games: Array) -> void:
    # Build list
    for game in games:
        add_button(game)
    
    $GamesDialog.popup_centered()
    yield($GamesDialog, "popup_hide")
    for idx in range(GamesList.get_child_count()):
        if GamesList.get_child(idx).pressed:
            new_game(games[idx])

    for child in GamesList.get_children():
        child.queue_free()
        GamesList.remove_child(child)

func _on_TopMenu_load_game(file) -> void:
    $FileParser.read(file)

func _on_TopMenu_new_game() -> void:
    var game = Game.new()
    game.path = "New game"
    new_game(game)

func add_button(game: Game):
    var button = Button.new()
    button.toggle_mode = true
    button.text = "%s v. %s" % [game.data.get("White", "Unknown"), game.data.get("Black", "Unknown")]
    GamesList.add_child(button)
    GamesList.move_child(button, GamesList.get_child_count()-1)
