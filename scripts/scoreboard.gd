extends CanvasLayer

# Transparency value for cell backgrounds.
@export_range(0.0, 1.0) var transparent: float = 0.8

var red_score: int = 0
var blue_score: int = 0

func _ready() -> void:
	var cell := $GridContainer/Cell.duplicate()
	$GridContainer.remove_child($GridContainer/Cell)

	for color in [Color.RED, Color.BLUE]:
		for i in range(8):
			var cell_clone = cell.duplicate()
			cell_clone.color = color
			cell_clone.color.a = transparent
			$GridContainer.add_child(cell_clone)


# Sets the score for a specific end for both red and blue teams.
func set_score(end: int, red: int, blue: int):
	assert(0 <= end && end <= 8)
	assert(red == 0 || blue == 0)
	var cells := $GridContainer.get_children()
	var red_label: Label = cells[end - 1].get_child(0)
	var blue_label: Label = cells[end - 1 + 8].get_child(0)
	red_label.text = str(red)
	blue_label.text = str(blue)


# Calculates the total score for the red team.
func red_total_score() -> int:
	var cells := $GridContainer.get_children()
	var score: int = 0
	for i in range(8):
		var label: Label = cells[i].get_child(0)
		score += int(label.text)
	return score


# Calculates the total score for the blue team.
func blue_total_score() -> int:
	var cells := $GridContainer.get_children()
	var score: int = 0
	for i in range(8):
		var label: Label = cells[8 + i].get_child(0)
		score += int(label.text)
	return score
