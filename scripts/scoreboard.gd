extends CanvasLayer

@onready var rich_text_label: RichTextLabel = $RichTextLabel

var red_score: int = 0
var blue_score: int = 0

func _ready() -> void:
	var cell = $GridContainer/ColorRect.duplicate()
	$GridContainer.remove_child($GridContainer/ColorRect)

	for i in range(8):
		var cell_clone = cell.duplicate()
		cell_clone.color = Color.RED
		cell_clone.color.a = 0.8
		$GridContainer.add_child(cell_clone)
	for i in range(8):
		var cell_clone = cell.duplicate()
		cell_clone.color = Color.BLUE
		cell_clone.color.a = 0.8
		$GridContainer.add_child(cell_clone)

func set_score(end: int, red: int, blue: int):
	assert(red == 0 || blue == 0)
	var cells = $GridContainer.get_children()
	cells[end - 1].get_child(0).text = str(red)
	cells[end - 1 + 8].get_child(0).text = str(blue)
