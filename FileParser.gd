extends Node

var data := {}
var turns := []
const COLOURS = ["White", "Black"]

func _ready():
    self.read('test.pgn')

func read(path):
    var file := File.new()
    var status = file.open(path, File.READ)
    
    if status:
        printerr("Cannot open file: ", path)
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
                  "(?<Promotion>=[NKQRB])?"+
                  "(?<Check>[+#])?")
    var castleRE = "O-O(-O)?"
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

    var currTurn
    if not "setup" in data:
        currTurn = Turn.new().standard_start()
        turns.push_back(currTurn)
        
    for turn in turnRE.search_all(content):
        currTurn = calc_turn(Turn.COLOUR.WHITE, currTurn.positions, turn)
        turns.push_back(currTurn)
        currTurn = calc_turn(Turn.COLOUR.BLACK, currTurn.positions, turn)
        turns.push_back(currTurn)
        if currTurn.turnNo > 2:
            break
    
    print(turns)

