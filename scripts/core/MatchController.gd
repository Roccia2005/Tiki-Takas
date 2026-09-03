class_name MatchController
extends RefCounted

## Stato e loop di una singola partita: azioni, passaggi, tiri e punti parata
## (GDD §4 "Regole del Match", §4.1 e §7).
##
## Va istanziato una volta per partita e posseduto da GameManager: conserva lo
## stato mutabile del match, mentre tutta la matematica resta in ActionResolver.
## Nessun riferimento a nodi, scene o UI: l'interfaccia leggerà lo stato e i
## Dictionary restituiti dai metodi.
## [codeblock]
## var match_ctrl := MatchController.new()
## match_ctrl.start_match(TeamGenerator.generate_starter_team(), avversaria, 120.0)
## match_ctrl.execute_pass(match_ctrl.player_team.get_starter(7))
## var esito := match_ctrl.execute_shot()
## print(esito["is_goal"])
## [/codeblock]

## Fasi del match. AI_TURN resta riservata: nel GDD §4 l'avversario non gioca
## la palla, si difende con il portiere e con le sagome passive del §4.1.
enum MatchPhase {
	SETUP,
	PLAYER_TURN,
	AI_TURN,
	ACTION_RESOLVING,
	GOAL,
	TURNOVER,
	MATCH_OVER,
}

## Esito complessivo della partita (GDD §4).
enum MatchResult {
	PENDING,
	WIN,
	LOSS,
}

## Come si riforniscono i contatori di passaggi e tiri.
## [br]- MATCH: risorse dell'intera partita, come da GDD §2.3 e §3 (default).
## [br]- ACTION: contatori ripristinati a ogni nuova azione; comoda per i test,
## ma azzera la condizione di sconfitta "tiri esauriti" del GDD §4.
enum ResourceMode {
	MATCH,
	ACTION,
}

## Nomi leggibili delle fasi, allineati all'ordine di MatchPhase.
const PHASE_NAMES := [
	"SETUP", "PLAYER_TURN", "AI_TURN", "ACTION_RESOLVING", "GOAL", "TURNOVER", "MATCH_OVER",
]

## Passaggi e tiri concessi per azione in ResourceMode.ACTION.
const DEFAULT_PASSES_PER_ACTION: int = 3
const DEFAULT_SHOTS_PER_ACTION: int = 1

## Punti parata di partenza se il chiamante non li indica: GDD §7, Ante 1 Match 1.
const DEFAULT_SAVE_POINTS: float = 120.0

## GDD §4: la prima azione parte sempre dai piedi del portiere, cioè lo slot 1.
const STARTER_SLOT: int = 1

## GDD §2.3: passaggi (x) e tiri (y) concessi per partita da ogni squadra.
const TEAM_RESOURCES := {
	"Standard": Vector2i(6, 4),
	"Italiana": Vector2i(4, 5),
	"Spagnola": Vector2i(10, 3),
	"Portoghese": Vector2i(5, 4),
	"Brasiliana": Vector2i(7, 4),
	"Inglese": Vector2i(4, 5),
}

## Risorse usate per le squadre fuori catalogo: quelle della Standard.
const FALLBACK_RESOURCES := Vector2i(6, 4)

## GDD §10.2: il passaggio del Baller non consuma il contatore dei passaggi.
const BALLER_ARCHETYPE_ID := "baller"

## Fasce di respinta post-tiro parato: 45% ATT, 40% CEN, 15% DIF (GDD §4).
const REBOUND_WEIGHTS := {"ATT": 45.0, "CEN": 40.0, "DIF": 15.0}

## Fasce di respinta post-tiro con il Rinvio Telecomandato equipaggiato,
## 60% ATT, 30% CEN, 10% DIF (GDD §10.1).
const REBOUND_WEIGHTS_REMOTE := {"ATT": 60.0, "CEN": 30.0, "DIF": 10.0}

## Fasce di respinta difensiva su palla persa: 60% DIF, 30% CEN, 10% ATT (GDD §4.1).
const TURNOVER_WEIGHTS := {"DIF": 60.0, "CEN": 30.0, "ATT": 10.0}

## Scala del peso di prossimità: dentro la fascia estratta il recupero premia
## chi si trova più vicino al punto in cui la palla è tornata giocabile.
const RECOVERY_DISTANCE_SCALE: float = 1000.0

## Archetipo che raddoppia le probabilità di raccogliere la palla vagante (GDD §10.2).
const CALAMITA_ARCHETYPE_ID := "calamita"

## Talismano che ribalta le fasce della respinta post-tiro (GDD §10.1).
const TALISMAN_REMOTE_CLEARANCE := "rinvio_telecomandato"

## Origine della prossima azione: decide chi riceve la palla in
## [method start_action]. Solo KICKOFF e GOAL_KICK la consegnano al portiere,
## come vuole il GDD §4; REBOUND e TURNOVER passano dalle fasce di respinta.
enum Restart {
	KICKOFF,
	GOAL_KICK,
	REBOUND,
	TURNOVER,
}

## Rosa controllata dal giocatore.
var player_team: TeamData = null

## Rosa avversaria: serve solo a ricavare il portiere da battere (GDD §4).
## Può restare null, in quel caso valgono i soli punti parata.
var ai_team: TeamData = null

## Sagome difensive passive in campo (GDD §4.1), da costruire con
## [method ActionResolver.make_defender] oppure con [method add_obstacle].
var obstacles: Array[Dictionary] = []

## Passaggi ancora disponibili (GDD §4).
var passes_left: int = 0

## Tiri ancora disponibili (GDD §4).
var shots_left: int = 0

## Gol realizzati dal giocatore. Nel GDD §4 l'avversario non segna mai:
## score_ai resta a 0 ed esiste per completezza dell'interfaccia.
var score_player: int = 0
var score_ai: int = 0

## Giocatore che ha la palla in questo momento, null tra due azioni.
var current_ball_carrier: PlayerData = null

## Posizione della palla sulla griglia pitch 1000x600 (GDD §9).
var ball_position: Vector2 = Vector2.ZERO

## Potenza Azione cumulata dai passaggi dell'azione corrente (GDD §4).
var accumulated_action_power: float = 0.0

## Fase corrente del match.
var match_phase: MatchPhase = MatchPhase.SETUP

## Esito del match, PENDING fino alla vittoria o alla sconfitta.
var match_result: MatchResult = MatchResult.PENDING

## Punti parata residui del portiere avversario: l'obiettivo da azzerare (GDD §7).
var save_points: float = 0.0

## Punti parata iniziali del match, utili per le percentuali a schermo.
var save_points_max: float = 0.0

## Posizione del portiere avversario, sulla linea di porta (GDD §4).
var goalkeeper_position: Vector2 = Vector2.ZERO

## Azioni avviate nel match, passaggi e tiri già consumati.
var action_index: int = 0
var passes_used: int = 0
var shots_used: int = 0

## Ultimo esito restituito da [method execute_pass] o [method execute_shot].
var last_result: Dictionary = {}

## Modalità di rifornimento dei contatori, da impostare prima di start_match().
var resource_mode: MatchController.ResourceMode = MatchController.ResourceMode.MATCH

## Budget per azione usato quando resource_mode è ResourceMode.ACTION.
var passes_per_action: int = DEFAULT_PASSES_PER_ACTION
var shots_per_action: int = DEFAULT_SHOTS_PER_ACTION

## Motivo della prossima ripartenza, da Restart: il portiere batte solo a inizio
## partita o su rimessa dal fondo dopo un gol subito (GDD §4).
var pending_restart: int = Restart.KICKOFF

## Punto in cui la palla è tornata giocabile: parata del portiere, intercetto
## della sagoma o punto della palla persa (GDD §4 e §4.1).
var recovery_point: Vector2 = Vector2.ZERO

## Sagoma avversaria che ha intercettato l'ultimo passaggio, null se è riuscito.
var last_interceptor: PlayerData = null

## Compagno che ha raccolto la palla all'ultima ripartenza (GDD §4 e §4.1).
var last_recovered_by: PlayerData = null

## Generatore delle estrazioni di respinta post-tiro e palla persa (GDD §4, §4.1).
var _rng := RandomNumberGenerator.new()
var _seeded: bool = false

## Fissa il seme delle estrazioni di respinta, per partite ripetibili nei test.
func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value
	_seeded = true


## Prepara la partita: azzera punteggio e contatori, carica le risorse della
## squadra dal GDD §2.3, fissa i punti parata del portiere avversario (GDD §7)
## e avvia la prima azione dai piedi del portiere.
## Restituisce false se la rosa manca o non ha un undici titolare valido.
func start_match(player: TeamData, opponent: TeamData = null, gk_save_points: float = DEFAULT_SAVE_POINTS) -> bool:
	if player == null:
		push_error("MatchController: impossibile avviare un match senza rosa")
		return false
	if not player.is_lineup_valid():
		push_error("MatchController: l'undici titolare non è schierato correttamente")
		return false

	player_team = player
	ai_team = opponent
	score_player = 0
	score_ai = 0
	save_points_max = maxf(0.0, gk_save_points)
	save_points = save_points_max
	goalkeeper_position = ActionResolver.get_goal_position()
	match_result = MatchResult.PENDING
	action_index = 0
	passes_used = 0
	shots_used = 0
	last_result = {}
	accumulated_action_power = 0.0
	pending_restart = Restart.KICKOFF
	recovery_point = Vector2.ZERO
	last_interceptor = null
	last_recovered_by = null
	match_phase = MatchPhase.SETUP
	_refill_counters()
	start_action()
	return true


## Avvia una nuova azione: azzera i tocchi di tutta la rosa e la Potenza Azione,
## poi consegna la palla a [param carrier] se è schierato, altrimenti al portiere
## come previsto dal GDD §4. Il parametro accoglierà il destinatario estratto
## dalla respinta post-tiro o dalla palla persa (GDD §4 e §4.1).
## In ResourceMode.ACTION i contatori vengono ripristinati qui.
func start_action(carrier: PlayerData = null) -> bool:
	if player_team == null:
		push_warning("MatchController: nessuna partita avviata")
		return false
	if match_result != MatchResult.PENDING:
		push_warning("MatchController: match concluso, nessuna nuova azione")
		return false

	action_index += 1
	player_team.reset_all_touches()
	accumulated_action_power = 0.0
	if resource_mode == ResourceMode.ACTION:
		_refill_counters()
	current_ball_carrier = _resolve_carrier(carrier)
	if current_ball_carrier == null:
		push_warning("MatchController: nessun titolare disponibile per battere")
		return false
	ball_position = get_player_position(current_ball_carrier)
	last_recovered_by = current_ball_carrier
	last_interceptor = null
	match_phase = MatchPhase.PLAYER_TURN
	return true


## Esegue il passaggio dal portatore di palla a [param target_player] (GDD §4).
##
## Il tocco viene registrato dopo il calcolo, così il primo tocco dell'azione
## versa il 100% della Forza (GDD §4, rendimento decrescente). Il contatore dei
## passaggi cala anche quando la sfera viene intercettata, perché il GDD §4.1
## stabilisce che i passaggi consumati non vengono restituiti; il Baller non lo
## consuma affatto (GDD §10.2).
## Il dizionario restituito contiene [code]executed[/code], [code]reason[/code],
## [code]success[/code], [code]intercepted_by[/code], [code]turnover[/code],
## [code]effective_power[/code], [code]action_power[/code], [code]passes_left[/code],
## [code]consumed_pass[/code], [code]phase[/code] e [code]resolver[/code],
## l'esito integrale di [method ActionResolver.resolve_pass].
func execute_pass(target_player: PlayerData) -> Dictionary:
	if player_team == null:
		return _rejected("partita non avviata")
	if match_phase != MatchPhase.PLAYER_TURN:
		return _rejected("fase non valida per un passaggio: %s" % get_phase_name())
	if current_ball_carrier == null:
		return _rejected("nessun portatore di palla")
	if target_player == null:
		return _rejected("destinatario nullo")
	if target_player == current_ball_carrier:
		return _rejected("il portatore non può passare a se stesso")
	if player_team.find_slot(target_player) < 1:
		return _rejected("destinatario non schierato in campo")
	var passer := current_ball_carrier
	var consumes := _consumes_pass(passer)
	if consumes and passes_left <= 0:
		return _rejected("passaggi esauriti")

	match_phase = MatchPhase.ACTION_RESOLVING
	var target_pos := get_player_position(target_player)
	var resolver := ActionResolver.resolve_pass(passer, ball_position, target_pos, obstacles, accumulated_action_power)
	var contribution := passer.register_touch()
	if consumes:
		passes_left = maxi(0, passes_left - 1)
	passes_used += 1

	var success: bool = resolver["success"]
	if success:
		accumulated_action_power = resolver["action_power"]
		current_ball_carrier = target_player
		ball_position = target_pos
	else:
		_apply_interception(resolver["intercepted_by"] as PlayerData, target_pos)

	var turnover: bool = resolver["turnover"]
	if turnover:
		_apply_turnover()
	else:
		match_phase = MatchPhase.PLAYER_TURN
	last_result = {
		"executed": true,
		"reason": "",
		"success": success,
		"intercepted_by": resolver["intercepted_by"],
		"turnover": turnover,
		"effective_power": resolver["effective_power"],
		"touch_contribution": contribution,
		"action_power": accumulated_action_power,
		"passes_left": passes_left,
		"consumed_pass": consumes,
		"carrier": current_ball_carrier,
		"interceptor": last_interceptor,
		"recovery_point": recovery_point,
		"phase": match_phase,
		"resolver": resolver,
	}
	return last_result


## Calcia in porta con il portatore di palla (GDD §4 e §7).
##
## La Potenza Azione accumulata dai passaggi viene sommata al contributo del
## tiratore (GDD §5: la Forza è il valore aggiunto al passaggio o al tiro) e
## ridotta di 15 punti per ogni sagoma dentro il cono di tiro (GDD §4.1);
## ActionResolver applica poi il decadimento da distanza del GDD §7.
## Il danno risultante viene sottratto ai punti parata del portiere: quando
## scendono a 0 è gol e la partita è vinta, altrimenti è parata e l'azione va
## ricominciata. I tocchi dell'intera rosa vengono sempre azzerati (GDD §4).
## Il dizionario restituito contiene [code]executed[/code], [code]reason[/code],
## [code]is_goal[/code], [code]damage[/code], [code]blocked[/code],
## [code]action_power[/code], [code]shooter_power[/code], [code]obstacle_malus[/code],
## [code]save_points_left[/code], [code]shots_left[/code], [code]phase[/code],
## [code]match_result[/code] e [code]resolver[/code].
func execute_shot() -> Dictionary:
	if player_team == null:
		return _rejected("partita non avviata")
	if match_phase != MatchPhase.PLAYER_TURN:
		return _rejected("fase non valida per un tiro: %s" % get_phase_name())
	if current_ball_carrier == null:
		return _rejected("nessun tiratore in possesso di palla")
	if shots_left <= 0:
		return _rejected("tiri esauriti")

	match_phase = MatchPhase.ACTION_RESOLVING
	var shooter := current_ball_carrier
	var goal_pos := ActionResolver.get_goal_position()
	var in_cone := ActionResolver.filter_defenders_in_cone(obstacles, ball_position, goal_pos)
	var obstacle_malus := ActionResolver.OBSTACLE_POWER_MALUS * float(in_cone.size())
	var shooter_power := shooter.get_effective_power()
	var action_total := maxf(0.0, accumulated_action_power + shooter_power - obstacle_malus)
	var resolver := ActionResolver.resolve_shot(shooter, ball_position, get_opponent_goalkeeper(), goalkeeper_position, [], action_total)
	var contribution := shooter.register_touch()
	shots_left = maxi(0, shots_left - 1)
	shots_used += 1

	# Sagome che assorbono tutta la Potenza Azione: tiro murato, danno nullo.
	var blocked := is_zero_approx(action_total)
	var damage := 0.0
	if not blocked:
		damage = float(resolver["shot_value"])
	save_points = maxf(0.0, save_points - damage)
	var scored := save_points <= 0.0

	player_team.reset_all_touches()
	accumulated_action_power = 0.0
	current_ball_carrier = null
	last_interceptor = null
	recovery_point = goalkeeper_position
	ball_position = goalkeeper_position
	if scored:
		score_player += 1
		match_phase = MatchPhase.GOAL
		pending_restart = Restart.GOAL_KICK
	else:
		match_phase = MatchPhase.TURNOVER
		pending_restart = Restart.REBOUND
	_check_match_end()
	last_result = {
		"executed": true,
		"reason": "",
		"is_goal": scored,
		"damage": damage,
		"blocked": blocked,
		"action_power": action_total,
		"shooter_power": shooter_power,
		"touch_contribution": contribution,
		"obstacle_malus": obstacle_malus,
		"save_points_left": save_points,
		"shots_left": shots_left,
		"phase": match_phase,
		"match_result": match_result,
		"restart": pending_restart,
		"recovery_point": recovery_point,
		"resolver": resolver,
	}
	return last_result


## True se il portatore può ancora passare: serve la fase giusta e un passaggio
## disponibile, salvo il Baller che non consuma il contatore (GDD §4 e §10.2).
func can_pass() -> bool:
	if match_phase != MatchPhase.PLAYER_TURN or current_ball_carrier == null:
		return false
	return passes_left > 0 or not _consumes_pass(current_ball_carrier)


## True se il portatore può calciare in porta (GDD §4).
func can_shoot() -> bool:
	return match_phase == MatchPhase.PLAYER_TURN and current_ball_carrier != null and shots_left > 0


## Titolari che possono ricevere il pallone: tutti tranne il portatore. Il GDD
## §4.1 consente anche i passaggi oltre la gittata, a costo di potenza.
func get_valid_targets() -> Array[PlayerData]:
	var targets: Array[PlayerData] = []
	if player_team == null:
		return targets
	for slot in range(1, TeamData.LINEUP_SIZE + 1):
		var player := player_team.get_starter(slot)
		if player != null and player != current_ball_carrier:
			targets.append(player)
	return targets


## Coordinate del titolare sul modulo attivo (GDD §9), Vector2.ZERO se il
## giocatore non è schierato o se manca il modulo.
func get_player_position(player: PlayerData) -> Vector2:
	if player_team == null or player_team.current_formation == null or player == null:
		return Vector2.ZERO
	var slot := player_team.find_slot(player)
	if slot < 1:
		return Vector2.ZERO
	return player_team.current_formation.get_slot_position(slot)


## Portiere avversario da battere, null se non è stata passata una rosa nemica.
func get_opponent_goalkeeper() -> PlayerData:
	if ai_team == null:
		return null
	var keeper := ai_team.get_starter(STARTER_SLOT)
	if keeper != null and keeper.role == "POR":
		return keeper
	for player in ai_team.players:
		if player != null and player.role == "POR":
			return player
	return keeper


## Aggiunge una sagoma difensiva passiva in campo (GDD §4.1).
func add_obstacle(player: PlayerData, field_pos: Vector2, intercept_radius: float = ActionResolver.DEFAULT_INTERCEPT_RADIUS) -> void:
	obstacles.append(ActionResolver.make_defender(player, field_pos, intercept_radius))


## Sostituisce tutte le sagome in campo (GDD §4.1).
func set_obstacles(defenders: Array[Dictionary]) -> void:
	obstacles = defenders.duplicate()


## True quando la partita è decisa, in vittoria o in sconfitta.
func is_match_over() -> bool:
	return match_result != MatchResult.PENDING


## Nome leggibile della fase corrente, per log e HUD.
func get_phase_name() -> String:
	var index := int(match_phase)
	if index < 0 or index >= PHASE_NAMES.size():
		return "UNKNOWN"
	var phase_name: String = PHASE_NAMES[index]
	return phase_name


## Fotografia completa dello stato, pensata per HUD, log e salvataggi.
func get_state_snapshot() -> Dictionary:
	return {
		"phase": match_phase,
		"phase_name": get_phase_name(),
		"result": match_result,
		"passes_left": passes_left,
		"shots_left": shots_left,
		"passes_used": passes_used,
		"shots_used": shots_used,
		"score_player": score_player,
		"score_ai": score_ai,
		"save_points": save_points,
		"save_points_max": save_points_max,
		"action_power": accumulated_action_power,
		"action_index": action_index,
		"ball_position": ball_position,
		"carrier": current_ball_carrier,
		"obstacles": obstacles.size(),
		"restart": pending_restart,
		"recovery_point": recovery_point,
		"recovered_by": last_recovered_by,
		"interceptor": last_interceptor,
	}


## Ricarica i contatori: risorse di partita del GDD §2.3 in ResourceMode.MATCH,
## budget per azione in ResourceMode.ACTION.
func _refill_counters() -> void:
	if resource_mode == ResourceMode.ACTION:
		passes_left = maxi(0, passes_per_action)
		shots_left = maxi(0, shots_per_action)
		return
	var resources := _resources_for(player_team.team_name if player_team != null else "")
	passes_left = resources.x
	shots_left = resources.y


## Passaggi e tiri concessi dal GDD §2.3 alla squadra indicata, con ripiego
## sulle risorse della Standard per i nomi fuori catalogo.
func _resources_for(team_name: String) -> Vector2i:
	if not TEAM_RESOURCES.has(team_name):
		return FALLBACK_RESOURCES
	var resources: Vector2i = TEAM_RESOURCES[team_name]
	return resources


## Battitore dell'azione (GDD §4 e §4.1).
##
## [param carrier] esplicito ha sempre la precedenza. Senza indicazioni decide
## [member pending_restart]: il portiere batte solo a inizio partita
## (Restart.KICKOFF) o su rimessa dal fondo dopo un gol (Restart.GOAL_KICK),
## mentre la respinta post-tiro (Restart.REBOUND) e la palla persa
## (Restart.TURNOVER) passano dalle fasce di reparto del GDD e finiscono sempre
## a un giocatore di movimento. Il portiere resta l'ultimo ripiego solo se in
## campo non c'è nessun uomo di movimento.
func _resolve_carrier(carrier: PlayerData) -> PlayerData:
	if carrier != null and player_team.find_slot(carrier) >= 1:
		return carrier
	if pending_restart == Restart.REBOUND or pending_restart == Restart.TURNOVER:
		var recovered := _pick_recovering_player(_restart_weights())
		if recovered != null:
			return recovered
	var keeper := player_team.get_starter(STARTER_SLOT)
	if keeper != null:
		return keeper
	for slot in range(1, TeamData.LINEUP_SIZE + 1):
		var player := player_team.get_starter(slot)
		if player != null:
			return player
	return null


## Fasce di reparto della ripartenza in corso: respinta difensiva sulla palla
## persa (GDD §4.1), respinta offensiva post-tiro (GDD §4) eventualmente
## ribaltata dal Rinvio Telecomandato (GDD §10.1).
func _restart_weights() -> Dictionary:
	if pending_restart == Restart.TURNOVER:
		return TURNOVER_WEIGHTS
	if _has_talisman(TALISMAN_REMOTE_CLEARANCE):
		return REBOUND_WEIGHTS_REMOTE
	return REBOUND_WEIGHTS


## Estrae il reparto con le probabilità del GDD, poi dentro quel reparto sorteggia
## il ricevente pesando la vicinanza a [member recovery_point]; la Calamita
## raddoppia il proprio peso (GDD §10.2). Null se non c'è nessun uomo di movimento.
func _pick_recovering_player(weights: Dictionary) -> PlayerData:
	var role := _pick_role(weights)
	if role.is_empty():
		return null
	var candidates := _outfielders_by_role(role)
	var total := 0.0
	var scores: Array[float] = []
	for player in candidates:
		var distance := recovery_point.distance_to(get_player_position(player))
		var score := RECOVERY_DISTANCE_SCALE / (RECOVERY_DISTANCE_SCALE + distance)
		if _has_archetype(player, CALAMITA_ARCHETYPE_ID):
			score *= 2.0
		scores.append(score)
		total += score
	if candidates.is_empty() or total <= 0.0:
		return null
	_ensure_seeded()
	var draw := _rng.randf() * total
	for index in candidates.size():
		draw -= scores[index]
		if draw <= 0.0:
			return candidates[index]
	return candidates[candidates.size() - 1]


## Reparto sorteggiato fra quelli davvero presenti in campo: i pesi delle fasce
## vuote vengono ridistribuiti sulle altre, così la somma resta il 100%.
func _pick_role(weights: Dictionary) -> String:
	var total := 0.0
	for role in weights:
		if not _outfielders_by_role(role).is_empty():
			total += float(weights[role])
	if total <= 0.0:
		return ""
	_ensure_seeded()
	var draw := _rng.randf() * total
	for role in weights:
		if _outfielders_by_role(role).is_empty():
			continue
		draw -= float(weights[role])
		if draw <= 0.0:
			return role
	return ""


## Titolari di movimento del reparto indicato: lo slot del portiere è escluso,
## perché la palla torna a lui solo su rimessa dal fondo (GDD §4).
func _outfielders_by_role(role: String) -> Array[PlayerData]:
	var found: Array[PlayerData] = []
	if player_team == null:
		return found
	for slot in range(1, TeamData.LINEUP_SIZE + 1):
		if slot == STARTER_SLOT:
			continue
		var player := player_team.get_starter(slot)
		if player != null and player.role == role:
			found.append(player)
	return found


## True se il giocatore ha l'archetipo indicato equipaggiato (GDD §10.2).
func _has_archetype(player: PlayerData, archetype_id: String) -> bool:
	if player == null:
		return false
	for archetype in player.archetypes:
		var data := archetype as ArchetypeData
		if data != null and data.id == archetype_id:
			return true
	return false


## True se la squadra ha il talismano indicato equipaggiato (GDD §10.1).
func _has_talisman(talisman_id: String) -> bool:
	if player_team == null:
		return false
	return player_team.find_talisman(talisman_id) != null


## Passaggio intercettato (GDD §4.1): la sfera resta alla sagoma avversaria che
## l'ha rubata, il possesso del giocatore cade e la ripartenza seguirà le fasce
## della respinta difensiva.
func _apply_interception(interceptor: PlayerData, fallback_pos: Vector2) -> void:
	last_interceptor = interceptor
	var stolen_at := fallback_pos
	for entry in obstacles:
		if entry.get("player") == interceptor:
			stolen_at = entry.get("position", fallback_pos)
			break
	ball_position = stolen_at
	recovery_point = stolen_at
	current_ball_carrier = null
	pending_restart = Restart.TURNOVER

## False se il passatore ha il Baller equipaggiato: il suo passaggio non scala
## il contatore dei passaggi disponibili (GDD §10.2).
func _consumes_pass(passer: PlayerData) -> bool:
	if passer == null:
		return true
	for archetype in passer.archetypes:
		var data := archetype as ArchetypeData
		if data != null and data.id == BALLER_ARCHETYPE_ID:
			return false
	return true


## Palla persa (GDD §4.1): l'azione muore, i tocchi si azzerano e la Potenza
## Azione torna a zero. La ripartenza è marcata Restart.TURNOVER, così la
## prossima [method start_action] estrae il ricevente dalla respinta difensiva
## 60% DIF - 30% CEN - 10% ATT e non dal portiere.
func _apply_turnover() -> void:
	accumulated_action_power = 0.0
	current_ball_carrier = null
	if player_team != null:
		player_team.reset_all_touches()
	recovery_point = ball_position
	pending_restart = Restart.TURNOVER
	match_phase = MatchPhase.TURNOVER
	_check_match_end()


## Vittoria quando i punti parata sono azzerati, sconfitta quando i tiri sono
## esauriti con il portiere ancora in piedi (GDD §4). In ResourceMode.ACTION la
## sconfitta per tiri finiti non scatta, perché i contatori si ricaricano.
func _check_match_end() -> bool:
	if match_result != MatchResult.PENDING:
		return true
	if save_points <= 0.0:
		match_result = MatchResult.WIN
		match_phase = MatchPhase.MATCH_OVER
		return true
	if resource_mode == ResourceMode.MATCH and shots_left <= 0:
		match_result = MatchResult.LOSS
		match_phase = MatchPhase.MATCH_OVER
		return true
	return false


## Esito di rifiuto: possesso, contatori e fase restano intatti e
## [code]reason[/code] spiega perché la mossa non è stata eseguita.
func _rejected(reason: String) -> Dictionary:
	last_result = {
		"executed": false,
		"reason": reason,
		"success": false,
		"is_goal": false,
		"turnover": false,
		"phase": match_phase,
		"passes_left": passes_left,
		"shots_left": shots_left,
	}
	return last_result


func _ensure_seeded() -> void:
	if _seeded:
		return
	_rng.randomize()
	_seeded = true
