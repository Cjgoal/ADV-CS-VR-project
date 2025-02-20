@tool
class_name PersistentPocket
extends XRToolsSnapZone


## Persistent Pocket Node
##
## The [PersistentPocket] type holds persistent items managed by the
## persistence system. The [PersistentPocket] type extends from
## [XRToolsSnapZone] to allow [PersistentItem] objects to be snapped or
## removed by the player.


## Enumeration to control pocket behavior when the parent item is held
enum HeldBehavior {
	IGNORE,		## Ignore picked_up/dropped changes
	ENABLE,		## Enable when picked up
	DISABLE		## Disable when picked up
}


# Group for world-data properties
@export_group("World Data")

## This property specifies the unique ID of this pocket
@export var pocket_id : String

# Group for options
@export_group("Options")

## Pocket behavior when held
@export var held_behavior := HeldBehavior.ENABLE : set = _set_held_behavior


# Parent pickable body
var _parent_body : XRToolsPickable

var total_value: float = 0

var value_label: Label3D

# Add support for is_xr_class
func is_xr_class(p_name : String) -> bool:
	return p_name == "PersistentPocket" or super(p_name)


# Called when the node enters the scene tree for the first time.
func _ready():
	super()

	# Skip initialization if in editor
	if Engine.is_editor_hint():
		return
		
	
	# Create a 3D label to display the value
	value_label = Label3D.new()
	value_label.text = "Total: 0"
	value_label.position = Vector3(0, 0.5, 0)  # Adjust position above the box
	value_label.font_size = 32
	add_child(value_label)

	# Search for an ancestor XRToolsPickable
	_parent_body = XRTools.find_xr_ancestor(self, "*", "XRToolsPickable")
	if _parent_body:
		_parent_body.picked_up.connect(_on_picked_up)
		_parent_body.dropped.connect(_on_dropped)

	# Update the held behavior
	_update_held_behavior()
	
	_attach_value_display_to_hand()


# Get configuration warnings
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Verify pocket ID is set
	if not pocket_id:
		warnings.append("Pocket ID not zet")

	# Verify pocket is in persistent group
	if not is_in_group("persistent"):
		warnings.append("Pocket not in 'persistent' group")

	# Return warnings
	return warnings


# Handle notifications
func _notification(what : int) -> void:
	# Ignore notifications on freeing objects
	if is_queued_for_deletion():
		return

	match what:
		Persistent.NOTIFICATION_LOAD_STATE:
			_load_state()

		Persistent.NOTIFICATION_SAVE_STATE:
			_save_state()

		Persistent.NOTIFICATION_DESTROY:
			_destroy()


# This method loads the pocket state from [PersistentWorld]. If the
# [PersistentWorld] indicates this pocket holds an item then the item is
# created and picked up by the pocket.
func _load_state() -> void:
	# Queue populating the pocket as new nodes cannot be created inside a
	# notification handler.
	_populate_pocket.call_deferred()


# This method saves the state of the pocket to [PersistentWorld].
func _save_state() -> void:
	# Handle pocket not holding on to PersistentItem
	if not picked_up_object is PersistentItem:
		# Save that the pocket is empty
		PersistentWorld.instance.clear_value(pocket_id)
		return

	# Get the item_id of the PersistentItem in the pocket
	var item_id : String = picked_up_object.item_id

	# Save that the pocket holds the item
	PersistentWorld.instance.set_value(pocket_id, item_id)


# This method destroys the pocket and any item inside it.
func _destroy() -> void:
	# Propagate destruction for anything we hold
	if is_instance_valid(picked_up_object):
		print(self, " propagating destroy to ", picked_up_object.name)
		picked_up_object.propagate_notification(Persistent.NOTIFICATION_DESTROY)
		picked_up_object.queue_free()


# Populate the contents of a pocket
func _populate_pocket() -> void:
	# Get the ID of the item in the pocket
	var item_id = PersistentWorld.instance.get_value(pocket_id)
	if not item_id is String:
		return

	# Construct the item for the pocket
	var zone = PersistentZone.find_instance(self)
	var item := zone.create_item_instance(item_id)
	if not item:
		return

	# Put the item in the pocket
	item.global_transform = global_transform
	
	# random value for pickup if it doesnt have one
	if not item.has_method("get_value"):
		item.set_meta("value", randf_range(20,100))
	
	pick_up_object.call_deferred(item)


# Called when the parent pickable body is picked up
func _on_picked_up(_pickable) -> void:
	_update_held_behavior()

	# Update and show the total value when an item is collected
	if picked_up_object and picked_up_object.has_meta("value"):
		var item_value = picked_up_object.get_meta("value")
		total_value += item_value
		_update_value_display()
		
func _update_value_display():
	if not value_label:
		return

	# Set the new text
	value_label.text = "Total: %d" % total_value
	
	# Find the player's hand (adjust path if necessary)
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Try to find the right hand controller
	var right_hand = player.find_child("RightHand", true, false)  # Adjust if needed
	
	if right_hand:
		# Move the label to be above the right hand
		value_label.global_transform.origin = right_hand.global_transform.origin + Vector3(0, 0.2, 0)

func _attach_value_display_to_hand():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var right_hand = player.find_child("RightHand", true, false)
	if right_hand:
		# Reparent the label to the right hand
		right_hand.add_child(value_label)
		value_label.position = Vector3(0, 0.2, 0)  # Slightly above the hand


# Called when the parent pickable body is dropped
func _on_dropped(_pickable) -> void:
	_update_held_behavior()
	
		# Update and subtract the total value when an item is removed
	if picked_up_object and picked_up_object.has_meta("value"):
		var item_value = picked_up_object.get_meta("value")
		total_value -= item_value
		_update_value_display()

# Called when the held_behavior property has been modified
func _set_held_behavior(p_held_behavior : HeldBehavior) -> void:
	held_behavior = p_held_behavior
	if is_inside_tree() and _parent_body:
		_update_held_behavior()


# Update the pocket enable
func _update_held_behavior() -> void:
	# Skip if no valid parent body
	if not is_instance_valid(_parent_body):
		return

	# Test if the parent pickable is held
	var is_held := _parent_body.is_picked_up()

	# Update the enabled state based on whether the parent body is held and
	# the desired behavior
	match held_behavior:
		HeldBehavior.ENABLE:
			enabled = is_held

		HeldBehavior.DISABLE:
			enabled = not is_held
