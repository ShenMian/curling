extends CanvasLayer

@onready var rich_text_label: RichTextLabel = $RichTextLabel

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
	rich_text_label.text = "[color=red]{RED_TEAM}[/color]: {red}\n[color=blue]{BLUE_TEAM}[/color]: {blue}".format({
		"RED_TEAM": tr("RED_TEAM"),
		"BLUE_TEAM": tr("BLUE_TEAM"),
		"red": red_score,
		"blue": blue_score})
