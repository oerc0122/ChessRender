extends Resource
class_name Game

var data := {}
var turns := [Turn.new()]
var path := ""

func nTurns() -> int:
    return len(self.turns)
