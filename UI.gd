extends Control

onready var game = $MainGame
onready var parser = game.get_node("FileParser")
onready var turnsList = $PanelContainer/VBoxContainer/Turns/VBoxContainer
var lastTurn = 0

func _ready():
    var file = File.new()
    file.open("res://tmp.pgn", File.WRITE)
    file.close()
    load_file("res://tmp.pgn")

func load_file(path):
    parser.read(path)
    
    $PanelContainer/VBoxContainer/GameDetails.text = parser.path+"\n"
    for data in parser.data:
        $PanelContainer/VBoxContainer/GameDetails.text += data+" : "+parser.data[data]+"\n"

    # Remove old buttons
    for child in turnsList.get_children():
        child.queue_free()

    var i = 0
    for turn in parser.turns:
        var button = Button.new()
        button.text = turn.ID
        button.name = "Button"+str(i)
        button.connect('pressed', self, 'set_turn', [i])
        turnsList.add_child(button)
        i += 1
    game.load_turn(0)

func quit():
    get_tree().quit()

func update_turn(newTurn):
    turnsList.get_child(lastTurn).disabled = false
    turnsList.get_child(newTurn).disabled = true
    turnsList.get_child(newTurn).grab_focus()
    self.lastTurn = newTurn
    $PanelContainer/VBoxContainer/HBoxContainer/TurnNo.text = str(parser.turns[newTurn].turnNo)

func set_turn(turn: int):
    self.game.load_turn(turn)

func _on_prevTurn_button_up() -> void:
    self.game.prev_turn()

func _on_nextTurn_button_up() -> void:
    self.game.next_turn()

func _on_Search_pressed() -> void:
    $FileDialog.popup_centered()

func _on_FileDialog_file_selected(path: String) -> void:
    $PanelContainer/VBoxContainer/HBoxContainer3/Path.text = path

func _on_Load_pressed() -> void:
    var path: String = $PanelContainer/VBoxContainer/HBoxContainer3/Path.text
    if File.new().file_exists(path):
        load_file(path)
    else:
        _error("File not found", "File: "+path+" not found")
        
func _error(title: String, message: String):
    $ErrorPopup.window_title = title
    $ErrorPopup/ErrorMessage.text = message
    $ErrorPopup.popup_centered()
