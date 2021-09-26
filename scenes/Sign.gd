extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

export(String, MULTILINE) var message : String = "i am a sign"

func usable():
    return true

func cutscene():
    Manager.textbox_show()
    Manager.textbox_set_tag("")
    #Manager.set_bg(preload("res://art/adv/bg/test bg.png"))
    
    Manager.textbox_set_typin(true)
    #Manager.textbox_set_continue_icon("next")
    Manager.textbox_set_bbcode(message)
    yield(Manager, "cutscene_continue")
    
    player.velocity = Vector2(0, 0)
    #yield(Manager.follow_path(player, player.speed, $Path2D), "completed")
    #player.animate_by_motion(Vector2(-1, 0))
    
    #Manager.textbox_set_bbcode("A small pond!")
    #yield(Manager, "cutscene_continue")
    
    #Manager.textbox_set_typin(true)
    #Manager.textbox_set_continue_icon("done")
    #Manager.textbox_set_bbcode("Behold the waters!")
    #yield(Manager, "cutscene_continue")

var player : Node

func interact(other):
    player = other
    Manager.start_cutscene(self, "cutscene")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    $InteractIcon.hide()
    if true:#Manager.input_mode != "cutscene":
        for _node in get_tree().get_nodes_in_group("Player"):
            var player : Node = _node
            if overlaps_body(player):
                $InteractIcon.show()
