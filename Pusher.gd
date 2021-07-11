extends RigidBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    #custom_integrator = true
    gravity_scale = 0
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func _integrate_forces(state):
    state.angular_velocity = 0
    #if contacts_reported == 0:
    state.linear_velocity = get_parent().velocity*0.15
    #print(get_parent().velocity*0.3)
    #print(state.linear_velocity.length_squared())
    #else:
        #state.linear_velocity = lerp(state.linear_velocity, get_parent().velocity*0.3, state.step)
    state.transform.x = Vector2(1, 0)
    state.transform.y = Vector2(0, 1)
    state.transform.origin = get_parent().global_position# - state.linear_velocity*state.step
    
