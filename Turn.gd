extends Resource
class_name Turn

enum COLOUR {WHITE=0, BLACK=1}
const PAWN_DIR = [-1, 1]
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
const STARTING_BOARD_STATE = {"WR1":Vector2(1,8),"WN1":Vector2(2,8),"WB1":Vector2(3,8),"WQ1":Vector2(4,8),"WK1":Vector2(5,8),"WB2":Vector2(6,8),"WN2":Vector2(7,8),"WR2":Vector2(8,8),
                              "WP1":Vector2(1,7),"WP2":Vector2(2,7),"WP3":Vector2(3,7),"WP4":Vector2(4,7),"WP5":Vector2(5,7),"WP6":Vector2(6,7),"WP7":Vector2(7,7),"WP8":Vector2(8,7),
                              "BR1":Vector2(1,1),"BN1":Vector2(2,1),"BB1":Vector2(3,1),"BQ1":Vector2(4,1),"BK1":Vector2(5,1),"BB2":Vector2(6,1),"BN2":Vector2(7,1),"BR2":Vector2(8,1),
                              "BP1":Vector2(1,2),"BP2":Vector2(2,2),"BP3":Vector2(3,2),"BP4":Vector2(4,2),"BP5":Vector2(5,2),"BP6":Vector2(6,2),"BP7":Vector2(7,2),"BP8":Vector2(8,2)}


var raw : String
var ID : String
var piece : String
var from : String
var location : String
var turnNo : int
var player : int
var comment : String = ""
var positions : Dictionary
var capture : bool = false
var captureLocation = null
var check : int = 0
var promote : String
var promotions : int = 0
var castle: String

class DummyBoard:
    var positions: Dictionary = {}

func _init(colour: int = COLOUR.BLACK, boardState: Dictionary = STARTING_BOARD_STATE, turn: RegExMatch = null, nPromotions: int = 0, commentOverride = null):
    self.player = colour
    self.positions = boardState.duplicate()
    self.promotions = nPromotions
    if turn:
        self.raw = turn.get_string()
        self.turnNo = int(turn.get_string("turn"))
        self.capture = turn.get_string(self.get_colour()+"Capture") != ""
        self.check = "+#".find(turn.get_string(self.get_colour()+"Check")) + 1
        castle = turn.get_string(self.get_colour()+"Castle")
        if castle:
            self.castling(castle.count("O")==2)
            self.ID = self.get_colour() + " : " + castle
        else:
            self.promote = turn.get_string(self.get_colour()+"Promotion")
            self.piece = self.which_piece(colour, turn.get_string(self.get_colour()+"Piece"),
                                                turn.get_string(self.get_colour()+"Disambiguation"),
                                                turn.get_string(self.get_colour()+"Location"))
            self.location = turn.get_string(self.get_colour()+"Location")
            self.from = from_grid(self.positions[self.piece])
            self.move(self.piece, self.location)
            self.ID = self.get_ID()
        self.comment = turn.get_string("Comment")
    else:
        self.turnNo = 0
        self.ID = "Board start"

    if comment:
        self.comment += "; "+ commentOverride

func which_piece(colour, label, disamb, pos) -> String:
    # Determine which piece moved for parsing a FEN or PGN game
    var search : String
    match colour:
        COLOUR.WHITE:
            search = "W"
        COLOUR.BLACK:
            search = "B"
        _:
            return "Not found"

    if not label:
        label = "P"
    search += label

    var possibles := []
    for key in positions.keys():
        if key.left(2) == search:
            possibles.push_back(key)

    if len(possibles) == 0:
        printerr("No possible piece found")
        null.get_node("Crash")

    var tmp_poss = possibles.duplicate()
    if disamb: # Have disambiguation
        for poss in tmp_poss:
            if not disamb in self.from_grid(self.positions[poss]):
                possibles.erase(poss)
    tmp_poss.clear()

    # Ambiguous: need to do this manually
    var grid_pos = to_grid(pos)

    var board = DummyBoard.new()
    for pos in positions.values():
        board.positions[pos] = 1
    
    for poss in possibles:
        var trial_piece = Piece.new()
        trial_piece.init_from_name(poss, positions[poss])
        # Only care if pawns have moved
        if trial_piece.type == Piece.TYPES.PAWN:
            trial_piece.moved = ((trial_piece.colour == COLOUR.WHITE and trial_piece.gridPos.y != 7) or
                                (trial_piece.colour == COLOUR.BLACK and trial_piece.gridPos.y != 2))
            if self.capture and not grid_pos in board.positions: # En passant
                self.captureLocation = trial_piece.gridPos + Vector2.RIGHT*(grid_pos.x - trial_piece.gridPos.x)
        if trial_piece.can_move(grid_pos, self.capture, board):
            return poss

    null.get_node("Crash")
    return "Not found"

func to_grid(pos: String) -> Vector2:
    # Turn algebraic notation into gridPos 
    return Vector2(LET[pos[0]], 9-int(pos[1]))

func from_grid(pos: Vector2) -> String:
    # Turn gridPos into algebraic notation
    return NUM[int(pos.x)] + str(9-pos.y)

func move(piece, newLoc):
    # Simulate moving a piece between plies for parsing algebraic notation
    if self.promote:
        self.positions.erase(piece)
        piece = self.get_colour()[0] + self.promote + char(65+self.promotions)
        self.promotions += 1

    if self.capture:
        if self.captureLocation == null:
            self.captureLocation = to_grid(newLoc)
        
        for capturedPiece in self.positions:
            if self.positions[capturedPiece] == self.captureLocation:
                self.positions.erase(capturedPiece)

    self.positions[piece] = self.to_grid(newLoc)

func castling(kingside: bool):
    if kingside:
        if self.player == COLOUR.WHITE:
            self.move("WK1", "g1")
            self.move("WR2", "f1")
        else:
            self.move("BK1", "g8")
            self.move("BR2", "f8")
    else:
        if self.player == COLOUR.WHITE:
            self.move("WK1", "c1")
            self.move("WR1", "d1")
        else:
            self.move("BK1", "c8")
            self.move("BR1", "d8")
            
func get_ID() -> String:
    return "{turn}:{piece}{from} -> {to}".format({'turn':self.get_colour(), 
                                                  'piece':self.piece[1], 
                                                  'from':self.from,
                                                  'to':self.location})
func get_colour() -> String:
    return COLOUR_NAMES[self.player]

func _to_string() -> String:
    var string = ""
    if self.castle:
        string += self.castle
    else:
        var cap = "x" if self.capture else ""
        var prom = "="+self.promote if self.promote else ""
        string += "{Piece}{Disamb}{Capture}{MoveTo}{Promote}".format({"Piece":self.piece[1],
                                                            "Disamb":self.from,
                                                            "Capture": cap,
                                                            "MoveTo":self.location,
                                                            "Promote": prom
                                                            })
    if self.comment:
        string += " {%s}" % self.comment
    return string

func to_dict() -> Dictionary:
    return {"raw":self.raw, 
        "ID":self.ID, 
        "piece":self.piece, 
        "from":self.from, 
        "location":self.location, 
        "turnNo":self.turnNo, 
        "player":self.player, 
        "comment":self.comment, 
        "positions":self.positions, 
        "capture":self.capture, 
        "captureLocation":self.captureLocation,
        "check":self.check, 
        "promote":self.promote, 
        "promotions":self.promotions, 
        "castle":self.castle}
        
func from_dict(dict: Dictionary):
    for prop in dict:
        self.set("pop", dict[prop])
