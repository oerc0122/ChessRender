extends TileMap
class_name Board
onready var PIECE = preload("res://Piece.tscn")
onready var game = get_parent()

const LET = {"a":1, "b":2, "c":3, "d":4, "e":5, "f":6, "g":7, "h":8}
const NUM = {1:"a", 2:"b", 3:"c", 4:"d", 5:"e", 6:"f", 7:"g", 8:"h"}
const TILE_OFFSET := Vector2(32,32)

signal error(title, message) 
signal piece_moved(turn)
signal promoted

var positions = {}
var promoteTo = 0

func add_piece(colour, type, pos, has_moved:bool = false):
    if pos in self.positions: # Occupied
        push_error("Cannot add piece. Tile "+str(pos)+" occupied")
        push_error("%d %d" % [colour, type])
        null.get_node("Crash")

    var piece = PIECE.instance()
    piece.init(colour, type)
    
    # Find used names
    var currNames = []
    currNames.resize(self.positions.size())
    var i = 0
    for val in self.positions.values():
        currNames[i] = val.ID
        i += 1
        
    # Calculate new name
    i = 1
    var trial_name = piece.get_ID()+str(i)
    while trial_name in currNames:
        i += 1
        trial_name = piece.get_ID()+str(i)
    piece.ID = trial_name
    add_child(piece)
    update_piece(piece, pos)
    piece.moved = has_moved
    
func remove_piece(piece):
    self.positions.erase(piece)
    self.remove_child(piece)
    piece.queue_free()
    
func clear_board():
    for piece in self.positions.values():
        self.remove_piece(piece)
    self.positions.clear()
    
func update_piece(piece, location: Vector2):
    if piece.gridPos in self.positions:
        self.positions.erase(piece.gridPos)
    piece.gridPos = location
    piece.moved = true
    self.positions[piece.gridPos] = piece
    piece.move_to_pos()

remotesync func move_piece(pos:Vector2, newLoc:Vector2):
    if not pos in self.positions:
        emit_signal("error","Cannot move piece", "No piece in position")
        return
    if (newLoc.x * newLoc.y < 0) or newLoc.x > 8 or newLoc.y > 8:
        emit_signal("error","Cannot move piece", "Not on board")
        return
    if pos == newLoc: # No movement
        return
        
    var moving : Piece = self.positions[pos]
    var SAN = moving.TYPES_SAN[moving.type] + self.from_grid(pos)
    var turn := Turn.new()
    var target : Piece
    turn.piece = moving.ID
    turn.from = from_grid(pos)
    turn.player = game.currPlayer
    turn.turnNo = game.currTurn + 1
    turn.location = from_grid(newLoc)

    if moving.colour != game.currPlayer:
        emit_signal("error","Cannot move piece", "Not current player")
        return
    
    if newLoc in self.positions:
        target = self.positions[newLoc]
        if target.colour != moving.colour:
            turn.capture = true
            turn.captureLocation = target.gridPos
        else:
            emit_signal("error","Cannot move piece", "Tile occupied")
            return

    if not moving.can_move(newLoc, turn.capture, self):
        emit_signal("error","Cannot move piece", "Piece cannot move there")
        return

    if target:
        self.remove_piece(target)

    self.update_piece(moving, newLoc)
    
    if moving.type == moving.TYPES.PAWN and newLoc.y == 7*(1-moving.colour)+1:
        $PromoteDialogue.popup_centered()
        yield(self, "promoted")
        turn.promotions = self.promoteTo
        moving.init(moving.colour, self.promoteTo)
        turn.promote = "="+moving.TYPES_SAN[moving.type]
    
    if turn.capture:
        SAN += "x"
    if turn.promote:
        SAN += turn.promote
    
    SAN += self.from_grid(newLoc)
    match moving.castled:
        -1: 
            SAN = "O-O"
            var rook = self.positions[Vector2(1,moving.colour*7+1)]
            update_piece(rook, Vector2(3,moving.colour*7+1))
            moving.castled = 0
        1:
            SAN = "O-O-O"
            var rook = self.positions[Vector2(8,moving.colour*7+1)]
            update_piece(rook, Vector2(6,moving.colour*7+1))
            moving.castled = 0
   
    turn.positions = self.to_pos()
    turn.raw = SAN
    turn.ID = turn.get_ID()
    emit_signal("piece_moved", turn)
        
func to_grid(pos: String) -> Vector2:
    return Vector2(LET[pos[0]], 9-int(pos[1]))

func from_grid(pos: Vector2) -> String:
    return NUM[int(pos.x)] + str(9-pos.y)

func promote(sel : int) -> void:
    self.promoteTo = sel
    $PromoteDialogue.hide()
    emit_signal("promoted")
    
func to_pos() -> Dictionary:
    var dictOut = {}
    for child in self.get_children():
        if child is Piece:
            dictOut[child.ID] = child.gridPos
    return dictOut
