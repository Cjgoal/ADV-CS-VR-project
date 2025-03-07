extends StaticBody3D

# List of objects and their values
var object_values = {
	"Wine": 50,
	"pool_table": 100,
	"RubixCube": 75,
	"guitar": 150
}

# Set to track detected objects (to avoid detecting each item more than once)
var detected_items = {}

func _ready():
	# Connect the area detection signals
	$DropZone.body_entered.connect(_on_item_entered)

func _on_item_entered(body):
		if body.name not in detected_items:
			detected_items[body.name] = true  # Mark this object as detected

			# Determine the object's value based on its name
			var object_value = object_values.get(body.name, 0)  # Default value 0 if not in list

			# Update the score
			Globals.Score += object_value
			print("Detected:", body.name, "Value:", object_value)
		else:
			print("Item already detected:", body.name)
