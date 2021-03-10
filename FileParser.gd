extends Node

var path := ""
var data := {}
var turns := [Turn.new()]
const COLOURS = ["White", "Black"]
signal read
signal error(title, message) 

func _ready():
    turns = [Turn.new()]

func read(filepath):
    self.turns = []
    self.path = filepath
    var file := File.new()
    var status = file.open(self.path, File.READ)
    
    if status:
        printerr("Cannot open file: ", self.path)
    var content := file.get_as_text()
    file.close()

    var rawCommentRE = RegEx.new()
    rawCommentRE.compile(";(?<comment>.*)")    
    var tagRE = RegEx.new()
    tagRE.compile("\\[(?<key>[A-Za-z]+) *\"(?<value>[^\"]+)\"\\]")
    var moveRE = ("(?<Piece>[NKQRBP]?)"+
                  "(?<Disambiguation>(?:[a-h]|[1-8]|[a-h][1-8])(?=x?[a-h][1-8]))?"+
                  "(?<Capture>x)?"+
                  "(?<Location>[a-h][1-8])"+
                  "(?:=(?<Promotion>[NKQRB]))?"+
                  "(?<Check>[+#])?")
    var commentRE = "\\{(?<comment>[^}]+)\\}"
    var turnRE = RegEx.new()
    turnRE.compile("(?<turn>[0-9]+)\\.\\s*" +
                   "("+moveRE.replace("?<","?<White")+"|(?<WhiteCastle>O-O(?:-O)?))\\s*" +
                   "("+moveRE.replace("?<","?<Black")+"|(?<BlackCastle>O-O(?:-O)?))\\s*" +
                   "(?:"+commentRE+")?"
                   )

    content = rawCommentRE.sub(content, "{$comment}", true).strip_escapes()

    for tag in tagRE.search_all(content):
        data[tag.get_string("key")] = tag.get_string("value")
        content = content.replace(tag.get_string(), "")


    var currTurn : Turn
    if not "SetUp" in data:
        currTurn = Turn.new()
        currTurn.raw = "0. Start game"
    else:
        if not "FEN" in data:
            emit_signal("error", "Bad input pgn", "FEN data not found")
        currTurn = parse_FEN(data["FEN"])
        currTurn.raw = "0. Start game"
        currTurn.ID = "Start Game"
    turns.push_back(currTurn)
        
        
    for turn in turnRE.search_all(content):
        currTurn = Turn.new(Turn.COLOUR.WHITE, currTurn.positions, turn, currTurn.promotions)
        turns.push_back(currTurn)
        currTurn = Turn.new(Turn.COLOUR.BLACK, currTurn.positions, turn, currTurn.promotions)
        turns.push_back(currTurn)
        
    emit_signal("read")

func parse_FEN(FEN: String):
    # Parse FEN notation of the form:
    # rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
    # BoardLayout player castling enPassant turnSinceMove turnNo
    var turn = Turn.new()
    var line = FEN.split(' ')
    var layout = line[0]
    var i = 1
    var j = 0
    var count = 0
    var label : String
    for row in layout.split('/'):
        j = 0
        for col in row:
            if col.is_valid_integer():
                j += int(col)
            elif col in "kqrbnp":
                label = "W" + col.to_upper() + count
                count += 1
            elif col in "KQRBNP":
                label = "B" + col + count
                count += 1
            turn.positions[label] = Vector2(i,j)
            j += 1
        i += 1    
    turn.player = "wb".find(line[1])
    turn.turnNo = line[5]
    return turn
