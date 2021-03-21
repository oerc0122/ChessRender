extends Sprite
class_name Piece
enum TYPES {KING, QUEEN, BISHOP, KNIGHT, ROOK, PAWN}
enum COLOUR {WHITE=0, BLACK=1}
const PAWN_DIR = [-1, 1]
const KNIGHT_MOVES = [Vector2(1,2),
                      Vector2(-1,2),
                      Vector2(-1,-2),
                      Vector2(1,-2),
                      Vector2(2,1),
                      Vector2(-2,1),
                      Vector2(-2,-1),
                      Vector2(2,-1)]
const TYPES_SAN = "KQBNRP"

onready var board = self.get_parent()

var gridPos : Vector2
var type : int
var moved : bool = false
var colour : int
var castled : int = 0
var ID : String

func _process(delta: float) -> void:
    if $Draggable.dragging:
        rpc_unreliable("set_pos", get_global_mouse_position())

remotesync func set_pos(newPos: Vector2):
    self.position = newPos

func init(colour: int, type: int) -> void:
    self.colour = colour
    self.type = type
    self.set_frame(colour*6 + type)
    self.ID = get_name()

func init_from_name(code: String, pos: Vector2):
    self.init("WB".find(code[0]), TYPES_SAN.find(code[1]))
    self.gridPos = pos

func can_move(newLoc, capture: bool, boardIn) -> bool:
    var raw = newLoc - self.gridPos
    var ref = raw.abs()
    var mag = max(ref.x,ref.y)
    var dir = raw / mag

    if type != TYPES.KNIGHT: # Check not jumping
        for step in range(1,mag): # May land on piece on capture
            if self.gridPos + step*dir in boardIn.positions:
                return false

    match type:
        TYPES.QUEEN:
            return ref.x == 0 or ref.y == 0 or ref.x == ref.y
        TYPES.KING:
            if not self.moved and newLoc in [Vector2(3, self.colour*7+1), Vector2(7, self.colour*7+1)]:
                match int(newLoc.x):
                    3:
                        if (not newLoc in boardIn.positions and
                            not newLoc + Vector2.RIGHT in boardIn.positions and
                            not newLoc + Vector2.LEFT in boardIn.positions and
                            Vector2(1,self.colour*7+1) in boardIn.positions and
                            not boardIn.positions[Vector2(1,self.colour*7+1)].moved):
                                self.castled = -1
                                return true
                    7:
                        if (not newLoc in boardIn.positions and
                            not newLoc + Vector2.LEFT in boardIn.positions and
                            Vector2(8,self.colour*7+1) in boardIn.positions and
                            not boardIn.positions[Vector2(8,self.colour*7+1)].moved):
                                self.castled = 1
                                return true
            return ref.x < 2 and ref.y < 2
        TYPES.KNIGHT:
            return ref in KNIGHT_MOVES
        TYPES.ROOK:
            return ref.x == 0 or ref.y == 0
        TYPES.BISHOP:
            return ref.x == ref.y
        TYPES.PAWN:            
            if not self.moved and not capture:
                return (ref.x == 0 and raw.y in [self.move_dir(), 2*self.move_dir()])
            return ref.x == int(capture) and raw.y == self.move_dir()
        
    return false

func _on_Draggable_stopdrag() -> void:
    var mousePos = get_global_mouse_position()
    var newPos = board.world_to_map(mousePos)
    board.rpc("move_piece", self.gridPos, newPos)
    rpc("move_to_pos")

func move_to_pos():
    self.position = board.map_to_world(self.gridPos) + board.TILE_OFFSET

func get_ID() -> String:
    return "WB"[self.colour] + TYPES_SAN[self.type]

func move_dir() -> int:
    return PAWN_DIR[self.colour]
