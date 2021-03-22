extends Node

enum FILE_MENU {NEW, LOAD, SAVE, QUIT} 
enum GAME_MENU {PREV, NEXT, EDIT, CLOSE}
enum NETWORK {HOST, CONNECT, DISCONNECT}
enum HELP_MENU {HELP, ABOUT} 

const TAGS = ["Event", "Site", "Date", "Round", "White", "Black",
              "Result", "Annotator", "PlyCount", "TimeControl", 
              "Time", "Termination", "Mode", "FEN"]

onready var Root = get_tree().get_root().get_node("Root")
onready var grid = $GameDetailPopup/VBoxContainer/GridContainer

signal new_game
signal load_game(file)
signal save_game(file)

signal prev_turn
signal next_turn
signal update_headers
signal close_game

signal host(port, pw)
signal connect(ip, port, pw)
signal disconnect()

var file_loc: String

var IP : String
var port : String
var pw : String

func _ready() -> void:
    $MenuBar/HBoxContainer/MenuButton.get_popup().connect("id_pressed", self, "_on_FileMenu_id_pressed")
    $MenuBar/HBoxContainer/GameButton.get_popup().connect("id_pressed", self, "_on_GameMenu_id_pressed")
    $MenuBar/HBoxContainer/NetworkButton.get_popup().connect("id_pressed", self, "_on_NetworkMenu_id_pressed")
    $MenuBar/HBoxContainer/HelpButton.get_popup().connect("id_pressed", self, "_on_HelpMenu_id_pressed")

func _on_FileMenu_id_pressed(id: int) -> void:
    match id:
        FILE_MENU.NEW:
            emit_signal("new_game")
        FILE_MENU.LOAD:
            $FileDialog.mode = FileDialog.MODE_OPEN_FILE
            $FileDialog.window_title = "Load game"
            $FileDialog.popup_centered()
            yield($FileDialog, "popup_hide")
            if self.file_loc:
                emit_signal("load_game", self.file_loc)
            self.file_loc = ""
        FILE_MENU.SAVE:
            $FileDialog.mode = FileDialog.MODE_SAVE_FILE
            $FileDialog.window_title = "Save game"
            $FileDialog.popup_centered()
            yield($FileDialog, "popup_hide")
            if self.file_loc:
                emit_signal("save_game", self.file_loc)
            self.file_loc = ""
        FILE_MENU.QUIT:
            get_tree().quit()

func _on_HelpMenu_id_pressed(id: int) -> void:
    match id:
        HELP_MENU.HELP:
            $HelpDialog.popup_centered()
        HELP_MENU.ABOUT:
            $CreditsDialog.popup_centered()
        
func _on_GameMenu_id_pressed(id: int) -> void:
    match id:
        GAME_MENU.PREV:
            emit_signal("prev_turn")
        GAME_MENU.NEXT:
            emit_signal("next_turn")
        GAME_MENU.EDIT:
            var gameDetails = Root.MainGame.currGame.data
            var cont = $GameDetailPopup/GridContainer
            for tag in TAGS:
                cont.get_node(tag + "Edit").text = gameDetails.get(tag, "")
            $GameDetailPopup.popup_centered()
            yield($GameDetailPopup, "popup_hide")
            for tag in TAGS:
                if cont.get_node(tag + "Edit").text:
                    gameDetails[tag] = cont.get_node(tag + "Edit").text
            emit_signal("update_headers")
        GAME_MENU.CLOSE:
            emit_signal("close_game")

func _on_NetworkMenu_id_pressed(id: int) -> void:
    match id:
        NETWORK.HOST:
            $Network.window_title = "Host game..."
            $Network/CenterContainer/VBoxContainer/IPBlock.hide()
            $Network.popup_centered()
            yield($Network, "popup_hide")
            yield(get_tree().create_timer(0.1), "timeout")  
            if self.port:
                emit_signal("host", int(self.port), self.pw)
            self.IP = ""
            self.port = ""
            self.pw = ""
        NETWORK.CONNECT:
            $Network.window_title = "Connect to..."
            $Network/CenterContainer/VBoxContainer/IPBlock.show()
            $Network.popup_centered()
            yield($Network, "popup_hide")
            yield(get_tree().create_timer(0.1), "timeout")
            if self.IP:
                emit_signal("connect", self.IP, int(self.port), self.pw)
            self.IP = ""
            self.port = ""
            self.pw = ""
        NETWORK.DISCONNECT:
            emit_signal("disconnect")

func _on_FileDialog_file_selected(path: String) -> void:
    self.file_loc = path

func _on_Network_confirmed() -> void:
    self.IP = $Network/CenterContainer/VBoxContainer/IPBlock/IP.text
    self.port = $Network/CenterContainer/VBoxContainer/PortBlock/Port.text
    self.pw = $Network/CenterContainer/VBoxContainer/PasswordBlock/Password.text
