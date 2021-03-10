extends Node

var turnID = 0
var nTurns = 0
signal turn_updated
var fileParsers := []
var currFileParser = 0
var currTurn = 0

func update_turns():
    self.nTurns = len($FileParser.turns)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed('ui_right'):
        self.next_turn()
    if event.is_action_pressed("ui_left"):
        self.prev_turn()
        
func next_turn():
    self.turnID = clamp(self.turnID+1, 0, nTurns-1)
    load_turn(turnID)       

func prev_turn():
    self.turnID = clamp(self.turnID-1, 0, nTurns-1)
    load_turn(turnID)
    
func load_turn(turn: int):
    self.turnID = turn
    var currTurn = $FileParser.turns[turn]
    for child in $Board.get_children(): # Clear old children
       child.queue_free()
    for pos in currTurn.positions:
        $Board.add_piece("WB".find(pos[0]),"KQBNRP".find(pos[1]),currTurn.positions[pos])
    emit_signal("turn_updated", self.turnID)


func _on_Board_piece_moved(SAN) -> void:
    self.currTurn = 1 - self.currTurn
