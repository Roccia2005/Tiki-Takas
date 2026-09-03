class_name MatchView
extends Node2D

## Scena giocabile della partita: disegna il campo, le pedine e la palla, e
## traduce il mouse in passaggi e tiri di [MatchController] (GDD §4 e §4.1).
##
## Il layer visuale non contiene formule: ogni esito arriva dal controller, che
## a sua volta delega la matematica ad [ActionResolver]. Qui si fa solo tre
## cose: leggere lo stato, disegnarlo, inoltrare l'input del giocatore.
## [br][br]Comandi: premi e trascina dal portatore di palla, rilascia su un
## compagno per passare oppure dentro la zona porta per calciare. Dopo un tiro
## o una palla persa un clic (o SPAZIO) fa ripartire l'azione, R avvia una
## nuova partita di prova.

## Partita conclusa: [code]won[/code] è true se il portiere è stato battuto
## (GDD §7). [Main] la usa per registrare il risultato nella run.
signal match_finished(won: bool)

## Stato dell'interazione col mouse.
enum InputMode {
	IDLE,
	AIMING,
	WAITING_RESTART,
	MATCH_OVER,
}

## Raggio, in unità pitch, entro cui il clic afferra la palla del portatore.
const BALL_GRAB_RADIUS: float = 44.0

## Squadra e Ante della partita di prova avviata quando la scena parte da sola.
const DEMO_TEAM_NAME := "Standard"

## Angolo in alto a sinistra del campo nel canvas 1920x1080 (GDD §12).
const PITCH_ORIGIN := Vector2(210.0, 90.0)

## Ingrandimento delle unità pitch: 1000x600 diventa 1500x900 a schermo.
const PITCH_SCALE: float = 1.5

## Avvia una partita di prova in autonomia: utile per eseguire questa scena
## direttamente. Con false la scena attende [method bind_controller].
@export var autostart_demo_run: bool = true

## Squadra usata dalla partita di prova (GDD §2.3).
@export var demo_team_name: String = DEMO_TEAM_NAME

## Ante della partita di prova: da 2 in su compaiono le sagome (GDD §4.1).
@export_range(1, 6) var demo_cup: int = 1

## Seme dei generatori per una prova ripetibile, 0 per lasciarli casuali.
@export var demo_seed: int = 0

## Partita osservata e pilotata dalla scena.
var controller: MatchController = null

## Run di appartenenza, se la partita arriva da [GameManager] (GDD §3).
var run: GameManager = null

var _pitch_root: Node2D = null
var _pitch_view: PitchView = null
var _tokens_root: Node2D = null
var _cone: ShotConeVisualizer = null
var _trajectory: TrajectoryLine = null
var _ball: BallToken = null
var _hud: MatchHUD = null
var _hud_layer: CanvasLayer = null

var _tokens: Dictionary[int, PlayerToken] = {}
var _obstacle_tokens: Array[PlayerToken] = []
var _keeper_token: PlayerToken = null
var _input_mode: int = InputMode.IDLE
var _hovered: PlayerToken = null
var _finished_emitted: bool = false


func _ready() -> void:
	_resolve_nodes()
	if controller == null and autostart_demo_run:
		start_demo_match()
	else:
		_bind_views()


## Collega una partita già avviata (di norma quella di [GameManager]) e ridisegna
## tutto: pedine dei titolari, portiere avversario e sagome del §4.1.
func bind_controller(match_controller: MatchController, game_run: GameManager = null) -> void:
	controller = match_controller
	run = game_run
	_input_mode = InputMode.IDLE
	_finished_emitted = false
	_bind_views()


## Accende o spegne l'intera scena della partita, HUD compreso: [Main] la chiama
## a ogni cambio di fase (GDD §3). Serve un metodo dedicato perché [member
## Node2D.visible] non arriva a [code]HUDLayer[/code], che è un [CanvasLayer] e
## quindi disegna sul proprio canvas: senza questo passaggio i pannelli del match
## resterebbero dipinti sopra Calcio Mercato e schermate di stato (GDD §12).
func set_view_active(active: bool) -> void:
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if _hud_layer == null:
		_hud_layer = get_node_or_null(NodePath("HUDLayer")) as CanvasLayer
	if _hud_layer != null:
		_hud_layer.visible = active


## Avvia una partita di prova completa passando da [GameManager], così valgono
## punti parata, malus del boss e sagome dell'Ante scelta (GDD §3, §7 e §8).
func start_demo_match() -> bool:
	if demo_seed != 0:
		TeamGenerator.set_seed(demo_seed)
	var demo_run := GameManager.new()
	if demo_seed != 0:
		demo_run.set_seed(demo_seed)
	var team := TeamGenerator.generate_starter_team(null, demo_team_name)
	if team == null or not demo_run.start_new_run(team):
		push_error("MatchView: impossibile avviare la partita di prova")
		return false
	demo_run.current_cup = clampi(demo_cup, GameManager.FIRST_CUP, GameManager.LAST_CUP)
	var demo_controller := demo_run.start_match()
	if demo_controller == null:
		push_error("MatchView: GameManager non ha restituito un match")
		return false
	bind_controller(demo_controller, demo_run)
	return true


func _unhandled_input(event: InputEvent) -> void:
	if controller == null:
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				_on_press(_mouse_field_position())
			else:
				_on_release(_mouse_field_position())
		return
	if event is InputEventMouseMotion:
		if _input_mode == InputMode.AIMING:
			_update_aim(_mouse_field_position())
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			_on_key(key.keycode)


## Clic sinistro: fa ripartire l'azione dopo un tiro o una palla persa, oppure
## impugna la palla del portatore per iniziare la mira.
func _on_press(field_pos: Vector2) -> void:
	if _input_mode == InputMode.MATCH_OVER:
		return
	if _input_mode == InputMode.WAITING_RESTART:
		_start_next_action()
		return
	var carrier := controller.current_ball_carrier
	if carrier == null:
		return
	var carrier_token := _token_of(carrier)
	var on_carrier := field_pos.distance_to(controller.ball_position) <= BALL_GRAB_RADIUS
	if carrier_token != null and carrier_token.contains_point(field_pos):
		on_carrier = true
	if not on_carrier:
		_hud.set_hint("Trascina dalla pedina con la palla per mirare")
		return
	_begin_aim(field_pos)


## Rilascio del mouse: passaggio se il puntatore è su un compagno, tiro se è
## dentro la zona porta, mira annullata altrimenti.
func _on_release(field_pos: Vector2) -> void:
	if _input_mode != InputMode.AIMING:
		return
	_end_aim()
	var target := _token_at(field_pos)
	if target != null and target.side == PlayerToken.Side.PLAYER and target.player != controller.current_ball_carrier:
		_do_pass(target.player)
		return
	if PitchView.goal_aim_zone().has_point(field_pos):
		_do_shot()
		return
	_hud.flash("MIRA ANNULLATA", MatchHUD.TEXT_DIM)
	_refresh_all()


## SPAZIO riparte con l'azione successiva, R avvia una nuova partita di prova.
func _on_key(keycode: Key) -> void:
	if keycode == KEY_SPACE or keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
		if _input_mode == InputMode.WAITING_RESTART:
			_start_next_action()
		return
	if keycode == KEY_R and autostart_demo_run:
		start_demo_match()


## Entra in mira: accende la zona porta e marca i compagni ricevibili.
func _begin_aim(field_pos: Vector2) -> void:
	_input_mode = InputMode.AIMING
	_pitch_view.set_goal_zone_highlight(true)
	_update_aim(field_pos)


## Esce dalla mira e spegne traiettoria, cono e zona porta.
func _end_aim() -> void:
	_input_mode = InputMode.IDLE
	_hovered = null
	_trajectory.clear_aim()
	_cone.clear_cone()
	_pitch_view.set_goal_zone_highlight(false)


## Aggiorna traiettoria, cono di tiro ed evidenziazioni mentre il mouse si
## muove: verde passaggio in gittata, ambra fuori gittata, rosso non valido. I
## numeri restano nei pannelli dell'HUD, la linea di mira non porta etichette
## galleggianti (GDD §12).
func _update_aim(field_pos: Vector2) -> void:
	var carrier := controller.current_ball_carrier
	if carrier == null:
		_end_aim()
		return
	var from := controller.ball_position
	_hovered = _token_at(field_pos)
	if _hovered != null and (_hovered.side != PlayerToken.Side.PLAYER or _hovered.player == carrier):
		_hovered = null
	if _hovered != null:
		var to := _hovered.position
		var state := TrajectoryLine.AimState.PASS_VALID
		if not controller.can_pass():
			state = TrajectoryLine.AimState.PASS_INVALID
		elif not ActionResolver.is_pass_in_range(carrier, from, to):
			state = TrajectoryLine.AimState.PASS_OUT_OF_RANGE
		_trajectory.aim(from, to, state)
		_cone.clear_cone()
	elif PitchView.goal_aim_zone().has_point(field_pos):
		var state := TrajectoryLine.AimState.SHOT
		if not controller.can_shoot():
			state = TrajectoryLine.AimState.PASS_INVALID
		_trajectory.aim(from, PitchView.enemy_goal_position(), state)
		_cone.show_cone(from, controller.obstacles)
	else:
		_trajectory.aim(from, field_pos, TrajectoryLine.AimState.PASS_INVALID)
		_cone.clear_cone()
	_refresh_tokens()


## Passaggio al compagno indicato e messaggio di esito minimale: il nome
## dell'intercettante resta nel suggerimento in basso (GDD §4 e §12).
func _do_pass(target: PlayerData) -> void:
	var result := controller.execute_pass(target)
	if not bool(result.get("executed", false)):
		_hud.flash(str(result.get("reason", "mossa non valida")).to_upper(), MatchHUD.FLASH_BAD)
	elif not bool(result.get("success", false)):
		_hud.flash("INTERCETTATO", MatchHUD.FLASH_BAD)
	elif bool(result.get("turnover", false)):
		_hud.flash("PALLA PERSA", MatchHUD.FLASH_BAD)
	else:
		_hud.flash("PASSAGGIO", MatchHUD.ACCENT)
	_after_move()


## Tiro in porta e messaggio di esito: gol, parata o tiro murato (GDD §4 e §7).
func _do_shot() -> void:
	var result := controller.execute_shot()
	if not bool(result.get("executed", false)):
		_hud.flash(str(result.get("reason", "mossa non valida")).to_upper(), MatchHUD.FLASH_BAD)
		_after_move()
		return
	if bool(result.get("is_goal", false)):
		_hud.flash("GOL", MatchHUD.FLASH_GOAL)
	elif bool(result.get("blocked", false)):
		_hud.flash("TIRO MURATO", MatchHUD.FLASH_BAD)
	else:
		_hud.flash("PARATA", MatchHUD.FLASH_SAVE)
	_after_move()


## Dopo ogni mossa: ridisegna tutto e decide come proseguire. Con la palla in
## viaggio si torna a giocare, senza portatore si attende il via all'azione
## successiva, a match deciso l'input si chiude (GDD §4).
func _after_move() -> void:
	_refresh_all()
	if controller.is_match_over():
		_input_mode = InputMode.MATCH_OVER
		_hud.set_hint(_match_over_hint())
		_emit_finished()
		return
	if controller.current_ball_carrier == null:
		_input_mode = InputMode.WAITING_RESTART
		_hud.set_hint(_restart_hint())
		return
	_input_mode = InputMode.IDLE
	_hud.set_hint(_default_hint())


## Riparte con una nuova azione: il portatore lo decide MatchController secondo le
## fasce di respinta del GDD §4 e §4.1, il portiere entra in gioco solo su
## rimessa dal fondo o a inizio partita.
func _start_next_action() -> void:
	if controller.is_match_over():
		_input_mode = InputMode.MATCH_OVER
		_hud.set_hint(_match_over_hint())
		_emit_finished()
		return
	if not controller.start_action():
		_hud.flash("NESSUNA AZIONE DISPONIBILE", MatchHUD.FLASH_BAD)
		return
	_ball.snap_to(controller.ball_position)
	_input_mode = InputMode.IDLE
	_hud.flash(_restart_message(), MatchHUD.ACCENT)
	_refresh_all()
	_hud.set_hint(_default_hint())


## Annuncio minimale della ripartenza: solo il numero dell'azione, chi ha
## raccolto la palla resta nel suggerimento in basso (GDD §12).
func _restart_message() -> String:
	return "AZIONE #%d" % controller.action_index


## Suggerimento con la palla fuori dal possesso: dice dove si trova la sfera
## prima della ripartenza (GDD §4 e §4.1).
func _restart_hint() -> String:
	if controller.last_interceptor != null:
		return "Palla a %s: clic o SPAZIO per la prossima azione" % controller.last_interceptor.player_name
	if controller.match_phase == MatchController.MatchPhase.GOAL:
		return "Rimessa dal fondo: clic o SPAZIO per la prossima azione"
	return "Clic o SPAZIO per la prossima azione"


## Annuncia la fine del match una sola volta per partita collegata (GDD §7).
func _emit_finished() -> void:
	if _finished_emitted or controller == null:
		return
	_finished_emitted = true
	match_finished.emit(controller.match_result == MatchController.MatchResult.WIN)

func _refresh_all() -> void:
	_refresh_tokens()
	_refresh_ball()
	_hud.refresh()


## Allinea la palla alla sua posizione sul campo e ne accende il bagliore con la
## Potenza Azione. Senza portatore la sfera resta visibile dove il gioco l'ha
## lasciata, cioè sulla sagoma che ha intercettato o sulla respinta del portiere
## avversario: non viene più nascosta né riportata d'ufficio al battitore
## (GDD §4 e §4.1).
func _refresh_ball() -> void:
	_ball.set_power(controller.accumulated_action_power)
	_ball.visible = true
	_ball.move_to(controller.ball_position)


## Riporta pedine e sagome sullo stato del controller: posizioni dal modulo
## attivo, portatore di palla e sagome dentro il cono di tiro (GDD §4.1).
func _refresh_tokens() -> void:
	var carrier := controller.current_ball_carrier
	for slot in _tokens:
		var token: PlayerToken = _tokens[slot]
		token.set_field_position(controller.get_player_position(token.player))
		token.set_state(token.player == carrier)
	var in_cone: Array[PlayerData] = []
	if carrier != null:
		in_cone = ActionResolver.filter_defenders_in_cone(controller.obstacles, controller.ball_position, PitchView.enemy_goal_position())
	for shape in _obstacle_tokens:
		shape.set_state(false, in_cone.has(shape.player))


## Collega la partita a HUD e pedine e riporta la palla al battitore.
func _bind_views() -> void:
	_rebuild_tokens()
	_hud.bind(controller, run)
	if controller == null:
		_ball.visible = false
		_hud.set_hint("Nessuna partita collegata")
		return
	_ball.snap_to(controller.ball_position)
	_refresh_all()
	if controller.is_match_over():
		_input_mode = InputMode.MATCH_OVER
		_hud.set_hint(_match_over_hint())
	elif controller.current_ball_carrier == null:
		_input_mode = InputMode.WAITING_RESTART
		_hud.set_hint(_restart_hint())
	else:
		_input_mode = InputMode.IDLE
		_hud.set_hint(_default_hint())


## Ricrea le pedine: gli 11 titolari, il portiere avversario e le sagome
## difensive passive dell'Ante in corso (GDD §4.1).
func _rebuild_tokens() -> void:
	_tokens.clear()
	_obstacle_tokens.clear()
	_keeper_token = null
	_hovered = null
	for child in _tokens_root.get_children():
		_tokens_root.remove_child(child)
		child.queue_free()
	if controller == null or controller.player_team == null:
		return
	for slot in range(1, TeamData.LINEUP_SIZE + 1):
		var starter := controller.player_team.get_starter(slot)
		if starter == null:
			continue
		var token := PlayerToken.new()
		token.name = "Titolare%02d" % slot
		token.setup(starter, PlayerToken.Side.PLAYER, slot)
		token.set_field_position(controller.get_player_position(starter))
		_tokens_root.add_child(token)
		_tokens[slot] = token
	var keeper := controller.get_opponent_goalkeeper()
	if keeper != null:
		_keeper_token = PlayerToken.new()
		_keeper_token.name = "PortiereAvversario"
		_keeper_token.setup(keeper, PlayerToken.Side.OPPONENT, 1)
		_keeper_token.set_field_position(controller.goalkeeper_position)
		_tokens_root.add_child(_keeper_token)
	var index := 0
	for entry in controller.obstacles:
		index += 1
		var shape: PlayerData = entry.get("player")
		if shape == null:
			continue
		var marker := PlayerToken.new()
		marker.name = "Sagoma%d" % index
		marker.setup(shape, PlayerToken.Side.OPPONENT, index)
		marker.intercept_radius = float(entry.get("radius", ActionResolver.DEFAULT_INTERCEPT_RADIUS))
		marker.set_field_position(entry.get("position", Vector2.ZERO))
		_tokens_root.add_child(marker)
		_obstacle_tokens.append(marker)


## Pedina che occupa il punto indicato, null se il clic è a vuoto. I titolari
## hanno la precedenza sulle sagome avversarie.
func _token_at(field_pos: Vector2) -> PlayerToken:
	for slot in _tokens:
		var token: PlayerToken = _tokens[slot]
		if token.contains_point(field_pos):
			return token
	for shape in _obstacle_tokens:
		if shape.contains_point(field_pos):
			return shape
	if _keeper_token != null and _keeper_token.contains_point(field_pos):
		return _keeper_token
	return null


## Pedina del cartellino indicato, null se non è schierato.
func _token_of(card: PlayerData) -> PlayerToken:
	if card == null:
		return null
	for slot in _tokens:
		var token: PlayerToken = _tokens[slot]
		if token.player == card:
			return token
	return null


## Posizione del mouse convertita nelle unità pitch 1000x600 (GDD §9).
func _mouse_field_position() -> Vector2:
	if _pitch_root == null:
		return get_global_mouse_position()
	return _pitch_root.to_local(_pitch_root.get_global_mouse_position())


## Suggerimento standard con i contatori residui del match (GDD §4).
func _default_hint() -> String:
	return "Trascina dal portatore: rilascia su un compagno per passare (%d), sulla porta per tirare (%d)" % [controller.passes_left, controller.shots_left]


## Suggerimento di fine partita.
func _match_over_hint() -> String:
	var closing := "PARTITA PERSA: punti parata non azzerati"
	if controller.match_result == MatchController.MatchResult.WIN:
		closing = "PARTITA VINTA: portiere battuto"
	if autostart_demo_run:
		closing += "   -   premi R per una nuova prova"
	return closing


## Recupera i nodi della scena e crea quelli mancanti, così lo script resta
## eseguibile anche montato su un Node2D vuoto.
func _resolve_nodes() -> void:
	_pitch_root = _child_of(self, "PitchRoot", _make_pitch_root) as Node2D
	_pitch_view = _child_of(_pitch_root, "PitchView", PitchView.new) as PitchView
	_cone = _child_of(_pitch_root, "ShotCone", ShotConeVisualizer.new) as ShotConeVisualizer
	_trajectory = _child_of(_pitch_root, "TrajectoryLine", TrajectoryLine.new) as TrajectoryLine
	_tokens_root = _child_of(_pitch_root, "TokensRoot", Node2D.new) as Node2D
	_ball = _child_of(_pitch_root, "BallToken", BallToken.new) as BallToken
	_hud_layer = _child_of(self, "HUDLayer", CanvasLayer.new) as CanvasLayer
	_hud = _child_of(_hud_layer, "MatchHUD", _make_hud) as MatchHUD


## Figlio con quel nome se già presente nella scena, altrimenti il nodo
## costruito da [param factory] e aggiunto all'albero.
func _child_of(parent: Node, node_name: String, factory: Callable) -> Node:
	var existing := parent.get_node_or_null(NodePath(node_name))
	if existing != null:
		return existing
	var created: Node = factory.call()
	created.name = node_name
	parent.add_child(created)
	return created


## Radice del campo: sposta e scala le unità pitch dentro il canvas di progetto.
func _make_pitch_root() -> Node2D:
	var root := Node2D.new()
	root.position = PITCH_ORIGIN
	root.scale = Vector2(PITCH_SCALE, PITCH_SCALE)
	return root


## HUD a schermo pieno, trasparente all'input così il mouse resta al campo.
func _make_hud() -> MatchHUD:
	var hud := MatchHUD.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return hud
