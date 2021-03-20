extends Node
class_name FileParser

var path := ""
const COLOURS = ["White", "Black"]
signal read(game)
signal error(title, message) 

const moveRER = ("(?<Piece>[NKQRBP]?)"+
                "(?<Disambiguation>(?:[a-h]|[1-8]|[a-h][1-8])(?=x?[a-h][1-8]))?"+
                "(?<Capture>x)?"+
                "(?<Location>[a-h][1-8])"+
                "(?:=(?<Promotion>[NKQRB]))?"+
                "(?<Check>[+#])?")
const castleRER = "(?<Castle>O-O(?:-O)?)"
var plyRER = "(?:(?:{move})|{castle})".format({"move":moveRER, "castle":castleRER})
const commentRER = "\\{(?<comment>[^}]+)\\}"
const rawCommentRER = ";(?<comment>.*)"
const suggestionRER = "\\((?<comment>[^)]+)\\)"
const NAGRER = "(?<nag>\\$[0-9]+)"
const tagRER = "\\[(?<key>[A-Za-z]+) *\"(?<value>[^\"]*)\"\\]\\s*(?:"+commentRER+")?"
const finalRER = "(?<WhiteWin>(?:0|1/2|1(?!/2)))-(?<BlackWin>(?:0|1/2|1(?!/2)))(?!\\s*\")"

var fullTurnRER = ("(?<turn>[0-9]+)\\.\\s*" +
                    plyRER.replace("?<","?<White")+"\\s+" +
                    plyRER.replace("?<","?<Black")+"?\\s*" +
                    "(?:"+commentRER+")?"
                )
var halfTurnRER = ("(?<turn>[0-9]+)\\.{3}\\s*" +
                    plyRER.replace("?<","?<Black")+"\\s*" +
                    "(?:"+commentRER+")?"
                    )


func read(filepath) -> Array:
    self.path = filepath
    var file := File.new()
    var status = file.open(self.path, File.READ)
    
    if status:
        emit_signal("error", "File not found...", "File not found: Cannot open file: "+self.path)
        return []
    var content := file.get_as_text()
    file.close()

    var rawCommentRE = RegEx.new()
    rawCommentRE.compile(rawCommentRER)    
    var suggestionRE = RegEx.new()
    suggestionRE.compile(suggestionRER)
    var nagRE = RegEx.new()
    nagRE.compile(NAGRER)
    var tagRE = RegEx.new()
    tagRE.compile(tagRER)
    var turnRE = RegEx.new()

                     
    turnRE.compile("(?:%s|%s)" % [fullTurnRER, halfTurnRER])
    var finalRE = RegEx.new()
    finalRE.compile(finalRER)

    content = rawCommentRE.sub(content, "{$comment}", true).replace("\n", " ").strip_escapes()
#    content = suggestionRE.sub(content, "", true) # For now ignore suggestions, later may want to branch
    content = nagRE.sub(content, "", true) # Remove NAGing
    var prevInd = 0
    var matches = []

    for game in finalRE.search_all(content):
        var ind = game.get_end()
        matches.push_back(content.substr(prevInd, ind-prevInd))
        prevInd = ind

    var games = []
    for game in matches:
        game = handle_branches(game)
        var loaded = Game.new()
        loaded.path = filepath.get_file()
        for tag in tagRE.search_all(game):
            loaded.data[tag.get_string("key")] = tag.get_string("value")
            game = game.replace(tag.get_string(), "")

        var turns = turnRE.search_all(game)
        var parsed_turns = []
        for turn in range(len(turns)): # Stitch half turns
            var currTurn = turns[turn]
            if currTurn.get_string("BlackLocation").empty() and currTurn.get_string("BlackCastle").empty():
                pass # Skip: handled by stitch
            elif currTurn.get_string("WhiteLocation").empty() and currTurn.get_string("WhiteCastle").empty():
                var prevTurn = turns[turn-1]
                var stitch = self.stitch_turns(prevTurn, currTurn)
                parsed_turns.push_back(turnRE.search(stitch)) 
            else:
                parsed_turns.push_back(currTurn)
        turns.clear() # Clean up

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
        
        for turn in parsed_turns:
            currTurn = Turn.new(Turn.COLOUR.WHITE, currTurn.positions, turn, currTurn.promotions)
            loaded.turns.push_back(currTurn)
            currTurn = Turn.new(Turn.COLOUR.BLACK, currTurn.positions, turn, currTurn.promotions)
            loaded.turns.push_back(currTurn)
        games.push_back(loaded)
        
    emit_signal("read", games)
    return games

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

func stitch_turns(prevTurn: RegExMatch, currTurn: RegExMatch) -> String:
    var plyRE = RegEx.new()
    plyRE.compile(plyRER)
    if prevTurn.get_string("turn") != currTurn.get_string("turn"):
        null.get_node("Crash")
        
    var whitePly = plyRE.search(prevTurn.strings[0])
    var blackPly = plyRE.search(currTurn.strings[0])
    
    var stitch = "{turn}.{whitePly} {blackPly} ".format({"turn": currTurn.get_string("turn"),
                                                         "whitePly": whitePly.strings[0],
                                                         "blackPly": blackPly.strings[0]})
    stitch += " {"+prevTurn.get_string("comment") + ";" + currTurn.get_string("comment") + "}"
    return stitch

func handle_branches(content: String) -> String:
    while content.find("(") > 0:
        var init = content.find("(")
        var count = 1
        var curr = init+1
        while count > 0:
            match content[curr]:
                "(":
                    count += 1
                ")":
                    count -= 1
            curr += 1
        content = content.substr(0, init) + content.substr(curr)
    return content
