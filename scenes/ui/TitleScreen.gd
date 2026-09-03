class_name TitleScreen
extends Control

## Menu iniziale della carriera (GDD §3).
##
## Presenta la rosa sorteggiata dalla run appena preparata da [GameManager] e
## attende il via del giocatore. Nessuna logica: la generazione della squadra e
## il budget di partenza restano in [TeamGenerator] e [GameManager].

## Il giocatore chiede di scendere in campo per il primo match.
signal start_requested

const PANEL := Rect2(460.0, 210.0, 1000.0, 660.0)
const TITLE_RECT := Rect2(480.0, 250.0, 960.0, 96.0)
const SUBTITLE_RECT := Rect2(480.0, 344.0, 960.0, 36.0)
const TEAM_RECT := Rect2(500.0, 424.0, 920.0, 44.0)
const ROSTER_RECT := Rect2(500.0, 472.0, 920.0, 176.0)
const CONTROLS_RECT := Rect2(500.0, 656.0, 920.0, 108.0)
const BUTTON_RECT := Rect2(660.0, 782.0, 600.0, 64.0)
const RULE_Y: float = 404.0

var run: GameManager = null

var _team_label: Label = null
var _roster_label: Label = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	refresh()


## Collega la run da presentare nel menu.
func bind_run(game_run: GameManager) -> void:
	run = game_run
	refresh()


## Riscrive squadra, rosa e budget di partenza.
func refresh() -> void:
	if _team_label == null:
		return
	if run == null or run.player_team == null:
		_team_label.text = "Nessuna squadra generata"
		_roster_label.text = ""
		return
	var team := run.player_team
	_team_label.text = "%s   ·   %d Football Coins   ·   modulo %s" % [team.team_name, run.budget, _formation_name(team)]
	_roster_label.text = _build_roster_text(team)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, UIStyle.DESIGN_SIZE), UIStyle.BACKDROP, true)
	UIStyle.draw_panel(self, PANEL)
	UIStyle.draw_rule(self, Vector2(PANEL.position.x + 40.0, RULE_Y), Vector2(PANEL.end.x - 40.0, RULE_Y))


## Nome del modulo in uso, trattino se la squadra non ne ha uno.
func _formation_name(team: TeamData) -> String:
	var formation := team.current_formation as FormationData
	if formation == null or formation.formation_name.is_empty():
		return "-"
	return formation.formation_name


## Riepilogo dell'undici titolare per reparto, una riga per ruolo (GDD §2.3).
func _build_roster_text(team: TeamData) -> String:
	var lines := ""
	for role in PlayerData.ROLES:
		var names: Array[String] = []
		for slot in range(1, TeamData.LINEUP_SIZE + 1):
			var starter := team.get_starter(slot)
			if starter != null and starter.role == role:
				names.append("%s (F%d)" % [starter.player_name, starter.power])
		if names.is_empty():
			continue
		lines += "%s   %s\n" % [str(role), "   ·   ".join(names)]
	return lines


## Costruisce titolo, riepilogo e pulsante di avvio.
func _build() -> void:
	add_child(UIStyle.make_label("TIKI TAKAS", TITLE_RECT, 72, UIStyle.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	add_child(UIStyle.make_label("Carriera roguelike: 6 Ante, 3 match ciascuna, un boss a chiudere ogni coppa", SUBTITLE_RECT, 20, UIStyle.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_team_label = UIStyle.make_label("", TEAM_RECT, 26, UIStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_team_label)
	_roster_label = UIStyle.make_paragraph("", ROSTER_RECT, 17, UIStyle.TEXT_MAIN)
	add_child(_roster_label)
	add_child(UIStyle.make_paragraph("Comandi: trascina dal portatore di palla e rilascia su un compagno per passare, dentro la zona porta per tirare. SPAZIO fa ripartire l'azione. Batti i punti parata del portiere prima di esaurire i tiri.", CONTROLS_RECT, 17, UIStyle.TEXT_DIM))
	var button := UIStyle.make_button("INIZIA LA CARRIERA", BUTTON_RECT, 28, UIStyle.ACCENT)
	button.pressed.connect(func() -> void: start_requested.emit())
	add_child(button)
