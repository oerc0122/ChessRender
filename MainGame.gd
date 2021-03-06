extends Node

var piece = load("res://Piece.tscn")

func _ready():
    load_turn(0)


func load_turn(turn: int):
    var currTurn = $FileParser.turns[turn]
    for pos in currTurn.positions:
        var currPiece = piece.instance()
        var loc = $Board.map_to_world(currTurn.positions[pos])
        currPiece.frame = "KQBNRP".find(pos[1])
        currPiece.name = pos
        if pos[0] == "B":
            currPiece.frame+=6
        currPiece.position = loc
        add_child(currPiece)
