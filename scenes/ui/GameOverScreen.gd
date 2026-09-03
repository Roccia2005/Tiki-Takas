class_name GameOverScreen
extends Control

## Schermata di sconfitta della run (GDD §3).
##
## Una partita persa chiude la carriera: qui si legge il riepilogo finale di
## [GameManager] e si offre di ricominciare da zero con una nuova rosa.

## Il giocatore chiede di avviare una nuova run.
signal restart_requested

const PANEL := Rect2(500.0, 220.0, 920.0, 640.0)
const TITLE_RECT := Rect2(520.0, 250.0, 880.0, 96.0)
const SUBTITLE_RECT := Rect2(520.0, 348.0, 880.0, 36.0)
const STATS_RECT := Rect2(560.0, 424.0, 800.0, 300.0)
const BUTTON_RECT := Rect2(660.0, 756.0, 600.0, 64.0)
const RULE_Y: float = 402.0

var _subtitle_label: Label = null
var _stats_label: Label = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


## Mostra il bilancio della run appena terminata.
func show_run(run: GameManager) -> void:
	if _stats_label == null:
		_build()
	if run == null:
		_subtitle_label.text = ""
		_stats_label.text = ""
	else:
		_subtitle_label.text = "Eliminato in Ante %d/%d al match %d/%d" % [run.current_cup, GameManager.LAST_CUP, run.current_match_index, GameManager.MATCHES_PER_CUP]
		_stats_label.text = _build_stats(run)
	visible = true
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, UIStyle.DESIGN_SIZE), UIStyle.BACKDROP, true)
	UIStyle.draw_panel(self, PANEL, UIStyle.PANEL_FILL, Color(UIStyle.DANGER.r, UIStyle.DANGER.g, UIStyle.DANGER.b, 0.5), 3.0)
	UIStyle.draw_rule(self, Vector2(PANEL.position.x + 40.0, RULE_Y), Vector2(PANEL.end.x - 40.0, RULE_Y))


## Statistiche complessive della run: match, gol, boss e rosa (GDD §3 e §8).
func _build_stats(run: GameManager) -> String:
	var boss := "nessuno"
	if run.current_boss != null:
		boss = run.current_boss.boss_name
	var roster := 0
	var team_name := "-"
	if run.player_team != null:
		roster = run.player_team.players.size()
		team_name = run.player_team.team_name
	var lines := "RIEPILOGO CARRIERA\n"
	lines += "squadra   %s\n" % team_name
	lines += "match completati   %d su %d\n" % [run.get_matches_completed(), GameManager.TOTAL_MATCHES]
	lines += "match giocati   %d   ·   vinti   %d\n" % [run.matches_played, run.matches_won]
	lines += "gol fatti   %d   ·   gol subiti   %d\n" % [run.total_goals_scored, run.total_goals_conceded]
	lines += "ultimo boss affrontato   %s\n" % boss
	lines += "cartellini in rosa   %d\n" % roster
	lines += "Football Coins residui   %d FC" % run.budget
	return lines


## Costruisce titolo, riepilogo e pulsante di ripartenza.
func _build() -> void:
	add_child(UIStyle.make_label("GAME OVER", TITLE_RECT, 72, UIStyle.DANGER, HORIZONTAL_ALIGNMENT_CENTER))
	_subtitle_label = UIStyle.make_label("", SUBTITLE_RECT, 22, UIStyle.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_subtitle_label)
	_stats_label = UIStyle.make_paragraph("", STATS_RECT, 20, UIStyle.TEXT_MAIN)
	add_child(_stats_label)
	var button := UIStyle.make_button("NUOVA PARTITA", BUTTON_RECT, 26, UIStyle.ACCENT)
	button.pressed.connect(func() -> void: restart_requested.emit())
	add_child(button)
