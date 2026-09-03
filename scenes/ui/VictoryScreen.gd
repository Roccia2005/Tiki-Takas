class_name VictoryScreen
extends Control

## Schermata di trionfo finale: il boss dell'Ante 6 è stato battuto (GDD §3, §8).
##
## Disegna la coppa in primitive vettoriali, riepiloga la carriera e riporta al
## menu iniziale per una nuova run.

## Il giocatore chiede di tornare al menu principale.
signal menu_requested

const PANEL := Rect2(440.0, 130.0, 1040.0, 810.0)
const TROPHY_CENTER := Vector2(960.0, 292.0)
const TITLE_RECT := Rect2(460.0, 400.0, 1000.0, 96.0)
const SUBTITLE_RECT := Rect2(460.0, 498.0, 1000.0, 36.0)
const STATS_RECT := Rect2(520.0, 570.0, 880.0, 260.0)
const BUTTON_RECT := Rect2(700.0, 846.0, 520.0, 64.0)
const RULE_Y: float = 548.0

const BOWL_HALF_WIDTH: float = 62.0
const HANDLE_RADIUS: float = 30.0
const SPARKLE_RADIUS: float = 132.0
const SPARKLES: int = 12

var _subtitle_label: Label = null
var _stats_label: Label = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


## Mostra il riepilogo del mondiale vinto.
func show_run(run: GameManager) -> void:
	if _stats_label == null:
		_build()
	if run == null:
		_subtitle_label.text = ""
		_stats_label.text = ""
	else:
		_subtitle_label.text = "%s ha vinto tutte le %d Ante del mondiale" % [_team_name(run), GameManager.LAST_CUP]
		_stats_label.text = _build_stats(run)
	visible = true
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, UIStyle.DESIGN_SIZE), UIStyle.BACKDROP, true)
	UIStyle.draw_panel(self, PANEL, UIStyle.PANEL_FILL, Color(UIStyle.GOLD.r, UIStyle.GOLD.g, UIStyle.GOLD.b, 0.6), 3.0)
	_draw_sparkles()
	_draw_trophy()
	UIStyle.draw_rule(self, Vector2(PANEL.position.x + 40.0, RULE_Y), Vector2(PANEL.end.x - 40.0, RULE_Y))


## Coppa vettoriale: coppa, manici, fusto e base, nessun asset esterno.
func _draw_trophy() -> void:
	var gold := UIStyle.GOLD
	var bowl := PackedVector2Array([
		TROPHY_CENTER + Vector2(-BOWL_HALF_WIDTH, -70.0),
		TROPHY_CENTER + Vector2(BOWL_HALF_WIDTH, -70.0),
		TROPHY_CENTER + Vector2(46.0, 6.0),
		TROPHY_CENTER + Vector2(16.0, 42.0),
		TROPHY_CENTER + Vector2(-16.0, 42.0),
		TROPHY_CENTER + Vector2(-46.0, 6.0),
	])
	draw_colored_polygon(bowl, Color(gold.r, gold.g, gold.b, 0.35))
	var outline := bowl.duplicate()
	outline.append(bowl[0])
	draw_polyline(outline, gold, 3.0)
	draw_arc(TROPHY_CENTER + Vector2(-BOWL_HALF_WIDTH, -44.0), HANDLE_RADIUS, PI * 0.5, PI * 1.5, 24, gold, 4.0)
	draw_arc(TROPHY_CENTER + Vector2(BOWL_HALF_WIDTH, -44.0), HANDLE_RADIUS, -PI * 0.5, PI * 0.5, 24, gold, 4.0)
	draw_rect(Rect2(TROPHY_CENTER + Vector2(-11.0, 42.0), Vector2(22.0, 40.0)), gold, true)
	draw_rect(Rect2(TROPHY_CENTER + Vector2(-58.0, 82.0), Vector2(116.0, 16.0)), gold, true)
	draw_rect(Rect2(TROPHY_CENTER + Vector2(-74.0, 98.0), Vector2(148.0, 12.0)), Color(gold.r, gold.g, gold.b, 0.6), true)


## Raggi di luce attorno alla coppa.
func _draw_sparkles() -> void:
	var glow := Color(UIStyle.GOLD.r, UIStyle.GOLD.g, UIStyle.GOLD.b, 0.22)
	for index in SPARKLES:
		var angle := TAU * float(index) / float(SPARKLES)
		var direction := Vector2.from_angle(angle)
		draw_line(TROPHY_CENTER + direction * SPARKLE_RADIUS, TROPHY_CENTER + direction * (SPARKLE_RADIUS + 34.0), glow, 3.0)


## Nome della squadra campione.
func _team_name(run: GameManager) -> String:
	if run.player_team == null or run.player_team.team_name.is_empty():
		return "La tua squadra"
	return run.player_team.team_name


## Bilancio del mondiale: match, gol, talismani e budget finale (GDD §3, §10).
func _build_stats(run: GameManager) -> String:
	var lines := "ALBO D'ORO\n"
	lines += "match giocati   %d   ·   vinti   %d\n" % [run.matches_played, run.matches_won]
	lines += "gol fatti   %d   ·   gol subiti   %d\n" % [run.total_goals_scored, run.total_goals_conceded]
	if run.player_team != null:
		lines += "cartellini in rosa   %d   ·   talismani   %d/%d\n" % [run.player_team.players.size(), run.player_team.talismans.size(), TalismanData.MAX_EQUIPPED]
	lines += "Football Coins finali   %d FC" % run.budget
	return lines


## Costruisce titolo, riepilogo e pulsante di ritorno al menu.
func _build() -> void:
	add_child(UIStyle.make_label("CAMPIONI DEL MONDO", TITLE_RECT, 62, UIStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	_subtitle_label = UIStyle.make_label("", SUBTITLE_RECT, 22, UIStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_subtitle_label)
	_stats_label = UIStyle.make_paragraph("", STATS_RECT, 20, UIStyle.TEXT_MAIN)
	add_child(_stats_label)
	var button := UIStyle.make_button("TORNA AL MENU", BUTTON_RECT, 26, UIStyle.GOLD)
	button.pressed.connect(func() -> void: menu_requested.emit())
	add_child(button)
