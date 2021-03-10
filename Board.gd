extends TileMap

onready var PIECE = preload("res://Piece.tscn")

const LET = {"a":1, "b":2, "c":3, "d":4, "e":5, "f":6, "g":7, "h":8}
const NUM = {1:"a", 2:"b", 3:"c", 4:"d", 5:"e", 6:"f", 7:"g", 8:"h"}

signal error(title, message) 
signal piece_moved(SAN)
var positions = {}
const TILE_OFFSET := Vector2(32,32)
onready var game = get_parent()

func add_piece(colour, type, pos):
    if pos in self.positions:
        emit_signal("error","Cannot add piece", "Tile "+str(pos)+" occupied") 
    var piece = PIECE.instance()
    piece.init(colour, type)
    add_child(piece)
    update_piece(piece, pos)
    piece.moved = false
    
func remove_piece(piece):
    piece.queue_free()
    self.positions.erase(piece)
    
func update_piece(piece, location: Vector2):
    if piece.gridPos in self.positions:
        self.positions.erase(piece.gridPos)
    piece.gridPos = location
    piece.position = self.map_to_world(piece.gridPos) + TILE_OFFSET
    piece.moved = true
    self.positions[piece.gridPos] = piece
    
func move_piece(pos:Vector2, newLoc:Vector2):
    if not pos in self.positions:
        emit_signal("error","Cannot move piece", "No piece in position")
        return
    if (newLoc.x * newLoc.y < 0) or newLoc.x > 8 or newLoc.y > 8:
        emit_signal("error","Cannot move piece", "Not on board")
        return
        
    var moving = self.positions[pos]
    var SAN = moving.TYPES_SAN[moving.type] + self.from_grid(pos)
    var capture = false
    var promote = false
    var target = null

    if moving.colour != game.currTurn:
        emit_signal("error","Cannot move piece", "Not current player")
        return
    
    if newLoc in self.positions:
        target = self.positions[newLoc]
        if target.colour != moving.colour:
            capture = true
        else:
            emit_signal("error","Cannot move piece", "Tile occupied")
            return

    if not moving.can_move(newLoc, capture):
        emit_signal("error","Cannot move piece", "Piece cannot move there")
        return            

    if target:
        self.remove_piece(target)
        
    self.update_piece(moving, newLoc)
        
    
    if capture:
        SAN += "x"
    if promote:
        SAN += "="+moving.TYPES_SAN[moving.type]
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
            
    emit_signal("piece_moved", SAN)
        
func to_grid(pos: String) -> Vector2:
    return Vector2(LET[pos[0]], int(pos[1]))

func from_grid(pos: Vector2) -> String:
    return NUM[int(pos.x)] + str(pos.y)

