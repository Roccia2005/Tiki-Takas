class_name MatchResultModal
extends Control

## Riquadro di fine partita (GDD §3 e §7).
##
## Mostra l'esito del match appena chiuso, i gol, le risorse rimaste e i
## Football Coins guadagnati secondo il resoconto di
## [method GameManager.record_match_result]. Il pulsante prosegue verso il
## Calcio Mercato, il match successivo o le schermate finali: la decisione
## spetta a [Main], qui si emette solo [signal continue_requested].

## Il giocatore chiede di proseguire la run.
signal continue_requested

const PANEL := Rect2(420.0, 180.0, 1080.0, 720.0)
const TITLE_RECT := Rect2(440.0, 214.0, 1040.0, 90.0)
const SUBTITLE_RECT := Rect2(440.0, 306.0, 1040.0, 34.0)
const SCORE_RECT := Rect2(440.0, 352.0, 1040.0, 84.0)
const STATS_RECT := Rect2(470.0, 476.0, 500.0, 250.0)
const REWARD_RECT := Rect2(990.0, 476.0, 490.0, 250.0)
const BUTTON_RECT := Rect2(730.0, 796.0, 460.0, 64.0)
const RULE_Y: float = 458.0

## Etichette dei pulsanti in base a come continua la run (GDD §3).
const NEXT_SHOP := "VAI AL CALCIO MERCATO"
const NEXT_MATCH := "PROSSIMO MATCH"
const NEXT_OVER := "RIEPILOGO DELLA RUN"
const NEXT_VICTORY := "ALZA LA COPPA"

var _title_label: Label = null
var _subtitle_label: Label = null
var _score_label: Label = null
var _stats_label: Label = null
var _reward_label: Label = null
var _button: Button = null
var _won: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


## Riempie il riquadro con l'esito del match e adatta il pulsante alla fase in
## cui la run è entrata dopo [method GameManager.record_match_result].
func show_result(run: GameManager, report: Dictionary, controller: MatchController) -> void:
	if _title_label == null:
		_build()
	_won = bool(report.get("won", false))
	_title_label.text = "VITTORIA" if _won else "SCONFITTA"
	_title_label.add_theme_color_override("font_color", UIStyle.GOLD if _won else UIStyle.DANGER)
	_subtitle_label.text = _build_subtitle(run)
	_score_label.text = _build_score(controller)
	_stats_label.text = _build_stats(controller)
	_reward_label.text = _build_reward(run, report)
	_button.text = _next_label(run)
	visible = true
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, UIStyle.DESIGN_SIZE), UIStyle.MODAL_SHADE, true)
	var edge := UIStyle.GOLD if _won else UIStyle.DANGER
	UIStyle.draw_panel(self, PANEL, UIStyle.PANEL_FILL, Color(edge.r, edge.g, edge.b, 0.55), 3.0)
	UIStyle.draw_rule(self, Vector2(PANEL.position.x + 40.0, RULE_Y), Vector2(PANEL.end.x - 40.0, RULE_Y))


## Ante, match e boss della partita appena giocata (GDD §3 e §8).
func _build_subtitle(run: GameManager) -> String:
	if run == null:
		return ""
	var boss := "nessuno"
	if run.current_boss != null:
		boss = run.current_boss.boss_name
	var kind := "Boss Match" if run.current_match_index == GameManager.BOSS_MATCH_INDEX else "Match di campionato"
	return "Ante %d/%d   ·   %s %d/%d   ·   Boss: %s" % [run.current_cup, GameManager.LAST_CUP, kind, run.current_match_index, GameManager.MATCHES_PER_CUP, boss]


## Punteggio del match, con i gol segnati e subiti.
func _build_score(controller: MatchController) -> String:
	if controller == null:
		return "-  :  -"
	return "%d  :  %d" % [controller.score_player, controller.score_ai]


## Risorse spese e punti parata residui del portiere avversario (GDD §7).
func _build_stats(controller: MatchController) -> String:
	if controller == null:
		return ""
	var lines := "TABELLINO\n"
	lines += "azioni giocate   %d\n" % controller.action_index
	lines += "passaggi   %d usati   %d rimasti\n" % [controller.passes_used, controller.passes_left]
	lines += "tiri   %d usati   %d rimasti\n" % [controller.shots_used, controller.shots_left]
	lines += "punti parata   %s / %s\n" % [UIStyle.format_points(controller.save_points), UIStyle.format_points(controller.save_points_max)]
	lines += "sagome in campo   %d" % controller.obstacles.size()
	return lines


## Football Coins guadagnati: premio base, bonus boss e residui (GDD §3).
func _build_reward(run: GameManager, report: Dictionary) -> String:
	var lines := "FOOTBALL COINS\n"
	if not _won:
		lines += "nessun premio: la run si chiude qui\n"
	else:
		lines += "premio match   +%d FC\n" % int(report.get("base_reward", 0))
		lines += "risorse non spese   +%d FC\n" % int(report.get("residual_reward", 0))
		lines += "totale incassato   +%d FC\n" % int(report.get("reward", 0))
	var budget := int(report.get("budget", 0))
	if run != null:
		budget = run.budget
	lines += "budget attuale   %d FC" % budget
	return lines


## Etichetta del pulsante in base allo stato in cui si trova la run (GDD §3).
func _next_label(run: GameManager) -> String:
	if run == null:
		return NEXT_MATCH
	match run.run_state:
		GameManager.RunState.SHOP_PHASE:
			return NEXT_SHOP
		GameManager.RunState.GAME_OVER:
			return NEXT_OVER
		GameManager.RunState.CUP_VICTORY:
			return NEXT_VICTORY
		_:
			return NEXT_MATCH


## Costruisce le etichette del riquadro, tutte in coordinate di design.
func _build() -> void:
	_title_label = UIStyle.make_label("", TITLE_RECT, 68, UIStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_title_label)
	_subtitle_label = UIStyle.make_label("", SUBTITLE_RECT, 20, UIStyle.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_subtitle_label)
	_score_label = UIStyle.make_label("", SCORE_RECT, 58, UIStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_score_label)
	_stats_label = UIStyle.make_paragraph("", STATS_RECT, 19, UIStyle.TEXT_MAIN)
	add_child(_stats_label)
	_reward_label = UIStyle.make_paragraph("", REWARD_RECT, 19, UIStyle.ACCENT)
	add_child(_reward_label)
	_button = UIStyle.make_button(NEXT_MATCH, BUTTON_RECT, 24, UIStyle.ACCENT)
	_button.pressed.connect(func() -> void: continue_requested.emit())
	add_child(_button)
