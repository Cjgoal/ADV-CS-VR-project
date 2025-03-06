extends PanelContainer

var time_left = 60  # Countdown time in seconds
var timer = null    # Timer node
var label = null    # Reference to the Label node

enum GameDifficulty {
	GAME_EASY,
	GAME_NORMAL,
	GAME_HARD,
	GAME_MAX
}

func _ready():
	# Get the Label node
	label = %Label  # Make sure your Label node is a direct child of this PanelContainer
	if (GameState.game_difficulty == GameDifficulty.GAME_EASY):
		time_left = 180
	if (GameState.game_difficulty == GameDifficulty.GAME_NORMAL):
		time_left = 120
	if (GameState.game_difficulty == GameDifficulty.GAME_HARD):
		time_left = 60
	if (GameState.game_difficulty == GameDifficulty.GAME_MAX):
		time_left = 40

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
	if %Score:
		%Score.text = "Score: " + str(Globals.Game_Score)



func end_game():
	print("Game Over! Final Score:", Globals.Game_Score)
	GameState.quit_game()

func _on_quit_button_pressed():
	GameState.quit_game()
