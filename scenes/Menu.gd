extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

signal done

var waiting = false

# Called when the node enters the scene tree for the first time.
func _ready():
    if Manager.bypass_loading:
        $Buttons.hide()
        return
    
    if Manager.load_exists():
        Manager.load_game()
        Manager.bypass_loading = true
        $"Buttons/Continue".grab_focus()
        waiting = true
    else:
        Manager.bypass_loading = true
        $"Buttons/Continue".disabled = true
        $"Buttons/New Game".grab_focus()
        waiting = true
    $Buttons/Continue.connect("pressed", self, "load_game")
    $"Buttons/New Game".connect("pressed", self, "new_game")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass

func load_game():
    get_parent().startmode = "load"
    emit_signal("done")
    waiting = false
    $Buttons.hide()

func new_game():
    get_parent().startmode = "new"
    emit_signal("done")
    get_tree().reload_current_scene()
    waiting = false
    $Buttons.hide()

