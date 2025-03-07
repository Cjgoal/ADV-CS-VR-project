extends StaticBody3D

# List of objects and their values
var object_values = {
	"Wine": 50,
	"Pool Table": 100,
	"Rubix Cube": 75,
	"Rubix Cube2": 50,
	"Guitair": 150,
	"Coffee maker":75
	
}

# Set to track detected objects (to avoid detecting each item more than once)
var detected_items = {}

func _ready():
	# Connect the area detection signals
	$DropZone.body_entered.connect(_on_item_entered)

func _on_item_entered(body):
	print(body.name)
	var object_value = object_values.get(body.name, 0)  # Default value 0 if not in list
	print(object_value)
	Globals.Game_Score += object_value
