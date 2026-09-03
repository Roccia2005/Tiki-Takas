class_name Main
extends Node

## Orchestratore della run: tiene insieme menu, partita, mercato e schermate
## finali senza mai ricaricare l'applicazione (GDD §3).
##
## È l'unico nodo che possiede l'istanza di [GameManager]: la crea all'avvio con
## la rosa sorteggiata da [TeamGenerator] e i Football Coins iniziali, poi
## commuta le scene figlie seguendo lo stato della run. Le regole restano nel
## core: qui si ascoltano i segnali delle viste e si chiamano
## [method GameManager.record_match_result], [method GameManager.open_shop] e
## [method GameManager.advance_to_next_match].

## Fasi della macchina a stati (GDD §3).
enum Stage {
	MENU,
	MATCH,
	SHOP,
	BOSS_MATCH,
	GAME_OVER,
	VICTORY,
}

## Nomi delle fasi, nell'ordine di Stage.
const STAGE_NAMES := ["MENU_INIZIALE", "PARTITA", "NEGOZIO", "BOSS_MATCH", "GAME_OVER", "VITTORIA"]

const MATCH_SCENE_PATH := "res://scenes/match/MatchView.tscn"
const SHOP_SCENE_PATH := "res://scenes/shop/ShopView.tscn"

## Squadra e budget con cui parte ogni nuova carriera (GDD §2.3 e §3).
const STARTING_TEAM := "Standard"
const STARTING_BUDGET: int = GameManager.DEFAULT_BUDGET

## Con false la run va avviata a mano con [method start_new_run].
@export var autostart: bool = true

## Seme dei generatori per una carriera ripetibile, 0 per lasciarli casuali.
@export var run_seed: int = 0

## Run in corso, unica istanza di [GameManager] dell'applicazione.
var run: GameManager = null

## Fase corrente, da Stage.
var stage: int = Stage.MENU

var _stage_layer: CanvasLayer = null
var _overlay_layer: CanvasLayer = null
var _match_view: MatchView = null
var _shop_view: ShopView = null
var _title: TitleScreen = null
var _result: MatchResultModal = null
var _game_over: GameOverScreen = null
var _victory: VictoryScreen = null


func _ready() -> void:
	_resolve_nodes()
	_connect_views()
	if autostart:
		start_new_run()
	else:
		_enter_stage(Stage.MENU)


## Prepara una carriera nuova: rosa generata, budget iniziale e menu in scena
## (GDD §2.3 e §3). False se la generazione della squadra fallisce.
func start_new_run() -> bool:
	if run_seed != 0:
		TeamGenerator.set_seed(run_seed)
		ShopManager.set_seed(run_seed)
	run = GameManager.new()
	if run_seed != 0:
		run.set_seed(run_seed)
	var team := TeamGenerator.generate_starter_team(null, STARTING_TEAM)
	if team == null or not run.start_new_run(team, STARTING_BUDGET):
		push_error("Main: impossibile avviare la run")
		return false
	_title.bind_run(run)
	_result.visible = false
	_enter_stage(Stage.MENU)
	return true


## Nome leggibile della fase corrente, utile ai test headless.
func get_stage_name() -> String:
	return STAGE_NAMES[clampi(stage, 0, STAGE_NAMES.size() - 1)]


## Avvia il match successivo della run e mostra il campo (GDD §3 e §8).
func start_next_match() -> bool:
	if run == null:
		return false
	var controller := run.start_match()
	if controller == null:
		push_error("Main: GameManager non ha restituito un match")
		return false
	_result.visible = false
	_match_view.bind_controller(controller, run)
	_enter_stage(Stage.BOSS_MATCH if run.is_boss_match() else Stage.MATCH)
	return true


## Apre il Calcio Mercato sulla vetrina già generata dal core (GDD §6).
func open_shop() -> void:
	if run == null:
		return
	if run.run_state != GameManager.RunState.SHOP_PHASE:
		run.open_shop()
	_shop_view.bind_run(run)
	_enter_stage(Stage.SHOP)


## Mostra solo i nodi della fase richiesta e sospende le viste in pausa. Il
## campo va spento con [method MatchView.set_view_active]: il suo HUD vive in un
## CanvasLayer, che non eredita la visibilità del Node2D e resterebbe dipinto
## sopra mercato e schermate di stato (GDD §12).
func _enter_stage(next_stage: int) -> void:
	stage = next_stage
	var playing := stage == Stage.MATCH or stage == Stage.BOSS_MATCH
	var shopping := stage == Stage.SHOP
	_match_view.set_view_active(playing)
	_shop_view.visible = shopping
	_shop_view.process_mode = Node.PROCESS_MODE_INHERIT if shopping else Node.PROCESS_MODE_DISABLED
	_title.visible = stage == Stage.MENU
	_result.visible = false
	_game_over.visible = stage == Stage.GAME_OVER
	_victory.visible = stage == Stage.VICTORY


## Il menu iniziale ha dato il via: si scende in campo per il primo match.
func _on_start_requested() -> void:
	start_next_match()


## Fine partita: il core registra il risultato e assegna i premi (GDD §3).
func _on_match_finished(won: bool) -> void:
	if run == null:
		return
	var controller := _match_view.controller
	if controller == null:
		return
	var report := run.record_match_result(won, controller.score_player, controller.score_ai, controller.passes_left, controller.shots_left)
	_result.show_result(run, report, controller)


## Il riquadro di fine partita è stato chiuso: la fase successiva dipende dallo
## stato in cui la run è entrata (GDD §3). Ogni ramo esce subito con un return,
## così [method _advance] non può scavalcare il Calcio Mercato né una schermata
## finale: avanza di partita solo in RunState.RUN_ACTIVE.
func _on_result_continue() -> void:
	_result.visible = false
	if run == null:
		return
	if run.run_state == GameManager.RunState.SHOP_PHASE:
		open_shop()
		return
	if run.run_state == GameManager.RunState.GAME_OVER:
		_show_game_over()
		return
	if run.run_state == GameManager.RunState.CUP_VICTORY:
		_show_victory()
		return
	if run.run_state == GameManager.RunState.RUN_ACTIVE:
		_advance()
		return
	push_warning("Main: fase %s inattesa a fine partita, nessuna transizione" % run.get_state_name())


## Uscita dal mercato: si chiude la visita e si passa al match successivo.
func _on_shop_finished() -> void:
	if run == null:
		return
	run.close_shop()
	_advance()


## Avanza di un match, oppure chiude la run se il mondiale è finito (GDD §3).
func _advance() -> void:
	if run.advance_to_next_match():
		start_next_match()
		return
	if run.run_state == GameManager.RunState.CUP_VICTORY:
		_show_victory()
		return
	_show_game_over()


func _show_game_over() -> void:
	_game_over.show_run(run)
	_enter_stage(Stage.GAME_OVER)


func _show_victory() -> void:
	_victory.show_run(run)
	_enter_stage(Stage.VICTORY)


## Collega i segnali delle viste una sola volta.
func _connect_views() -> void:
	_title.start_requested.connect(_on_start_requested)
	_match_view.match_finished.connect(_on_match_finished)
	_result.continue_requested.connect(_on_result_continue)
	_shop_view.next_match_requested.connect(_on_shop_finished)
	_game_over.restart_requested.connect(func() -> void: start_new_run())
	_victory.menu_requested.connect(func() -> void: start_new_run())


## Recupera i nodi della scena e crea quelli mancanti, così lo script resta
## eseguibile anche montato su un Node vuoto.
func _resolve_nodes() -> void:
	_stage_layer = _child_of(self, "StageLayer", CanvasLayer.new) as CanvasLayer
	_overlay_layer = _child_of(self, "OverlayLayer", CanvasLayer.new) as CanvasLayer
	_match_view = _child_of(_stage_layer, "MatchView", _make_match_view) as MatchView
	_shop_view = _child_of(_stage_layer, "ShopView", _make_shop_view) as ShopView
	_title = _child_of(_overlay_layer, "TitleScreen", TitleScreen.new) as TitleScreen
	_result = _child_of(_overlay_layer, "MatchResultModal", MatchResultModal.new) as MatchResultModal
	_game_over = _child_of(_overlay_layer, "GameOverScreen", GameOverScreen.new) as GameOverScreen
	_victory = _child_of(_overlay_layer, "VictoryScreen", VictoryScreen.new) as VictoryScreen
	_result.visible = false
	_game_over.visible = false
	_victory.visible = false


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


## Campo di gioco del Sprint 7, con la partita di prova disattivata.
func _make_match_view() -> MatchView:
	var scene := load(MATCH_SCENE_PATH) as PackedScene
	var view: MatchView = null
	if scene != null:
		view = scene.instantiate() as MatchView
	if view == null:
		view = MatchView.new()
	view.autostart_demo_run = false
	return view


## Schermata del Calcio Mercato.
func _make_shop_view() -> ShopView:
	var scene := load(SHOP_SCENE_PATH) as PackedScene
	var view: ShopView = null
	if scene != null:
		view = scene.instantiate() as ShopView
	if view == null:
		view = ShopView.new()
	return view
