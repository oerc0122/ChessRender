extends Resource
class_name Turn

enum COLOUR {WHITE=1, BLACK=-1}
const COLOUR_NAMES = {COLOUR.WHITE:"White", COLOUR.BLACK:"Black"}
const LET = {"a":1, "b":2, "c":3, "d":4, "e":5, "f":6, "g":7, "h":8}
const NUM = {1:"a", 2:"b", 3:"c", 4:"d", 5:"e", 6:"f", 7:"g", 8:"h"}
const KNIGHT_MOVES = [Vector2(1,2),
                      Vector2(-1,2),
                      Vector2(-1,-2),
                      Vector2(1,-2),
                      Vector2(2,1),
                      Vector2(-2,1),
                      Vector2(-2,-1),
                      Vector2(2,-1)]

var raw : String
var piece : String
var location : String
var turnNo : int
var player : int
var comment : String
var positions : Dictionary
var capture : bool = false
var check : int = 0

func standard_start():
    var currTurn = self
    currTurn.turnNo = 0
    currTurn.positions = {"WR1":Vector2(1,1),"WN1":Vector2(1,2),"WB1":Vector2(1,3),"WK":Vector2(1,4),"WQ":Vector2(1,5),"WB2":Vector2(1,6),"WN2":Vector2(1,7),"WR2":Vector2(1,8),
                          "WP1":Vector2(2,1),"WP2":Vector2(2,2),"WP3":Vector2(2,3),"WP4":Vector2(2,4),"WP5":Vector2(2,5),"WP6":Vector2(2,6),"WP7":Vector2(2,7),"WP8":Vector2(2,8),
                          "BR1":Vector2(8,1),"BN1":Vector2(8,2),"BB1":Vector2(8,3),"BQ":Vector2(8,4),"BK":Vector2(8,5),"BB2":Vector2(8,6),"BN2":Vector2(8,7),"BR2":Vector2(8,8),
                          "BP1":Vector2(7,1),"BP2":Vector2(7,2),"BP3":Vector2(7,3),"BP4":Vector2(7,4),"BP5":Vector2(7,5),"BP6":Vector2(7,6),"BP7":Vector2(7,7),"BP8":Vector2(7,8)}
    currTurn.comment = "Start game"
    return currTurn

func which_piece(colour, label, disamb, pos) -> String:
    var check : String
    if colour == COLOUR.WHITE:
        check = "W"
    else:
        check = "B"
    
    if not label:
        label = "P"
    check += label
    
    var possibles := []
    for key in positions.keys():
        if key.left(2) == check:
            possibles.push_back(key)
    
    if len(possibles) == 0:
        printerr("No possible piece found")
    elif len(possibles) == 1:
        return possibles[0]
    
    if disamb: # Have disambiguation
        for poss in possibles:
            if disamb in positions[poss]:
                return poss
            
    # Need to do this manually
    var grid_pos = to_grid(pos)
    
    for poss in possibles:
        var ref = abs(grid_pos - positions[poss])
        if label == "Q": # Ambiguous
            if ref.x == 0 or ref.y == 0 or ref.x == ref.y:
                return poss
        elif label == "K":
            if ref.length_squared < 2:
                return poss
        elif label == "N":
            if ref in KNIGHT_MOVES:
                return poss
        elif label == "R":
            if ref.x == 0 or ref.y == 0:
                return poss
        elif label == "B":
            if ref.x == ref.y:
                return poss
        elif label == "P":
            if self.capture:
                if ref.y == colour and abs(ref.x) == 1:
                    return poss      
            else:
                if ref.y == colour:
                    return poss
    return "Not found"

func to_grid(pos: String) -> Vector2:
    return Vector2(LET[pos[0]], int(pos[1]))

func from_grid(pos: Vector2) -> String:
    return NUM[pos[0]] + str(pos[1])

func move(piece, location):
    pass

func calc_turn(colour: int, boardState: Dictionary, turn: RegExMatch):
    self.turnNo = int(turn.get_string("turn"))
    self.player = colour
    self.capture = turn.get_string(COLOUR_NAMES[colour]+"Capture") != ""
    self.check = "+#".find(turn.get_string(COLOUR_NAMES[colour]+"Check")) + 1
    self.positions = boardState
    self.piece = self.which_piece(colour, turn.get_string(COLOUR_NAMES[colour]+"Piece"), 
                                          turn.get_string(COLOUR_NAMES[colour]+"Disambiguation"), 
                                          turn.get_string(COLOUR_NAMES[colour]+"Location"))
    self.positions = self.move(piece, location)
