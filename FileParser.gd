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

var rawCommentRE = RegEx.new()
var suggestionRE = RegEx.new()
var nagRE = RegEx.new()
var tagRE = RegEx.new()
var turnRE = RegEx.new()
var finalRE = RegEx.new()
var plyRE = RegEx.new()

func _init():
    rawCommentRE.compile(rawCommentRER)    
    suggestionRE.compile(suggestionRER)
    nagRE.compile(NAGRER)
    tagRE.compile(tagRER)
    turnRE.compile("(?:%s|%s)" % [fullTurnRER, halfTurnRER])
    finalRE.compile(finalRER)
    plyRE.compile(plyRER)

func read(filepath) -> Array:
    self.path = filepath
    var file := File.new()
    var status = file.open(self.path, File.READ)
    
    if status:
        emit_signal("error", "File not found...", "File not found: Cannot open file: "+self.path)
        return []
    var content := file.get_as_text()
    file.close()
    var matches = parse_matches(content)
    for game in matches:
        if not "DisplayName" in game:
            game.data["DisplayName"] = filepath.get_file()
    return matches

func parse_matches(content: String) -> Array:
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
        var loaded = parse_SAN(game)
        games.push_back(loaded)

    emit_signal("read", games)
    return games

func parse_SAN(SAN: String) -> Game:
    var game = Game.new()
    
    for tag in tagRE.search_all(SAN):
        game.data[tag.get_string("key")] = tag.get_string("value")
        SAN = SAN.replace(tag.get_string(), "")

    var turns = turnRE.search_all(SAN)
    var parsed_turns = []
    for turn in range(len(turns)): # Stitch half turns
        var currTurn = turns[turn]
        if not has_turn(currTurn, "Black"):
            pass # Skip: handled by stitch
        elif not has_turn(currTurn, "White"):
            var prevTurn = turns[turn-1]
            var stitch = self.stitch_turns(prevTurn, currTurn)
            parsed_turns.push_back(turnRE.search(stitch)) 
        else:
            parsed_turns.push_back(currTurn)

    if not has_turn(turns[-1], "Black"): # Catch leftover
        parsed_turns.push_back(turns[-1])
    turns.clear() # Clean up

    var currTurn : Turn
    if not "SetUp" in game.data:
        currTurn = Turn.new()
        currTurn.raw = "0. Start game"
    else:
        if not "FEN" in game.data:
            emit_signal("error", "Bad input pgn", "FEN data not found")
        currTurn = parse_FEN(game.data["FEN"])
        currTurn.raw = "0. Start game"
        currTurn.ID = "Start Game"

    game.turns = [currTurn]                   
    
    for turn in parsed_turns:
        currTurn = Turn.new(Turn.COLOUR.WHITE, currTurn.positions, turn, currTurn.promotions)
        game.turns.push_back(currTurn)
        if has_turn(turn, "Black"): # Catch leftover
            currTurn = Turn.new(Turn.COLOUR.BLACK, currTurn.positions, turn, currTurn.promotions)
            game.turns.push_back(currTurn)    
    return game

func has_turn(turn: RegExMatch, colour: String):
    return not (turn.get_string(colour+"Location").empty() and 
                turn.get_string(colour+"Castle").empty())

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
