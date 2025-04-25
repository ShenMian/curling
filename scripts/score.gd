extends CanvasLayer

var red_score: int = 0
var blue_score: int = 0

func _ready() -> void:
	update_label()

func set_red_score(score: int) -> void:
	red_score = score
	update_label()

func set_blue_score(score: int) -> void:
	blue_score = score
	update_label()

func update_label() -> void:
	$RichTextLabel.text = "[color=red]Red[/color] : {red}\n[color=blue]Blue[/color]: {blue}".format({"red": red_score, "blue": blue_score})
