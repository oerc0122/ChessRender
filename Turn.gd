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
const STARTING_BOARD_STATE = {"WR1":Vector2(1,1),"WN1":Vector2(2,1),"WB1":Vector2(3,1),"WK":Vector2(4,1),"WQ":Vector2(5,1),"WB2":Vector2(6,1),"WN2":Vector2(7,1),"WR2":Vector2(8,1),
                              "WP1":Vector2(1,2),"WP2":Vector2(2,2),"WP3":Vector2(3,2),"WP4":Vector2(4,2),"WP5":Vector2(5,2),"WP6":Vector2(6,2),"WP7":Vector2(7,2),"WP8":Vector2(8,2),
                              "BR1":Vector2(1,8),"BN1":Vector2(2,8),"BB1":Vector2(3,8),"BQ":Vector2(4,8),"BK":Vector2(5,8),"BB2":Vector2(6,8),"BN2":Vector2(7,8),"BR2":Vector2(8,8),
                              "BP1":Vector2(1,7),"BP2":Vector2(2,7),"BP3":Vector2(3,7),"BP4":Vector2(4,7),"BP5":Vector2(5,7),"BP6":Vector2(6,7),"BP7":Vector2(7,7),"BP8":Vector2(8,7)}


var raw : String
var piece : String
var location : String
var turnNo : int
var player : int
var comment : String = ""
var positions : Dictionary
var capture : bool = false
var check : int = 0
var promote : String
var promotions : int = 0


func _init(colour: int = COLOUR.WHITE, boardState: Dictionary = STARTING_BOARD_STATE, turn: RegExMatch = null, nPromotions: int = 0, comment = null):
    self.player = colour
    self.positions = boardState
    if turn:
        self.raw = turn.get_string()
        self.turnNo = int(turn.get_string("turn"))
        self.capture = turn.get_string(self.get_colour()+"Capture") != ""
        self.check = "+#".find(turn.get_string(self.get_colour()+"Check")) + 1
        self.piece = self.which_piece(colour, turn.get_string(self.get_colour()+"Piece"),
                                            turn.get_string(self.get_colour()+"Disambiguation"),
                                            turn.get_string(self.get_colour()+"Location"))
        self.location = turn.get_string(self.get_colour()+"Location")
        self.move(self.piece, self.location)
        self.comment = turn.get_string("Comment")
    else:
        self.turnNo = 0

    if comment:
        self.comment += "; "+ comment

func standard_start():
    var currTurn = self
    currTurn.turnNo = 0
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

    # Ambiguous: need to do this manually
    var grid_pos = to_grid(pos)

    for poss in possibles:
        var ref = (grid_pos - positions[poss]).abs()
        match label:
            "Q":
                if ref.x == 0 or ref.y == 0 or ref.x == ref.y:
                    return poss
            "K":
                if ref.length_squared < 2:
                    return poss
            "N":
                if ref in KNIGHT_MOVES:
                    return poss
            "R":
                if ref.x == 0 or ref.y == 0:
                    return poss
            "B":
                if ref.x == ref.y:
                    return poss
            "P":
                if self.capture:
                    if ref.y == colour and abs(ref.x) == 1:
                        return poss
                if ((self.colour == COLOUR.WHITE and positions[poss].y == 2) or # Initial move of two
                    (self.colour == COLOUR.BLACK and positions[poss].y == 7)):
                    if ref.y in [self.colour, 2*self.colour]:
                        return poss
                    # En passant
                    if self.capture:
                        pass
                    
                else:
                    if ref.y == colour:
                        return poss
    return "Not found"

func to_grid(pos: String) -> Vector2:
    return Vector2(LET[pos[0]], int(pos[1]))

func from_grid(pos: Vector2) -> String:
    return NUM[pos[0]] + str(pos[1])

func move(piece, location):
    if self.promote:
        self.positions.erase(piece)
        piece = self.get_colour() + self.promote + char(65+self.promotions)
        self.promotions += 1

    self.positions[piece] = self.to_grid(location)

    if self.capture:
        for capturedPiece in self.positions:
            if self.positions[capturedPiece] == location:
                self.positions.erase(capturedPiece)

func get_colour() -> String:
    return COLOUR_NAMES[self.player]
