extends Area2D

export (bool) var active = true
var dragging := false
var mouse_in := false
var stored_pos: Vector2
onready var parent = get_parent()

const COL_ACTIVE = 1 << 20

signal drag
signal stopdrag
signal deselect
signal select(parent)

func _ready():
    add_to_group("draggable")
    if active:
        activate()
    else:
        deactivate()

func _undrag():
    dragging = false
    set_process_unhandled_input(false)
    
func _drag():
    dragging = true
    set_process_unhandled_input(true)

func _input(event):
    if mouse_in:
        if event is InputEventMouseButton:
            if event.button_index == BUTTON_LEFT and event.pressed:
                stored_pos = parent.position
                emit_signal("drag")
                emit_signal("select", parent)
                get_tree().set_input_as_handled()

func _unhandled_input(event):
    if event is InputEventMouseButton:
        if not event.pressed and dragging:
            emit_signal("stopdrag")

func set_shape(shape: Shape2D):
    $Area.set_shape(shape)

func activate():
    active = true
    collision_layer = COL_ACTIVE

func deactivate():
    _undrag()
    active = false
    collision_layer = 0

func _mouse_enter():
    mouse_in = true
    
func _mouse_exit():
    mouse_in = false

