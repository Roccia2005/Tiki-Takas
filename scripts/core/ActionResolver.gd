class_name ActionResolver
extends RefCounted

## Motore di risoluzione dell'azione: geometria e formule del GDD §4, §4.1 e §7.
##
## Utility interamente statica e priva di effetti collaterali: non istanzia
## nodi, non modifica i cartellini e non consuma contatori. Chi la usa (il
## futuro MatchController) legge il dizionario di esito e applica le
## conseguenze, tocchi inclusi tramite [method PlayerData.register_touch].
## [codeblock]
## var esito := ActionResolver.resolve_pass(portiere, Vector2(60, 300), Vector2(450, 240))
## if esito["success"]:
## 	potenza_azione += esito["power_delta"]
## [/codeblock]

## Ascissa della linea di porta avversaria sulla griglia pitch (GDD §7:
## 0 = linea di fondo propria, 1000 = porta avversaria).
const GOAL_LINE_X: float = 1000.0

## Ordinata del centro della porta, metà dell'altezza del campo (GDD §9).
const GOAL_CENTER_Y: float = 300.0

## GDD §4.1: Potenza Azione persa per ogni unità di passaggio oltre la Gittata.
const RANGE_PENALTY_PER_UNIT: float = 0.05

## GDD §7: decadimento del tiro per ogni unità oltre la Gittata (1 / 500).
const SHOT_DECAY_PER_UNIT: float = 0.002

## GDD §7: moltiplicatore minimo garantito di un tiro dalla distanza.
const MIN_SHOT_MULTIPLIER: float = 0.20

## GDD §4.1: malus secco applicato quando la traiettoria interseca una sagoma
## avversaria che però perde il duello e non intercetta.
const OBSTACLE_POWER_MALUS: float = 15.0

## Raggio entro cui una sagoma difensiva prova a intercettare, in unità pitch.
const DEFAULT_INTERCEPT_RADIUS: float = 60.0

## Semiapertura in gradi del cono di tiro: i difensori che ricadono in questo
## spicchio tra tiratore e porta sommano la Forza alla parata (GDD §4).
const SHOT_CONE_HALF_ANGLE_DEG: float = 18.0


## Distanza euclidea tra due punti del campo, in unità pitch.
static func calculate_distance(from_pos: Vector2, to_pos: Vector2) -> float:
	return from_pos.distance_to(to_pos)


## Posizione canonica del portiere avversario: centro della linea di porta.
static func get_goal_position() -> Vector2:
	return Vector2(GOAL_LINE_X, GOAL_CENTER_Y)


## True se [param target_pos] cade entro la Gittata di [param passer], cioè se
## il passaggio non subisce perdite di potenza da distanza (GDD §4.1).
static func is_pass_in_range(passer: PlayerData, from_pos: Vector2, target_pos: Vector2) -> bool:
	if passer == null:
		return false
	return calculate_distance(from_pos, target_pos) <= passer.range_dist


## Perdita di Potenza Azione di un passaggio fuori gittata (GDD §4.1):
## (Distanza - Gittata) × 0.05, mai negativa.
static func calculate_range_penalty(distance: float, range_dist: float) -> float:
	if distance <= range_dist:
		return 0.0
	return (distance - range_dist) * RANGE_PENALTY_PER_UNIT


## Moltiplicatore di danno del tiro in funzione della distanza (GDD §7):
## max(0.20, 1.0 - (Distanza - Gittata) / 500). Vale 1.0 entro la Gittata.
static func calculate_distance_multiplier(distance: float, range_dist: float) -> float:
	if distance <= range_dist:
		return 1.0
	return maxf(MIN_SHOT_MULTIPLIER, 1.0 - (distance - range_dist) * SHOT_DECAY_PER_UNIT)


## Sagoma difensiva avversaria pronta per [method resolve_pass] e
## [method filter_defenders_in_cone]: cartellino, posizione sul campo e raggio
## entro cui tenta l'intercetto.
static func make_defender(player: PlayerData, field_pos: Vector2, intercept_radius: float = DEFAULT_INTERCEPT_RADIUS) -> Dictionary:
	return {
		"player": player,
		"position": field_pos,
		"radius": intercept_radius,
	}


## Distanza minima tra un punto e il segmento di traiettoria da [param from_pos]
## a [param to_pos].
static func distance_to_trajectory(point: Vector2, from_pos: Vector2, to_pos: Vector2) -> float:
	var closest := Geometry2D.get_closest_point_to_segment(point, from_pos, to_pos)
	return point.distance_to(closest)


## Avanzamento normalizzato (0-1) della proiezione di un punto sulla traiettoria:
## stabilisce quale sagoma incontra la palla per prima.
static func trajectory_progress(point: Vector2, from_pos: Vector2, to_pos: Vector2) -> float:
	var span := to_pos - from_pos
	var length_squared := span.length_squared()
	if is_zero_approx(length_squared):
		return 0.0
	return clampf((point - from_pos).dot(span) / length_squared, 0.0, 1.0)


## True se la sagoma in [param defender_pos] ostruisce il cono di tiro che parte
## da [param shooter_pos] e punta a [param goal_pos] (GDD §4). Le sagome più
## lontane della porta restano fuori dal cono.
static func is_in_shot_cone(defender_pos: Vector2, shooter_pos: Vector2, goal_pos: Vector2, half_angle_deg: float = SHOT_CONE_HALF_ANGLE_DEG) -> bool:
	var to_goal := goal_pos - shooter_pos
	var to_defender := defender_pos - shooter_pos
	if is_zero_approx(to_goal.length_squared()) or is_zero_approx(to_defender.length_squared()):
		return false
	if to_defender.length() > to_goal.length():
		return false
	return absf(rad_to_deg(to_goal.angle_to(to_defender))) <= half_angle_deg


## Cartellini delle sagome avversarie che ostruiscono il cono di tiro, pronti per
## il parametro [param defenders_in_cone] di [method resolve_shot].
static func filter_defenders_in_cone(defenders: Array[Dictionary], shooter_pos: Vector2, goal_pos: Vector2, half_angle_deg: float = SHOT_CONE_HALF_ANGLE_DEG) -> Array[PlayerData]:
	var in_cone: Array[PlayerData] = []
	for entry in defenders:
		var defender := _entry_player(entry)
		if defender == null:
			continue
		if is_in_shot_cone(_entry_position(entry), shooter_pos, goal_pos, half_angle_deg):
			in_cone.append(defender)
	return in_cone


## Risolve un passaggio da [param from_pos] a [param to_pos] (GDD §4 e §4.1).
##
## La traiettoria viene confrontata con il raggio di intercettazione delle sagome
## avversarie in [param defenders] (da costruire con [method make_defender]): la
## prima sagoma incontrata lungo il tragitto la cui Forza supera il contributo
## effettivo del passatore intercetta la palla, i pari merito li vince chi passa.
## Le sagome attraversate che perdono il duello applicano il malus secco di
## -15 punti previsto dal GDD §4.1.
##
## [param current_action_power] è la Potenza Azione già accumulata prima di
## questo passaggio e serve solo a calcolare la condizione di palla persa.
## Il dizionario restituito contiene:
## [code]success[/code], [code]intercepted_by[/code], [code]effective_power[/code],
## [code]distance[/code], [code]in_range[/code], [code]range_penalty[/code],
## [code]obstacle_malus[/code], [code]contested[/code], [code]power_delta[/code],
## [code]action_power[/code] e [code]turnover[/code].
static func resolve_pass(passer: PlayerData, from_pos: Vector2, to_pos: Vector2, defenders: Array[Dictionary] = [], current_action_power: float = 0.0) -> Dictionary:
	var distance := calculate_distance(from_pos, to_pos)
	var effective_power := 0.0
	var range_dist := 0.0
	if passer == null:
		push_warning("ActionResolver: passaggio senza passatore, contributo nullo")
	else:
		effective_power = passer.get_effective_power()
		range_dist = passer.range_dist
	var range_penalty := calculate_range_penalty(distance, range_dist)

	var intercepted_by: PlayerData = null
	var contested: Array[PlayerData] = []
	for entry in _defenders_on_trajectory(defenders, from_pos, to_pos):
		var defender := _entry_player(entry)
		contested.append(defender)
		if intercepted_by == null and float(defender.power) > effective_power:
			intercepted_by = defender

	var success := intercepted_by == null
	var obstacle_malus := 0.0
	var power_delta := 0.0
	var action_power := current_action_power
	if success:
		obstacle_malus = OBSTACLE_POWER_MALUS * float(contested.size())
		power_delta = effective_power - range_penalty - obstacle_malus
		action_power += power_delta
	return {
		"success": success,
		"intercepted_by": intercepted_by,
		"effective_power": effective_power,
		"distance": distance,
		"in_range": distance <= range_dist,
		"range_penalty": range_penalty,
		"obstacle_malus": obstacle_malus,
		"contested": contested,
		"power_delta": power_delta,
		"action_power": action_power,
		"turnover": not success or action_power <= 0.0,
	}


## Risolve un tiro in porta (GDD §4 e §7).
##
## Il valore di tiro parte dalla Potenza Azione accumulata se [param action_power]
## è maggiore di zero, altrimenti dal solo contributo effettivo del tiratore
## ([method PlayerData.get_effective_power]); viene poi scalato dal decadimento
## di distanza del GDD §7 misurato tra tiratore e portiere avversario.
## La difesa somma la Forza del portiere e quella dei difensori nel cono di tiro,
## selezionabili con [method filter_defenders_in_cone].
## Il dizionario restituito contiene:
## [code]is_goal[/code], [code]shot_value[/code], [code]defense_total[/code],
## [code]distance[/code], [code]in_range[/code], [code]distance_multiplier[/code],
## [code]base_power[/code], [code]defenders_in_cone[/code] e
## [code]save_points_left[/code], i punti parata residui del portiere.
static func resolve_shot(shooter: PlayerData, shooter_pos: Vector2, gk: PlayerData, gk_pos: Vector2, defenders_in_cone: Array[PlayerData] = [], action_power: float = 0.0) -> Dictionary:
	var distance := calculate_distance(shooter_pos, gk_pos)
	var base_power := maxf(0.0, action_power)
	var range_dist := 0.0
	if shooter == null:
		push_warning("ActionResolver: tiro senza tiratore, valore di tiro nullo")
	else:
		range_dist = shooter.range_dist
		if is_zero_approx(base_power):
			base_power = shooter.get_effective_power()
	var multiplier := calculate_distance_multiplier(distance, range_dist)
	var shot_value := base_power * multiplier

	var defense_total := 0.0
	if gk != null:
		defense_total += float(gk.power)
	for defender in defenders_in_cone:
		if defender == null:
			continue
		defense_total += float(defender.power)

	return {
		"is_goal": shot_value > 0.0 and shot_value >= defense_total,
		"shot_value": shot_value,
		"defense_total": defense_total,
		"distance": distance,
		"in_range": distance <= range_dist,
		"distance_multiplier": multiplier,
		"base_power": base_power,
		"defenders_in_cone": defenders_in_cone.size(),
		"save_points_left": maxf(0.0, defense_total - shot_value),
	}


## Sagome la cui distanza dalla traiettoria rientra nel proprio raggio di
## intercettazione, ordinate da quella che incontra la palla per prima.
static func _defenders_on_trajectory(defenders: Array[Dictionary], from_pos: Vector2, to_pos: Vector2) -> Array[Dictionary]:
	var crossed: Array[Dictionary] = []
	for entry in defenders:
		var defender := _entry_player(entry)
		if defender == null:
			continue
		var field_pos := _entry_position(entry)
		if distance_to_trajectory(field_pos, from_pos, to_pos) > _entry_radius(entry):
			continue
		var progress := trajectory_progress(field_pos, from_pos, to_pos)
		var insert_at := crossed.size()
		for index in crossed.size():
			var other: float = crossed[index]["progress"]
			if progress < other:
				insert_at = index
				break
		crossed.insert(insert_at, {"player": defender, "progress": progress})
	return crossed


## Cartellino contenuto in una sagoma, null se la voce è malformata.
static func _entry_player(entry: Dictionary) -> PlayerData:
	if not entry.has("player") or not (entry["player"] is PlayerData):
		return null
	var player: PlayerData = entry["player"]
	return player


## Posizione contenuta in una sagoma, Vector2.ZERO se la voce è malformata.
static func _entry_position(entry: Dictionary) -> Vector2:
	if not entry.has("position") or not (entry["position"] is Vector2):
		return Vector2.ZERO
	var field_pos: Vector2 = entry["position"]
	return field_pos


## Raggio di intercettazione di una sagoma, con ripiego sul valore predefinito.
static func _entry_radius(entry: Dictionary) -> float:
	if not entry.has("radius"):
		return DEFAULT_INTERCEPT_RADIUS
	var raw: Variant = entry["radius"]
	if raw is float or raw is int:
		return float(raw)
	return DEFAULT_INTERCEPT_RADIUS
