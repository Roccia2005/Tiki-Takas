class_name GameManager
extends RefCounted

## Controller della run roguelike: Ante, match corrente, Football Coins e fase
## del metagioco (GDD §3, §6, §7 e §8).
##
## Classe istanziabile come MatchController: va creata una volta per run e
## conserva tutto lo stato mutabile del metagioco. Resta logica pura, senza
## riferimenti a nodi, scene o UI: l'interfaccia legge lo stato e i Dictionary
## restituiti dai metodi. Le formule del Calcio Mercato vivono in ShopManager,
## quelle dell'azione in ActionResolver.
## [codeblock]
## var run := GameManager.new()
## run.start_new_run(TeamGenerator.generate_starter_team())
## var partita := run.start_match()
## run.record_match_result(true, 1, 0, partita.passes_left, partita.shots_left)
## run.advance_to_next_match()
## [/codeblock]

## Fasi del metagioco, dal menu iniziale alla fine della run.
enum RunState {
	MENU,
	RUN_ACTIVE,
	SHOP_PHASE,
	MATCH_ACTIVE,
	CUP_VICTORY,
	GAME_OVER,
}

## Nomi leggibili delle fasi, allineati all'ordine di RunState.
const STATE_NAMES := [
	"MENU", "RUN_ACTIVE", "SHOP_PHASE", "MATCH_ACTIVE", "CUP_VICTORY", "GAME_OVER",
]

## GDD §3: il mondiale conta 6 Ante da 3 match (2 preliminari + 1 Boss Match),
## per un totale di 18 partite.
const FIRST_CUP: int = 1
const LAST_CUP: int = 6
const MATCHES_PER_CUP: int = 3
const BOSS_MATCH_INDEX: int = 3
const TOTAL_MATCHES: int = 18

## Football Coins con cui parte una run.
const DEFAULT_BUDGET: int = 50

## GDD §7: punti parata del portiere avversario, per Ante e per match.
const SAVE_POINTS_TABLE := {
	1: [120.0, 180.0, 280.0],
	2: [350.0, 500.0, 750.0],
	3: [1000.0, 1400.0, 2100.0],
	4: [3000.0, 4200.0, 6500.0],
	5: [9000.0, 13000.0, 20000.0],
	6: [28000.0, 40000.0, 60000.0],
}

## GDD §4.1: sagome difensive passive schierate in campo, per Ante.
const OBSTACLES_BY_CUP := {
	1: 0,
	2: 1,
	3: 1,
	4: 2,
	5: 2,
	6: 3,
}

## GDD §4.1: le sagome restano vincolate alla propria fascia di reparto. Le
## coordinate sono lette dal punto di vista avversario sulla griglia pitch
## 1000x600 (GDD §9): la prima presidia la difesa davanti alla porta, la
## seconda il centrocampo, la terza il reparto avanzato.
const OBSTACLE_POSITIONS := [
	Vector2(750, 300),
	Vector2(550, 300),
	Vector2(350, 300),
]

## Ruolo del cartellino avversario usato come sagoma, fascia per fascia.
const OBSTACLE_ROLES := ["DIF", "CEN", "ATT"]

## GDD §3: ricompense in Football Coins di fine partita.
const REWARD_MATCH_WIN: int = 4
const REWARD_BOSS_BONUS: int = 5
const REWARD_PER_UNUSED_PASS: int = 1
const REWARD_PER_UNUSED_SHOT: int = 2

## GDD §10.1: talismani che alterano le ricompense di fine partita.
const TALISMAN_BOSS_REWARD := "coppa_grandi_orecchie"
const TALISMAN_SHOT_REWARD := "terzo_tempo"
const TALISMAN_SHOT_REWARD_BONUS: int = 1

## Rosa avversaria generata proceduralmente per i due match preliminari.
const OPPONENT_TEAM_NAME := "Avversaria"
const OPPONENT_FORMATION := "4-4-2"

## Ante in corso, da FIRST_CUP a LAST_CUP (GDD §3).
var current_cup: int = FIRST_CUP

## Match in corso dentro l'Ante, da 1 a MATCHES_PER_CUP.
var current_match_index: int = 1

## Rosa controllata dal giocatore per tutta la run.
var player_team: TeamData = null

## Football Coins disponibili al Calcio Mercato (GDD §3 e §6).
var budget: int = DEFAULT_BUDGET

## Fase corrente del metagioco.
var run_state: RunState = RunState.MENU

## Boss del match in corso, null nei due match preliminari (GDD §8).
var current_boss: BossData = null

## Controller dell'ultima partita avviata, null prima del primo match.
var match_controller: MatchController = null

## Vetrina del Calcio Mercato esposta ora, con le chiavi restituite da
## ShopManager.generate_offer().
var current_shop_offer: Dictionary = {}

## Reroll già pagati nella visita corrente al mercato (GDD §6.1).
var shop_rerolls: int = 0

## Statistiche cumulate della run.
var matches_played: int = 0
var matches_won: int = 0
var total_goals_scored: int = 0
var total_goals_conceded: int = 0

## Dettaglio dell'ultima ricompensa calcolata da record_match_result().
var last_match_reward: Dictionary = {}

var _rng := RandomNumberGenerator.new()
var _seeded: bool = false


## Fissa il seme del sorteggio boss per rendere ripetibili i test.
func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value
	_seeded = true


## Avvia una nuova run con la rosa indicata e i Football Coins iniziali,
## riportando Ante e match al primo incontro del mondiale (GDD §3).
## False se la rosa manca o non ha un undici titolare valido.
func start_new_run(starting_team: TeamData, starting_budget: int = DEFAULT_BUDGET) -> bool:
	if starting_team == null:
		push_error("GameManager: impossibile avviare una run senza rosa")
		return false
	if not starting_team.is_lineup_valid():
		push_error("GameManager: undici titolare non valido, run non avviata")
		return false

	player_team = starting_team
	budget = maxi(0, starting_budget)
	current_cup = FIRST_CUP
	current_match_index = 1
	matches_played = 0
	matches_won = 0
	total_goals_scored = 0
	total_goals_conceded = 0
	match_controller = null
	last_match_reward = {}
	current_shop_offer = {}
	shop_rerolls = 0
	run_state = RunState.RUN_ACTIVE
	_resolve_boss()
	return true


## Registra l'esito della partita appena conclusa e accredita la ricompensa in
## Football Coins (GDD §3).
##
## Il premio vale 4 FC per una vittoria e 9 FC nel Boss Match (4 + 5 di bonus
## completamento), raddoppiati dalla Coppa dalle Grandi Orecchie (GDD §10.1). Si
## sommano le monete residue: +1 FC per passaggio non speso e +2 FC per tiro non
## speso, +1 ulteriore per tiro con il Terzo Tempo. Una sconfitta chiude la run,
## una vittoria nel Boss Match apre il Calcio Mercato oppure assegna il mondiale
## se era l'ultima Ante.
## Chiavi restituite: recorded, reason, won, reward, base_reward,
## residual_reward, budget, state.
func record_match_result(player_won: bool, goals_scored: int = 0, goals_conceded: int = 0, passes_left: int = 0, shots_left: int = 0) -> Dictionary:
	if run_state != RunState.RUN_ACTIVE and run_state != RunState.MATCH_ACTIVE:
		return {
			"recorded": false,
			"reason": "nessuna partita in corso: fase %s" % get_state_name(),
			"won": player_won,
			"reward": 0,
			"base_reward": 0,
			"residual_reward": 0,
			"budget": budget,
			"state": run_state,
		}

	var boss_match := is_boss_match()
	matches_played += 1
	total_goals_scored += maxi(0, goals_scored)
	total_goals_conceded += maxi(0, goals_conceded)

	var base_reward := 0
	var residual_reward := 0
	if player_won:
		matches_won += 1
		base_reward = REWARD_MATCH_WIN
		if boss_match:
			base_reward += REWARD_BOSS_BONUS
			if _has_talisman(TALISMAN_BOSS_REWARD):
				base_reward *= 2
		var per_shot := REWARD_PER_UNUSED_SHOT
		if _has_talisman(TALISMAN_SHOT_REWARD):
			per_shot += TALISMAN_SHOT_REWARD_BONUS
		residual_reward = maxi(0, passes_left) * REWARD_PER_UNUSED_PASS
		residual_reward += maxi(0, shots_left) * per_shot
		budget += base_reward + residual_reward
		if boss_match and current_cup >= LAST_CUP:
			run_state = RunState.CUP_VICTORY
		elif boss_match:
			open_shop()
		else:
			run_state = RunState.RUN_ACTIVE
	else:
		run_state = RunState.GAME_OVER

	last_match_reward = {
		"recorded": true,
		"reason": "",
		"won": player_won,
		"reward": base_reward + residual_reward,
		"base_reward": base_reward,
		"residual_reward": residual_reward,
		"budget": budget,
		"state": run_state,
	}
	return last_match_reward


## Passa al match successivo del mondiale, cambiando Ante quando i 3 incontri
## sono esauriti e sorteggiando il boss se il prossimo è un Boss Match (GDD §3).
## Chiude la visita al mercato e scarta il controller della partita precedente.
## False se la run è finita o se il mondiale è stato completato.
func advance_to_next_match() -> bool:
	if run_state == RunState.MENU:
		push_warning("GameManager: nessuna run avviata")
		return false
	if run_state == RunState.GAME_OVER:
		push_warning("GameManager: run terminata, nessun match successivo")
		return false
	if run_state == RunState.CUP_VICTORY:
		push_warning("GameManager: mondiale già completato")
		return false

	current_shop_offer = {}
	shop_rerolls = 0
	match_controller = null
	current_match_index += 1
	if current_match_index > MATCHES_PER_CUP:
		current_match_index = 1
		current_cup += 1
	if current_cup > LAST_CUP:
		current_cup = LAST_CUP
		current_match_index = MATCHES_PER_CUP
		run_state = RunState.CUP_VICTORY
		return false

	run_state = RunState.RUN_ACTIVE
	_resolve_boss()
	return true


## Prepara la partita in corso e restituisce il MatchController già configurato
## con avversario, punti parata dell'Ante, malus del boss e sagome difensive
## (GDD §4.1, §7 e §8). Null se non c'è una run pronta a giocare.
func start_match() -> MatchController:
	if run_state != RunState.RUN_ACTIVE:
		push_warning("GameManager: fase %s, impossibile avviare il match" % get_state_name())
		return null
	if player_team == null:
		push_warning("GameManager: nessuna rosa, impossibile avviare il match")
		return null

	var opponent := build_opponent_team()
	var controller := MatchController.new()
	if not controller.start_match(player_team, opponent, get_save_points()):
		return null
	if current_boss != null:
		controller.passes_left = current_boss.apply_to_passes(controller.passes_left)
	_place_obstacles(controller, opponent)
	match_controller = controller
	run_state = RunState.MATCH_ACTIVE
	return controller


## Apre il Calcio Mercato tra due Ante: azzera i reroll pagati, genera la
## vetrina e passa in RunState.SHOP_PHASE (GDD §6).
func open_shop() -> Dictionary:
	run_state = RunState.SHOP_PHASE
	shop_rerolls = 0
	return generate_shop_offer()


## Chiude il mercato e torna in RunState.RUN_ACTIVE senza cambiare match.
func close_shop() -> void:
	if run_state != RunState.SHOP_PHASE:
		return
	current_shop_offer = {}
	shop_rerolls = 0
	run_state = RunState.RUN_ACTIVE


## Genera una nuova vetrina: 3 cartellini, 2 talismani e 1 allenamento (GDD §6).
func generate_shop_offer() -> Dictionary:
	current_shop_offer = ShopManager.generate_offer()
	return current_shop_offer


## Football Coins richiesti dal prossimo reroll di questa visita (GDD §6.1).
func get_reroll_cost() -> int:
	return ShopManager.get_reroll_cost(shop_rerolls)


## Paga il reroll e rimescola la vetrina: il costo parte da 2 FC e cresce di 1
## per ogni reroll consecutivo della stessa visita (GDD §6.1).
func reroll_shop_offer() -> Dictionary:
	var cost := get_reroll_cost()
	if cost > budget:
		return {"success": false, "reason": "budget insufficiente: servono %d FC" % cost, "budget": budget, "cost": cost}
	budget -= cost
	shop_rerolls += 1
	generate_shop_offer()
	return {"success": true, "reason": "", "budget": budget, "cost": cost, "offer": current_shop_offer}


## Acquista un cartellino dalla vetrina: controlla i Football Coins e i 3 posti
## in panchina, scala il prezzo e lo aggiunge alla rosa (GDD §6.1 e §10).
func buy_player(player: PlayerData) -> Dictionary:
	var result := ShopManager.buy_player(player_team, budget, player)
	_apply_shop_result(result, "players", player)
	return result


## Vende un panchinaro e accredita il valore da GDD §10.
func sell_player(player: PlayerData) -> Dictionary:
	var result := ShopManager.sell_player(player_team, budget, player)
	_apply_shop_result(result, "", player)
	return result


## Acquista un talismano e lo equipaggia, fino al massimo di 5 (GDD §10).
func buy_talisman(talisman: TalismanData) -> Dictionary:
	var result := ShopManager.buy_talisman(player_team, budget, talisman)
	_apply_shop_result(result, "talismans", talisman)
	return result


## Acquista un allenamento e lo applica al cartellino indicato (GDD §10.3).
func buy_training(training: TrainingData, target_player: PlayerData, new_role: String = "") -> Dictionary:
	var result := ShopManager.buy_training(player_team, budget, training, target_player, new_role)
	_apply_shop_result(result, "trainings", training)
	return result


## True se il match in corso è il Boss Match dell'Ante (GDD §3).
func is_boss_match() -> bool:
	return current_match_index == BOSS_MATCH_INDEX


## True se la run è chiusa, per sconfitta o per mondiale vinto.
func is_run_over() -> bool:
	return run_state == RunState.GAME_OVER or run_state == RunState.CUP_VICTORY


## Nome leggibile della fase corrente, utile nei log.
func get_state_name() -> String:
	var index := int(run_state)
	if index < 0 or index >= STATE_NAMES.size():
		return "UNKNOWN"
	return STATE_NAMES[index]


## Punti parata da tabella per l'Ante e il match indicati, senza modificatori
## del boss (GDD §7). Con argomenti a 0 usa il match in corso.
func get_base_save_points(cup: int = 0, match_index: int = 0) -> float:
	var ante := cup
	if ante < FIRST_CUP:
		ante = current_cup
	ante = clampi(ante, FIRST_CUP, LAST_CUP)
	var index := match_index
	if index < 1:
		index = current_match_index
	index = clampi(index, 1, MATCHES_PER_CUP)
	var row: Array = SAVE_POINTS_TABLE[ante]
	return float(row[index - 1])


## Punti parata effettivi del match in corso, con il moltiplicatore del boss
## già applicato (GDD §7 e §8, es. Portiere Saracinesca +50%).
func get_save_points() -> float:
	var points := get_base_save_points()
	if current_boss != null:
		points = current_boss.apply_to_save_points(points)
	return points


## Sagome difensive passive presenti nell'Ante indicata (GDD §4.1).
func get_obstacle_count(cup: int = 0) -> int:
	var ante := cup
	if ante < FIRST_CUP:
		ante = current_cup
	ante = clampi(ante, FIRST_CUP, LAST_CUP)
	return int(OBSTACLES_BY_CUP[ante])


## Partite completate sul totale delle 18 del mondiale (GDD §3).
func get_matches_completed() -> int:
	return (current_cup - FIRST_CUP) * MATCHES_PER_CUP + current_match_index - 1


## Costruisce la rosa avversaria del match in corso: quella del boss se ne
## dichiara una, altrimenti una squadra generata sulla sua formazione (GDD §8).
func build_opponent_team() -> TeamData:
	if current_boss != null:
		if current_boss.base_team != null:
			return current_boss.base_team
		return TeamGenerator.generate_starter_team(current_boss.formation, current_boss.boss_name, false)
	return TeamGenerator.generate_starter_team(GameCatalog.get_formation(OPPONENT_FORMATION), OPPONENT_TEAM_NAME, false)


## Fotografia leggibile dello stato della run, per log e debug.
func get_state_snapshot() -> Dictionary:
	var boss_name := ""
	if current_boss != null:
		boss_name = current_boss.boss_name
	return {
		"state": get_state_name(),
		"cup": current_cup,
		"match": current_match_index,
		"boss": boss_name,
		"budget": budget,
		"save_points": get_save_points(),
		"obstacles": get_obstacle_count(),
		"matches_played": matches_played,
		"matches_won": matches_won,
		"goals_scored": total_goals_scored,
		"goals_conceded": total_goals_conceded,
	}


## Sorteggia il boss dell'Ante quando il match in corso è il terzo, altrimenti
## azzera il riferimento (GDD §3 e §8).
func _resolve_boss() -> void:
	current_boss = null
	if not is_boss_match():
		return
	var pool := GameCatalog.get_bosses_by_cup(current_cup)
	if pool.is_empty():
		push_warning("GameManager: nessun boss registrato per l'Ante %d" % current_cup)
		return
	_ensure_seeded()
	current_boss = pool[_rng.randi_range(0, pool.size() - 1)]


## Schiera le sagome difensive dell'Ante sul controller, una per fascia di
## reparto (GDD §4.1).
func _place_obstacles(controller: MatchController, opponent: TeamData) -> void:
	var count := mini(get_obstacle_count(), OBSTACLE_POSITIONS.size())
	if count <= 0 or opponent == null:
		return
	var defenders: Array[Dictionary] = []
	var used: Array[PlayerData] = []
	for index in count:
		var role: String = OBSTACLE_ROLES[index]
		var shape := _pick_obstacle_player(opponent, role, used)
		if shape == null:
			continue
		used.append(shape)
		var field_pos: Vector2 = OBSTACLE_POSITIONS[index]
		defenders.append(ActionResolver.make_defender(shape, field_pos))
	controller.set_obstacles(defenders)


## Titolare avversario da usare come sagoma per la fascia indicata: preferisce
## il ruolo giusto, ripiega su un altro di movimento e mai sul portiere.
func _pick_obstacle_player(opponent: TeamData, role: String, used: Array[PlayerData]) -> PlayerData:
	var fallback: PlayerData = null
	for slot in range(TeamData.LINEUP_SIZE, 0, -1):
		var starter := opponent.get_starter(slot)
		if starter == null or used.has(starter):
			continue
		if starter.role == role:
			return starter
		if fallback == null and starter.role != "POR":
			fallback = starter
	return fallback


## True se la rosa del giocatore ha equipaggiato il talismano indicato.
func _has_talisman(id: String) -> bool:
	if player_team == null:
		return false
	return player_team.find_talisman(id) != null


## Applica al budget l'esito di un'operazione di mercato e, se è andata a buon
## fine, ritira l'articolo dalla vetrina.
func _apply_shop_result(result: Dictionary, offer_key: String, item: Resource) -> void:
	if not bool(result.get("success", false)):
		return
	budget = int(result.get("budget", budget))
	if offer_key == "" or not current_shop_offer.has(offer_key):
		return
	var pool: Array = current_shop_offer[offer_key]
	pool.erase(item)


func _ensure_seeded() -> void:
	if _seeded:
		return
	_rng.randomize()
	_seeded = true
