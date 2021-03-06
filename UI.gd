extends Control

onready var game = $ViewportContainer/Viewport/MainGame
onready var parser = $ViewportContainer/Viewport/MainGame/FileParser
onready var turnsList = $PanelContainer/VBoxContainer/Turns/VBoxContainer
var lastTurn = 0

func _ready() -> void:
    $PanelContainer/VBoxContainer/GameDetails.text = parser.path+"\n"
    for data in parser.data:
        $PanelContainer/VBoxContainer/GameDetails.text += data+" : "+parser.data[data]+"\n"

    var i = 0
    for turn in parser.turns:
        var button = Button.new()
        button.text = turn.ID
        button.name = "Button"+str(i)
        button.connect('pressed', self, 'set_turn', [i])
        turnsList.add_child(button)
        i += 1
    game.load_turn(0)

func update_turn(newTurn):
    turnsList.get_child(lastTurn).disabled = false
    turnsList.get_child(newTurn).disabled = true
    self.lastTurn = newTurn
    $PanelContainer/VBoxContainer/HBoxContainer/TurnNo.text = str(newTurn)

func set_turn(turn: int):
    self.game.load_turn(turn)

func _on_prevTurn_button_up() -> void:
    self.game.prev_turn()

func _on_nextTurn_button_up() -> void:
    self.game.next_turn()
