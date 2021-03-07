extends Sprite

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

var gridPos : Vector2
var type : int
var moved : bool = false
var colour : int
onready var board = get_parent()

func init(colour: int, type: int) -> void:
    self.colour = colour
    self.type = type
    self.set_frame(colour*6 + type)

func can_move(newLoc, capture=false) -> bool:
    var raw = newLoc - self.gridPos
    var ref = raw.abs()
    match type:
        TYPES.QUEEN:
            return ref.x == 0 or ref.y == 0 or ref.x == ref.y
        TYPES.KING:
            return ref.length_squared < 2
        TYPES.KNIGHT:
            return ref in KNIGHT_MOVES
        TYPES.ROOK:
            return ref.x == 0 or ref.y == 0
        TYPES.BISHOP:
            return ref.x == ref.y
        TYPES.PAWN:
            if not self.moved:
                return ref.x == int(capture) and raw in [PAWN_DIR[self.colour], PAWN_DIR[self.colour]*2]
            else:
                return ref.x == int(capture) and raw == PAWN_DIR[self.colour]
    return false

