extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	apply_torque(-transform.basis.x + (transform.basis.z * .25))
