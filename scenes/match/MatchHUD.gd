class_name MatchHUD
extends Control

## HUD compatto della partita, costruito interamente da codice (GDD §12).
##
## Legge lo stato di [MatchController] (e, se disponibile, di [GameManager]) e
## lo scrive a schermo: punteggio, passaggi e tiri residui, Potenza Azione
## accumulata e punti parata rimasti al portiere avversario (GDD §4 e §7).
## I messaggi rapidi tipo "GOL" o "INTERCETTATO" compaiono al centro in corpo
## contenuto e sfumano da soli. Nessun asset esterno e nessuna logica di gioco:
## sola lettura.

## Risoluzione di riferimento del layout (GDD §12).
const DESIGN_SIZE := Vector2(1920.0, 1080.0)

## Riquadri dell'HUD, negli angoli per lasciare libero il campo (GDD §12).
const SCORE_PANEL := Rect2(56.0, 24.0, 660.0, 96.0)
const SAVE_PANEL := Rect2(1204.0, 24.0, 660.0, 96.0)
const RESOURCE_PANEL := Rect2(56.0, 960.0, 660.0, 96.0)
const POWER_PANEL := Rect2(1204.0, 960.0, 660.0, 96.0)
const HINT_RECT := Rect2(740.0, 992.0, 440.0, 40.0)
const FLASH_RECT := Rect2(660.0, 468.0, 600.0, 84.0)

## Barra dei punti parata dentro SAVE_PANEL.
const SAVE_BAR := Rect2(1224.0, 92.0, 620.0, 12.0)

## Durata in secondi di un messaggio rapido e della sua dissolvenza.
const FLASH_DURATION: float = 1.4
const FLASH_FADE: float = 0.5

## Corpo del messaggio rapido: contenuto, per non coprire il campo (GDD §12).
const FLASH_FONT_SIZE: int = 44

const PANEL_FILL := Color(0.03, 0.09, 0.08, 0.78)
const PANEL_EDGE := Color(0.27, 0.94, 0.75, 0.35)
const TEXT_MAIN := Color(0.94, 0.98, 0.96)
const TEXT_DIM := Color(0.62, 0.75, 0.71)
const ACCENT := Color("46f0c0")
const WARN := Color("ffb703")
const DANGER := Color("ff5f6d")
const SAVE_BAR_BACK := Color(0.09, 0.14, 0.13, 0.9)

## Colori dei messaggi rapidi per tipo di evento (GDD §4).
const FLASH_GOAL := Color("ffd166")
const FLASH_SAVE := Color("8ecae6")
const FLASH_BAD := Color("ff5f6d")

## Partita osservata dall'HUD.
var controller: MatchController = null

## Run in corso, opzionale: aggiunge Ante, boss e Football Coins (GDD §3 e §8).
var run: GameManager = null

var _score_label: Label = null
var _context_label: Label = null
var _save_label: Label = null
var _save_caption: Label = null
var _resource_label: Label = null
var _resource_caption: Label = null
var _power_label: Label = null
var _phase_label: Label = null
var _hint_label: Label = null
var _flash_label: Label = null
var _flash_time_left: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_labels()
	set_process(true)
	refresh()


func _process(delta: float) -> void:
	if _flash_time_left <= 0.0:
		return
	_flash_time_left = maxf(0.0, _flash_time_left - delta)
	var alpha := 1.0
	if _flash_time_left < FLASH_FADE:
		alpha = _flash_time_left / FLASH_FADE
	_flash_label.modulate = Color(1.0, 1.0, 1.0, alpha)
	if _flash_time_left <= 0.0:
		_flash_label.text = ""


## Collega la partita (e la run, quando esiste) da mostrare a schermo.
func bind(match_controller: MatchController, game_run: GameManager = null) -> void:
	controller = match_controller
	run = game_run
	refresh()


## Mostra un messaggio rapido al centro dello schermo (GDD §4).
func flash(text: String, color: Color = ACCENT) -> void:
	if _flash_label == null:
		return
	_flash_label.text = text
	_flash_label.add_theme_color_override("font_color", color)
	_flash_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_flash_time_left = FLASH_DURATION


## Sostituisce il suggerimento sui comandi in basso al centro.
func set_hint(text: String) -> void:
	if _hint_label != null:
		_hint_label.text = text


## Riscrive tutti i valori a schermo leggendo lo stato del controller.
func refresh() -> void:
	if _score_label == null:
		return
	if controller == null:
		_score_label.text = "NESSUNA PARTITA"
		_context_label.text = ""
		return
	var opponent_name := "Avversaria"
	if controller.ai_team != null and not controller.ai_team.team_name.is_empty():
		opponent_name = controller.ai_team.team_name
	var team_name := "Giocatore"
	if controller.player_team != null and not controller.player_team.team_name.is_empty():
		team_name = controller.player_team.team_name
	_score_label.text = "%s   %d : %d   %s" % [team_name, controller.score_player, controller.score_ai, opponent_name]
	_context_label.text = _build_context_text()
	_save_label.text = "%s / %s" % [_format_points(controller.save_points), _format_points(controller.save_points_max)]
	_resource_label.text = "%d passaggi     %d tiri" % [controller.passes_left, controller.shots_left]
	_resource_caption.text = "AZIONE #%d     SAGOME %d" % [controller.action_index, controller.obstacles.size()]
	_power_label.text = "%.1f" % controller.accumulated_action_power
	_phase_label.text = "FASE %s" % controller.get_phase_name()
	_resource_label.add_theme_color_override("font_color", DANGER if controller.shots_left <= 1 else TEXT_MAIN)
	queue_redraw()


func _draw() -> void:
	_draw_panel(SCORE_PANEL)
	_draw_panel(SAVE_PANEL)
	_draw_panel(RESOURCE_PANEL)
	_draw_panel(POWER_PANEL)
	_draw_save_bar()


## Riquadro semitrasparente con bordo neon (GDD §12).
func _draw_panel(rect: Rect2) -> void:
	draw_rect(rect, PANEL_FILL, true)
	draw_rect(rect, PANEL_EDGE, false, 2.0)


## Barra di avanzamento dei punti parata residui (GDD §7).
func _draw_save_bar() -> void:
	draw_rect(SAVE_BAR, SAVE_BAR_BACK, true)
	if controller == null or controller.save_points_max <= 0.0:
		return
	var ratio := clampf(controller.save_points / controller.save_points_max, 0.0, 1.0)
	var fill := ACCENT
	if ratio > 0.66:
		fill = DANGER
	elif ratio > 0.33:
		fill = WARN
	draw_rect(Rect2(SAVE_BAR.position, Vector2(SAVE_BAR.size.x * ratio, SAVE_BAR.size.y)), fill, true)


## Riga di contesto: Ante, match, boss e Football Coins della run (GDD §3 e §8).
func _build_context_text() -> String:
	if run == null:
		return "Amichevole   ·   obiettivo %s punti parata" % _format_points(controller.save_points_max)
	var boss_name := "nessuno"
	if run.current_boss != null:
		boss_name = run.current_boss.boss_name
	return "Ante %d   ·   Match %d/%d   ·   Boss: %s   ·   %d FC" % [run.current_cup, run.current_match_index, GameManager.MATCHES_PER_CUP, boss_name, run.budget]


## Numero compatto per i punti parata, che in Ante 6 arrivano a 60.000 (GDD §7).
func _format_points(value: float) -> String:
	if value >= 10000.0:
		return "%.1fk" % (value / 1000.0)
	return "%.0f" % value


## Costruisce tutte le etichette dell'HUD: nessuna dipende da file esterni.
func _build_labels() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_score_label = _add_label("ScoreLabel", _inset(SCORE_PANEL, 20.0, 6.0, 48.0), 34, HORIZONTAL_ALIGNMENT_LEFT, TEXT_MAIN)
	_context_label = _add_label("ContextLabel", _inset(SCORE_PANEL, 20.0, 54.0, 34.0), 18, HORIZONTAL_ALIGNMENT_LEFT, TEXT_DIM)
	_save_caption = _add_label("SaveCaption", _inset(SAVE_PANEL, 20.0, 8.0, 28.0), 17, HORIZONTAL_ALIGNMENT_RIGHT, TEXT_DIM)
	_save_caption.text = "PUNTI PARATA PORTIERE"
	_save_label = _add_label("SaveLabel", _inset(SAVE_PANEL, 20.0, 32.0, 46.0), 32, HORIZONTAL_ALIGNMENT_RIGHT, TEXT_MAIN)
	_resource_label = _add_label("ResourceLabel", _inset(RESOURCE_PANEL, 20.0, 8.0, 48.0), 30, HORIZONTAL_ALIGNMENT_LEFT, TEXT_MAIN)
	_resource_caption = _add_label("ResourceCaption", _inset(RESOURCE_PANEL, 20.0, 56.0, 32.0), 17, HORIZONTAL_ALIGNMENT_LEFT, TEXT_DIM)
	var power_caption := _add_label("PowerCaption", _inset(POWER_PANEL, 20.0, 10.0, 32.0), 17, HORIZONTAL_ALIGNMENT_LEFT, TEXT_DIM)
	power_caption.text = "POTENZA AZIONE"
	_power_label = _add_label("PowerLabel", _inset(POWER_PANEL, 20.0, 4.0, 50.0), 34, HORIZONTAL_ALIGNMENT_RIGHT, ACCENT)
	_phase_label = _add_label("PhaseLabel", _inset(POWER_PANEL, 20.0, 56.0, 32.0), 17, HORIZONTAL_ALIGNMENT_RIGHT, TEXT_DIM)
	_hint_label = _add_label("HintLabel", HINT_RECT, 18, HORIZONTAL_ALIGNMENT_CENTER, TEXT_DIM)
	_hint_label.text = "Trascina dal portatore: su un compagno passi, verso la porta tiri"
	_flash_label = _add_label("FlashLabel", FLASH_RECT, FLASH_FONT_SIZE, HORIZONTAL_ALIGNMENT_CENTER, FLASH_GOAL)


## Riquadro di testo interno a un pannello dell'HUD.
func _inset(panel: Rect2, margin_x: float, offset_y: float, height: float) -> Rect2:
	return Rect2(panel.position + Vector2(margin_x, offset_y), Vector2(panel.size.x - margin_x * 2.0, height))


## Etichetta posizionata in coordinate di design, indipendente dal tema.
func _add_label(label_name: String, rect: Rect2, font_size: int, alignment: int, color: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label
