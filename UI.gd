extends Control

onready var game := get_parent().get_node("ViewportContainer/MainGame")
onready var UI := $UIPanel/VBoxContainer
onready var tabs := UI.get_node("TurnsTabber")
onready var details := UI.get_node("GameDetails")

signal panic_game(game)

var lastTurn = -1
var lastGame = -1
var TurnsTab = preload("res://TurnHolder.tscn")

func set_headers():
    var currGame = game.currGame
    details.text = currGame.data.get("DisplayName", "New Game")+"\n"
    for data in currGame.data:
        if data == "DisplayName":
            continue
        details.text += data+" : "+currGame.data[data]+"\n"

func new_game(newGame: Game):
    var turnsTab = TurnsTab.instance()
    tabs.add_child(turnsTab)
    var idx = tabs.get_tab_count()-1
    tabs.set_tab_title(idx, newGame.data.get("DisplayName", "New Game"))
    for turn in newGame.turns:
        new_turn(idx, turn)
    tabs.set_current_tab(idx)

func new_turn(newGame: int, turn: Turn):
    if newGame >= tabs.get_tab_count():
        var tmpGame = Game.new()
        tmpGame.turns = [turn]
        emit_signal("panic_newGame", tmpGame)
        return
    var turnsList = tabs.get_tab_control(newGame).get_node("TurnsList")
    var i = turnsList.get_child_count()
    var button = Button.new()
    button.text = turn.ID
    button.name = "Button"+str(i)
    button.connect('pressed', self, 'set_turn', [i, newGame])
    turnsList.add_child(button)

func update_turn(newTurn, newGame):
    if lastGame >= 0 or lastTurn >= 0:
        var turnsList = tabs.get_tab_control(self.lastGame).get_node("TurnsList")
        turnsList.get_child(lastTurn).disabled = false
    var turnsList = tabs.get_tab_control(newGame).get_node("TurnsList")
    turnsList.get_child(newTurn).disabled = true
    turnsList.get_child(newTurn).grab_focus()
    self.lastTurn = newTurn
    self.lastGame = newGame
    set_headers()
    UI.get_node("TurnDetails/TurnNo").text = str(game.currGame.turns[newTurn].turnNo)

func set_turn(turn: int, idx: int = -1):
    self.game.load_turn(turn, idx)

func close_game() -> void:
    var idx = tabs.get_current_tab()
    
    # Delete from stored games
    game.games.remove(idx)
    self.lastGame = -1
    self.lastTurn = -1   

    reload_games()

func reload_games() -> void:
    # Remove old tabs
    for tab in tabs.get_children():
        tab.queue_free()
        tabs.remove_child(tab)
    # Recreate tabs
    for currGame in game.games:
        self.new_game(currGame)
        
func _error(title: String, message: String):
    get_tree().get_root().get_node("Root").error(title, message)

func _on_nextTurn_pressed() -> void:
    self.game.next_turn()

func _on_prevTurn_pressed() -> void:
    self.game.prev_turn()
