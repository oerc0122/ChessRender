extends Node
class_name FileParser

var path := ""
const COLOURS = ["White", "Black"]
signal read(game)
signal error(title, message) 

func read(filepath) -> Game:
    self.path = filepath
    var file := File.new()
    var status = file.open(self.path, File.READ)
    
    if status:
        push_error("File not found: Cannot open file: "+self.path)
        null.get_node("crash")
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

    var loaded = Game.new()
    loaded.path = filepath.get_file()
    for tag in tagRE.search_all(content):
        loaded.data[tag.get_string("key")] = tag.get_string("value")
        content = content.replace(tag.get_string(), "")

    var currTurn : Turn
    if not "SetUp" in loaded.data:
        currTurn = Turn.new()
        currTurn.raw = "0. Start game"
    else:
        if not "FEN" in loaded.data:
            emit_signal("error", "Bad input pgn", "FEN data not found")
        currTurn = parse_FEN(loaded.data["FEN"])
        currTurn.raw = "0. Start game"
        currTurn.ID = "Start Game"

    loaded.turns = [currTurn]
        
        
    for turn in turnRE.search_all(content):
        currTurn = Turn.new(Turn.COLOUR.WHITE, currTurn.positions, turn, currTurn.promotions)
        loaded.turns.push_back(currTurn)
        currTurn = Turn.new(Turn.COLOUR.BLACK, currTurn.positions, turn, currTurn.promotions)
        loaded.turns.push_back(currTurn)
        
    emit_signal("read", loaded)
    return loaded

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
