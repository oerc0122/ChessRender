extends Sprite
class_name Piece
enum TYPES {KING, QUEEN, BISHOP, KNIGHT, ROOK, PAWN}
enum COLOUR {WHITE=0, BLACK=1}
const PAWN_DIR = [1, -1]
const KNIGHT_MOVES = [Vector2(1,2),
                      Vector2(-1,2),
                      Vector2(-1,-2),
                      Vector2(1,-2),
                      Vector2(2,1),
                      Vector2(-2,1),
                      Vector2(-2,-1),
                      Vector2(2,-1)]
const TYPES_SAN = "KQBNRP"

var gridPos : Vector2
var type : int
var moved : bool = false
var colour : int
onready var board = get_parent()
var castled : int = 0
var ID : String

func _process(delta: float) -> void:
    if $Draggable.dragging:
        self.position = get_global_mouse_position()

func init(colour: int, type: int) -> void:
    self.colour = colour
    self.type = type
    self.set_frame(colour*6 + type)
    self.ID = get_name()

func can_move(newLoc, capture=false) -> bool:
    var raw = newLoc - self.gridPos
    var ref = raw.abs()
        
    match type:
        TYPES.QUEEN:
            return ref.x == 0 or ref.y == 0 or ref.x == ref.y
        TYPES.KING:
            if not self.moved and newLoc in [Vector2(3, self.colour*7+1), Vector2(7, self.colour*7+1)]:
                match int(newLoc.x):
                    3:
                        if (not newLoc in board.positions and
                            not newLoc + Vector2.RIGHT in board.positions and
                            not newLoc + Vector2.LEFT in board.positions and
                            Vector2(1,self.colour*7+1) in board.positions and
                            not board.positions[Vector2(1,self.colour*7+1)].moved):
                                self.castled = -1
                                return true
                    7:
                        if (not newLoc in board.positions and
                            not newLoc + Vector2.LEFT in board.positions and
                            Vector2(8,self.colour*7+1) in board.positions and
                            not board.positions[Vector2(8,self.colour*7+1)].moved):
                                self.castled = 1
                                return true
            return ref.length_squared() < 2
        TYPES.KNIGHT:
            return ref in KNIGHT_MOVES
        TYPES.ROOK:
            return ref.x == 0 or ref.y == 0
        TYPES.BISHOP:
            return ref.x == ref.y
        TYPES.PAWN:            
            if not self.moved:
                return ref.x == int(capture) and raw.y in [PAWN_DIR[self.colour], PAWN_DIR[self.colour]*2]
            else:
                return ref.x == int(capture) and raw.y == PAWN_DIR[self.colour]
        
    return false

func _on_Draggable_stopdrag() -> void:
    var mousePos = get_global_mouse_position()
    var newPos = board.world_to_map(mousePos)
    board.move_piece(self.gridPos, newPos)
    move_to_pos()

func move_to_pos():
    self.position = board.map_to_world(self.gridPos) + board.TILE_OFFSET

func get_ID() -> String:
    return "WB"[self.colour] + TYPES_SAN[self.type]
