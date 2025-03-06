extends PanelContainer

var time_left = 60  # Countdown time in seconds
var score = 0       # Score counter
var timer = null    # Timer node
var label = null    # Reference to the Label node

func _ready():
	# Get the Label node
	label = %Label  # Make sure your Label node is a direct child of this PanelContainer
	score = %score

	# Create and start the countdown timer
	timer = Timer.new()
	timer.wait_time = 1  # 1 second interval
	timer.autostart = true
	timer.one_shot = false
	add_child(timer)
	timer.connect("timeout", self._on_timer_timeout)

	# Update label initially
	update_timer_label()

func _on_timer_timeout():
	time_left -= 1
	update_timer_label()
	if time_left <= 0:
		end_game()

func update_timer_label():
	if label:
		label.text = "Time Left: " + str(time_left)
	if score:
		score.text = "Score:" + score


func increase_score(points):
	score += points

func end_game():
	print("Game Over! Final Score:", score)
	GameState.quit_game()

func _on_quit_button_pressed():
	GameState.quit_game()
