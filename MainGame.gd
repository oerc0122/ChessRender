extends Node

var piece = load("res://Piece.tscn")
const TILE_OFFSET := Vector2(32,32)

var turnID = 0
var nTurns = 0
signal turn_updated

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
        var currPiece = piece.instance()
        var loc = $Board.map_to_world(currTurn.positions[pos])
        currPiece.frame = "KQBNRP".find(pos[1])
        currPiece.name = pos
        if pos[0] == "B":
            currPiece.frame+=6
        currPiece.position = loc + TILE_OFFSET
        $Board.add_child(currPiece)
    emit_signal("turn_updated", self.turnID)
