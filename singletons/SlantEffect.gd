tool
extends RichTextEffect
class_name RichTextPulse

# Syntax: [pulse color=#00FFAA height=0.0 freq=2.0][/pulse]

# Define the tag name.
var bbcode = "stress"

func _process_custom_fx(char_fx):
    char_fx.color.r = 1.0
    char_fx.color.g = 0.2
    char_fx.color.b = 0.1
    return true
