extends Node

var currTurn = 0
signal turn_updated(turn, game)
signal new_turn(game, turn)
signal new_game(game)
var games := []
var currGameIndex = 0
var currGame : Game
var currPlayer = 0

func _input(event: InputEvent) -> void:
    if event.is_action_pressed('ui_right'):
        self.next_turn()
    if event.is_action_pressed("ui_left"):
        self.prev_turn()
        
func next_turn():
    if not self.currGame:
        return
    self.currTurn = clamp(self.currTurn+1, 0, currGame.nTurns()-1)
    load_turn(currTurn)       

func prev_turn():
    if not self.currGame:
        return
    self.currTurn = clamp(self.currTurn-1, 0, currGame.nTurns()-1)
    load_turn(currTurn)
    
func load_turn(turn: int, loadGame: int = -1):
    if loadGame < 0:
        loadGame = currGameIndex
    if len(games) < loadGame-1:
        return
    self.currGame = games[loadGame]
    self.currGameIndex = loadGame
    self.currTurn = turn

    var newTurn = currGame.turns[turn]
    self.currPlayer = 1-newTurn.player
    $Board.clear_board()
        
    for pos in newTurn.positions:
        $Board.add_piece("WB".find(pos[0]),"KQBNRP".find(pos[1]),newTurn.positions[pos])
    emit_signal("turn_updated", self.currTurn, self.currGameIndex)

func _on_Board_piece_moved(turn) -> void:
    self.currPlayer = 1 - self.currPlayer
    var branching = currTurn < currGame.nTurns()-1
    if branching:
        var newBranch = branch(currGame, currTurn)
        new_game(newBranch)

    self.currGame.turns.push_back(turn)
    emit_signal("new_turn", self.currGameIndex, turn)
    self.currTurn += 1    
    if branching:
        load_turn(self.currTurn, len(games)-1)
    emit_signal("turn_updated", self.currTurn, self.currGameIndex)

func new_game(game: Game):
    self.games.push_back(game)
    emit_signal("new_game", game)
    load_turn(self.currTurn, len(games)-1)
    
func branch(toCopy: Game = null, turn: int = -1) -> Game:
    if not toCopy:
        toCopy = self.currGame
        if turn < 0:
            turn = self.currTurn

    var copy = Game.new()    
    copy.data = toCopy.data
    copy.turns = toCopy.turns.slice(0, turn)
    var basename = toCopy.path.split(':')[0]
    var num = 0
    for game in self.games:
        var split = game.path.split(':')
        if split[0] == basename and len(split) > 1:
            num = max(num, split[1].to_int())
    
    copy.path = basename + ":" + str(num+1)
    return copy

func _error(title, message):
    get_tree().get_root().get_node("Root").error(title, message) 
