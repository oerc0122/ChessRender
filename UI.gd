extends Control

onready var game := get_parent().get_node("ViewportContainer/MainGame")
onready var parser := game.get_node("FileParser")
onready var UI := $UIPanel/VBoxContainer
onready var tabs := UI.get_node("TurnsTabber")
onready var filePath := UI.get_node("FileControl/Path")
onready var details := UI.get_node("GameDetails")
var lastTurn = 0
var lastGame = 0
var TurnsTab = preload("res://TurnHolder.tscn")

func _ready():
    var file = File.new()
    file.open("res://tmp.pgn", File.WRITE)
    file.close()
    load_file("res://tmp.pgn", true)

func set_headers():
    var currGame = game.currGame
    details.text = currGame.path+"\n"
    for data in currGame.data:
        details.text += data+" : "+currGame.data[data]+"\n"

func load_file(path: String, init: bool = false):
    var newGame = parser.read(path)
    if init:
        newGame.path = "New Game"
    new_game(newGame)
    var idx = tabs.get_tab_count()-1
    set_turn(0, idx)

func new_game(newGame: Game):
    var turnsTab = TurnsTab.instance()
    tabs.add_child(turnsTab)
    var idx = tabs.get_tab_count()-1
    tabs.set_tab_title(idx, newGame.path)
    for turn in newGame.turns:
        new_turn(idx, turn)
    tabs.set_current_tab(idx)

func new_turn(game: int, turn: Turn):
    var turnsList = tabs.get_tab_control(game).get_node("TurnsList")
    var i = turnsList.get_child_count()
    var button = Button.new()
    button.text = turn.ID
    button.name = "Button"+str(i)
    button.connect('pressed', self, 'set_turn', [i, game])
    turnsList.add_child(button)

func update_turn(newTurn, newGame):
    var turnsList = tabs.get_tab_control(self.lastGame).get_node("TurnsList")
    turnsList.get_child(lastTurn).disabled = false
    turnsList = tabs.get_tab_control(newGame).get_node("TurnsList")
    turnsList.get_child(newTurn).disabled = true
    turnsList.get_child(newTurn).grab_focus()
    self.lastTurn = newTurn
    self.lastGame = newGame
    set_headers()
    UI.get_node("TurnDetails/TurnNo").text = str(game.currGame.turns[newTurn].turnNo)

func set_turn(turn: int, idx: int = -1):
    self.game.load_turn(turn, idx)

func _on_Search_pressed() -> void:
    $FileDialog.popup_centered()

func _on_FileDialog_file_selected(path: String) -> void:
    filePath.text = path

func _on_Load_pressed() -> void:
    var path: String = filePath.text
    if File.new().file_exists(path):
        load_file(path)
    else:
        _error("File not found", "File: "+path+" not found")

func _on_SaveGame_pressed() -> void:
    _error("Not implemented", "Saving of games not currently implemented")

func _on_CloseGame_pressed() -> void:
    var idx = tabs.get_current_tab()
    
    # Delete from stored games
    game.games.remove(idx)
    self.lastGame = 0
    self.lastTurn = 0    

    # Remove old tabs
    for tab in tabs.get_children():
        tab.queue_free()
        tabs.remove_child(tab)
    # Recreate tabs
    for currGame in game.games:
        self.new_game(currGame)

    if game.games.empty(): # Always have game
        load_file("res://tmp.pgn", true)    
        game.load_turn(0,0)
        
func _error(title: String, message: String):
    get_tree().get_root().get_node("Root").error(title, message)

func _on_nextTurn_pressed() -> void:
    self.game.next_turn()

func _on_prevTurn_pressed() -> void:
    self.game.prev_turn()

func _on_QuitButton_pressed() -> void:
    get_tree().quit()
