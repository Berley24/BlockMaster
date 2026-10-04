extends PanelContainer

@onready var rank_label: Label = %RankLabel
@onready var name_label: Label = %NameLabel
@onready var score_label: Label = %ScoreLabel

func setup(entry: Dictionary, rank: int, is_player: bool):
	rank_label.text = "#%d" % rank
	name_label.text = entry.get("name", "Desconhecido")
	score_label.text = "%d" % entry.get("score", 0)
	
	if is_player:
		modulate = Color(0.3, 0.5, 0.8, 0.3)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.4, 0.7, 0.3)
		style.border_color = Color(0.4, 0.7, 1, 1)
		style.border_width = 2
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		add_theme_stylebox_override("panel", style)
		name_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1, 1))
	else:
		modulate = Color(1, 1, 1, 1)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.12, 0.15, 1)
		style.border_color = Color(0.2, 0.2, 0.3, 1)
		style.border_width = 1
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		add_theme_stylebox_override("panel", style)