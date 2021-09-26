extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    for _box in get_tree().get_nodes_in_group("Pushbox"):
        var box : Node2D = _box
        if overlaps_body(box):
            if sign(box.global_position.x - global_position.x) == sign(get_parent().velocity.x):
                box.velocity.x = min(30, abs(get_parent().velocity.x))*sign(get_parent().velocity.x)
                box.tweaked = true
    pass
