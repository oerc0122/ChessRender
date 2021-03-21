extends Resource
class_name Game

var data := {"DisplayName": "New Game"}
var turns := [Turn.new()]

func _to_string() -> String:
    var string = ""
    for elem in data:
        string += '["{elem}" "{data}"]\n'.format({"elem":elem, "data":data[elem]})
    string += "\n"
    var capture: String
    var promote: String
    var currTurn: Turn
    for turn in range(1, len(turns), 2):
        string += "{turn}. ".format({"turn":(turn/2)+1})
        currTurn = turns[turn]
        string += currTurn.to_string()+" "
        if turn+1 < len(turns):
            currTurn = turns[turn+1]
            string += currTurn.to_string()+" "

    string += data.get("Result", "0-0")
    
    return string

func nTurns() -> int:
    return len(self.turns)
