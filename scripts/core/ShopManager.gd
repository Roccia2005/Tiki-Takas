class_name ShopManager
extends RefCounted

## Calcio Mercato di fine Ante: vitrina, prezzi, acquisti e vendite
## (GDD §6, §6.1, §10 e §10.3).
##
## Utility interamente statica: non va istanziata né registrata come autoload.
## Lo stato della vitrina (offerta esposta e reroll consecutivi) vive in
## GameManager, qui restano le formule pure e le mutazioni esplicite richieste
## su rosa e budget. Ogni acquisto restituisce un Dictionary con
## [code]success[/code], [code]reason[/code] e il nuovo [code]budget[/code].
## [codeblock]
## var offerta := ShopManager.generate_offer()
## var esito := ShopManager.buy_player(rosa, 50, offerta["players"][0])
## if esito["success"]:
## 	budget = esito["budget"]
## [/codeblock]

## Composizione della vitrina: 3 cartellini, 2 talismani, 1 allenamento.
const OFFER_PLAYERS: int = 3
const OFFER_TALISMANS: int = 2
const OFFER_TRAININGS: int = 1

## GDD §6.1: costo del reroll, 2 FC di base con +1 FC per reroll consecutivo.
const REROLL_BASE_COST: int = 2
const REROLL_COST_STEP: int = 1

## GDD §6.1: prezzo di partenza di un cartellino al mercato.
const PLAYER_BASE_COST: int = 4

## GDD §6.1: +3 FC per ogni archetipo già presente negli slot del giocatore.
const ARCHETYPE_COST: int = 3

## GDD §6.1: +1 FC per ogni scaglione di Forza oltre il minimo di ruolo.
const POWER_BONUS_STEP: int = 5

## GDD §6.1: +1 FC se la Gittata supera questa soglia in unità pitch.
const RANGE_BONUS_THRESHOLD: float = 350.0

## GDD §6.1: bonus di prezzo per fascia anagrafica e relativi limiti d'età.
const AGE_BONUS_YOUNG: int = 2
const AGE_BONUS_PRIME: int = 1
const AGE_BONUS_VETERAN: int = 0
const YOUNG_MAX_AGE: int = 22
const PRIME_MAX_AGE: int = 30

## GDD §7: Forza minima di ruolo, base del BonusForza del GDD §6.1.
const ROLE_MIN_POWER := {
	"POR": 3,
	"DIF": 4,
	"CEN": 8,
	"ATT": 15,
}

## GDD §10: valore fisso di partenza nella formula di vendita.
const SELL_BASE_VALUE: int = 2

## GDD §10.2 (Veterano): età da cui il costo d'acquisto è dimezzato.
const VETERANO_MIN_AGE: int = 33
const VETERANO_ARCHETYPE_ID := "veterano"

## GDD §10.1 (Fatturato Record): FC bonus per ogni giocatore venduto.
const TALISMAN_SALES_ID := "fatturato_record"
const TALISMAN_SALES_BONUS: int = 1

## GDD §10.2 (Vivaio DOC): Forza bonus a ogni Compleanno restando under 23.
const VIVAIO_ARCHETYPE_ID := "vivaio_doc"
const VIVAIO_POWER_BONUS: int = 2

## GDD §10.3: identificativi degli allenamenti e relativi valori.
const TRAINING_BULK_UP := "bulk_up"
const TRAINING_BIRTHDAY := "compleanno"
const TRAINING_HAWK_EYE := "occhio_di_falco"
const TRAINING_MASTERCLASS := "masterclass_tattica"
const TRAINING_YOUTH_CAMP := "stage_giovanile"
const TRAINING_EXTRA_SLOT := "slot_extra"

const BULK_UP_POWER: int = 3
const HAWK_EYE_RANGE: float = 100.0
const YOUTH_CAMP_YEARS: int = 3
const BIRTHDAY_YOUNG_POWER: int = 6
const BIRTHDAY_PRIME_POWER: int = 3
const BIRTHDAY_DECLINE_POWER: int = 3
const BIRTHDAY_YOUNG_MAX_AGE: int = 22
const BIRTHDAY_PRIME_MAX_AGE: int = 29
const BIRTHDAY_ARCHETYPE_CHANCE: float = 0.25

static var _rng := RandomNumberGenerator.new()
static var _seeded := false


## Fissa il seme del generatore per vitrine riproducibili nei test.
static func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value
	_seeded = true


## Estrae la vitrina del Calcio Mercato: OFFER_PLAYERS cartellini generati da
## TeamGenerator, OFFER_TALISMANS talismani e OFFER_TRAININGS allenamenti presi
## dal GameCatalog, tutti senza ripetizioni all'interno della stessa categoria.
## Il Dictionary restituito contiene le chiavi [code]players[/code],
## [code]talismans[/code] e [code]trainings[/code].
static func generate_offer() -> Dictionary:
	var players: Array[PlayerData] = []
	for _index in OFFER_PLAYERS:
		players.append(TeamGenerator.generate_player(_random_role()))
	return {
		"players": players,
		"talismans": _pick_talismans(OFFER_TALISMANS),
		"trainings": _pick_trainings(OFFER_TRAININGS),
	}


## Costo del prossimo reroll dopo [param rerolls_done] rimescolamenti nella
## stessa visita: 2 FC, poi 3, poi 4 e così via (GDD §6.1).
static func get_reroll_cost(rerolls_done: int) -> int:
	return REROLL_BASE_COST + maxi(0, rerolls_done) * REROLL_COST_STEP


## Prezzo del cartellino al mercato (GDD §6.1):
## 4 + BonusEtà + BonusForza + BonusGittata + (3 × archetipi).
## Il Veterano dai 33 anni in su costa la metà, arrotondata per eccesso (GDD §10.2).
static func get_player_cost(player: PlayerData) -> int:
	if player == null:
		return 0
	var cost := PLAYER_BASE_COST
	cost += get_age_bonus(player.age)
	cost += get_power_bonus(player)
	if player.range_dist > RANGE_BONUS_THRESHOLD:
		cost += 1
	cost += ARCHETYPE_COST * player.archetypes.size()
	if player.age >= VETERANO_MIN_AGE and has_archetype(player, VETERANO_ARCHETYPE_ID):
		cost = int(ceil(float(cost) / 2.0))
	return maxi(0, cost)


## BonusEtà del GDD §6.1: +2 FC per i giovani talenti, +1 nel pieno della
## carriera, nulla per i veterani.
static func get_age_bonus(age: int) -> int:
	if age <= YOUNG_MAX_AGE:
		return AGE_BONUS_YOUNG
	if age <= PRIME_MAX_AGE:
		return AGE_BONUS_PRIME
	return AGE_BONUS_VETERAN


## BonusForza del GDD §6.1: +1 FC per ogni 5 punti di Forza oltre il minimo che
## il GDD §7 assegna al ruolo del giocatore.
static func get_power_bonus(player: PlayerData) -> int:
	if player == null:
		return 0
	var minimum: int = ROLE_MIN_POWER.get(player.role, 0)
	var surplus := player.power - minimum
	if surplus <= 0:
		return 0
	return surplus / POWER_BONUS_STEP


## Ricavo della cessione di un panchinaro (GDD §10):
## 2 + (1 × archetipi) + (1 × allenamenti), più il bonus del talismano
## Fatturato Record se la squadra lo ha equipaggiato (GDD §10.1).
static func get_sell_value(player: PlayerData, team: TeamData = null) -> int:
	if player == null:
		return 0
	var value := SELL_BASE_VALUE + player.archetypes.size() + player.trainings.size()
	if team != null and team.find_talisman(TALISMAN_SALES_ID) != null:
		value += TALISMAN_SALES_BONUS
	return value


## True se il cartellino ha equipaggiato l'archetipo indicato.
static func has_archetype(player: PlayerData, archetype_id: String) -> bool:
	if player == null:
		return false
	for entry in player.archetypes:
		var archetype := entry as ArchetypeData
		if archetype != null and archetype.id == archetype_id:
			return true
	return false


## Acquista [param player] e lo mette in panchina (GDD §5 e §6.1).
##
## Rifiuta l'operazione se il budget non basta o se la panchina ha già
## TeamData.MAX_BENCH riserve: in quel caso il GDD §5 impone di svincolare prima
## un giocatore della rosa con [method sell_player].
static func buy_player(team: TeamData, budget: int, player: PlayerData) -> Dictionary:
	if team == null or player == null:
		return _failed(budget, "rosa o cartellino non validi")
	if team.players.has(player):
		return _failed(budget, "cartellino già in rosa")
	if not team.has_bench_space():
		return _failed(budget, "panchina piena: massimo %d riserve" % TeamData.MAX_BENCH)
	var cost := get_player_cost(player)
	if cost > budget:
		return _failed(budget, "budget insufficiente: servono %d FC" % cost)
	team.players.append(player)
	var result := _succeeded(budget - cost, cost)
	result["player"] = player
	return result


## Cede [param player] e accredita il ricavo della formula di vendita (GDD §10).
##
## Un titolare non può essere venduto lasciando lo slot sguarnito: va prima
## scambiato con un panchinaro, quindi qui viene rifiutato.
static func sell_player(team: TeamData, budget: int, player: PlayerData) -> Dictionary:
	if team == null or player == null:
		return _failed(budget, "rosa o cartellino non validi")
	if not team.players.has(player):
		return _failed(budget, "cartellino non presente in rosa")
	if team.find_slot(player) >= 1:
		return _failed(budget, "un titolare non può essere venduto: scambialo prima con un panchinaro")
	var revenue := get_sell_value(player, team)
	team.players.erase(player)
	var result := _succeeded(budget + revenue, 0)
	result["revenue"] = revenue
	result["player"] = player
	return result


## Equipaggia un talismano di squadra (GDD §10 e §10.1).
##
## Un talismano dello stesso id sovrascrive il precedente senza costi di slot;
## oltre TalismanData.MAX_EQUIPPED talismani attivi l'acquisto viene rifiutato,
## come da GDD §10.
static func buy_talisman(team: TeamData, budget: int, talisman: TalismanData) -> Dictionary:
	if team == null or talisman == null:
		return _failed(budget, "rosa o talismano non validi")
	var cost := talisman.cost
	if cost > budget:
		return _failed(budget, "budget insufficiente: servono %d FC" % cost)
	var existing := team.find_talisman(talisman.id)
	if existing == null and not team.has_talisman_space():
		return _failed(budget, "talismani al completo: massimo %d" % TalismanData.MAX_EQUIPPED)
	if existing != null:
		team.talismans[team.talismans.find(existing)] = talisman
	else:
		team.talismans.append(talisman)
	var result := _succeeded(budget - cost, cost)
	result["talisman"] = talisman
	return result


## Acquista un allenamento e lo applica subito a [param target_player] (GDD §10.3).
##
## [param new_role] serve solo alla Masterclass Tattica, che converte il ruolo:
## per tutti gli altri allenamenti viene ignorato. Il cartellino deve essere in
## rosa e l'effetto deve essere applicabile, altrimenti il budget non viene
## toccato.
static func buy_training(team: TeamData, budget: int, training: TrainingData, target_player: PlayerData, new_role: String = "") -> Dictionary:
	if team == null or training == null or target_player == null:
		return _failed(budget, "rosa, allenamento o destinatario non validi")
	if not team.players.has(target_player):
		return _failed(budget, "il destinatario non è in rosa")
	var cost := training.cost
	if cost > budget:
		return _failed(budget, "budget insufficiente: servono %d FC" % cost)
	var applied := apply_training(training, target_player, new_role)
	if not applied["success"]:
		return _failed(budget, applied["reason"])
	var result := _succeeded(budget - cost, cost)
	result["training"] = training
	result["player"] = target_player
	result["effect"] = applied
	return result


## Applica l'effetto permanente di un allenamento al cartellino (GDD §10.3).
##
## Gli allenamenti sono cumulabili all'infinito (GDD §5) e vengono registrati in
## [member PlayerData.trainings], da cui la formula di vendita del GDD §10 ricava
## il ricavo di cessione. Il Dictionary restituito riporta
## [code]success[/code], [code]reason[/code] e i campi modificati.
static func apply_training(training: TrainingData, player: PlayerData, new_role: String = "") -> Dictionary:
	if training == null or player == null:
		return {"success": false, "reason": "allenamento o cartellino non validi"}
	var effect := {"success": true, "reason": ""}
	match training.id:
		TRAINING_BULK_UP:
			player.power += BULK_UP_POWER
			effect["power"] = player.power
		TRAINING_HAWK_EYE:
			player.range_dist += HAWK_EYE_RANGE
			effect["range_dist"] = player.range_dist
		TRAINING_EXTRA_SLOT:
			if player.archetype_slots >= PlayerData.MAX_ARCHETYPE_SLOTS:
				return {"success": false, "reason": "slot archetipi già al massimo (%d)" % PlayerData.MAX_ARCHETYPE_SLOTS}
			player.archetype_slots += 1
			effect["archetype_slots"] = player.archetype_slots
		TRAINING_YOUTH_CAMP:
			if player.age <= PlayerData.MIN_AGE:
				return {"success": false, "reason": "il giocatore ha già l'età minima (%d)" % PlayerData.MIN_AGE}
			player.age = maxi(PlayerData.MIN_AGE, player.age - YOUTH_CAMP_YEARS)
			effect["age"] = player.age
		TRAINING_MASTERCLASS:
			var role := new_role.to_upper()
			if not PlayerData.ROLES.has(role):
				return {"success": false, "reason": "ruolo di destinazione non valido: '%s'" % new_role}
			if role == player.role:
				return {"success": false, "reason": "il giocatore ricopre già il ruolo %s" % role}
			player.role = role
			effect["role"] = player.role
		TRAINING_BIRTHDAY:
			var birthday := _apply_birthday(player)
			if not birthday["success"]:
				return birthday
			effect.merge(birthday, true)
		_:
			return {"success": false, "reason": "allenamento senza effetto noto: '%s'" % training.id}
	player.trainings.append(training)
	effect["trainings"] = player.trainings.size()
	return effect


## Compleanno (GDD §10.3): l'età avanza di un anno e la Forza viene ricalcolata
## sulla nuova fascia anagrafica. Restando under 23 c'è anche il 25% di sbloccare
## un archetipo casuale gratuito, più il bonus del Vivaio DOC (GDD §10.2).
static func _apply_birthday(player: PlayerData) -> Dictionary:
	if player.age >= PlayerData.MAX_AGE:
		return {"success": false, "reason": "il giocatore ha già l'età massima (%d)" % PlayerData.MAX_AGE}
	player.age += 1
	var unlocked: ArchetypeData = null
	if player.age <= BIRTHDAY_YOUNG_MAX_AGE:
		player.power += BIRTHDAY_YOUNG_POWER
		if has_archetype(player, VIVAIO_ARCHETYPE_ID):
			player.power += VIVAIO_POWER_BONUS
		_ensure_seeded()
		if _rng.randf() < BIRTHDAY_ARCHETYPE_CHANCE:
			unlocked = _equip_random_archetype(player)
	elif player.age <= BIRTHDAY_PRIME_MAX_AGE:
		player.power += BIRTHDAY_PRIME_POWER
	else:
		player.power -= BIRTHDAY_DECLINE_POWER * (player.age - BIRTHDAY_PRIME_MAX_AGE)
	player.power = maxi(0, player.power)
	return {
		"success": true,
		"reason": "",
		"age": player.age,
		"power": player.power,
		"unlocked_archetype": unlocked,
	}


## Equipaggia un archetipo casuale non ancora presente, se il cartellino ha uno
## slot libero. Null se gli slot sono pieni o il catalogo non offre alternative.
static func _equip_random_archetype(player: PlayerData) -> ArchetypeData:
	if player.archetypes.size() >= player.archetype_slots:
		return null
	var candidates: Array[ArchetypeData] = []
	for archetype in GameCatalog.get_all_archetypes():
		if not has_archetype(player, archetype.id):
			candidates.append(archetype)
	if candidates.is_empty():
		return null
	_ensure_seeded()
	var picked: ArchetypeData = candidates[_rng.randi_range(0, candidates.size() - 1)]
	player.archetypes.append(picked)
	return picked


## Ruolo del prossimo cartellino in vitrina, estratto uniformemente fra i quattro
## ruoli ammessi da PlayerData.ROLES.
static func _random_role() -> String:
	_ensure_seeded()
	var role: String = PlayerData.ROLES[_rng.randi_range(0, PlayerData.ROLES.size() - 1)]
	return role


## Talismani distinti estratti dal catalogo (GDD §10.1).
static func _pick_talismans(count: int) -> Array[TalismanData]:
	var pool := GameCatalog.get_all_talismans()
	var picked: Array[TalismanData] = []
	for index in _pick_indices(pool.size(), count):
		picked.append(pool[index])
	return picked


## Allenamenti distinti estratti dal catalogo (GDD §10.3).
static func _pick_trainings(count: int) -> Array[TrainingData]:
	var pool := GameCatalog.get_all_trainings()
	var picked: Array[TrainingData] = []
	for index in _pick_indices(pool.size(), count):
		picked.append(pool[index])
	return picked


## Estrae [param count] indici distinti da un pool di [param pool_size] elementi,
## meno se il pool è più piccolo della richiesta.
static func _pick_indices(pool_size: int, count: int) -> Array[int]:
	_ensure_seeded()
	var available: Array[int] = []
	for index in pool_size:
		available.append(index)
	var picked: Array[int] = []
	while picked.size() < count and not available.is_empty():
		var slot := _rng.randi_range(0, available.size() - 1)
		picked.append(available[slot])
		available.remove_at(slot)
	return picked


## Semina il generatore al primo utilizzo, se set_seed() non è stato chiamato.
static func _ensure_seeded() -> void:
	if not _seeded:
		_rng.randomize()
		_seeded = true


## Esito negativo: il budget resta quello di partenza e reason spiega il rifiuto.
static func _failed(budget: int, reason: String) -> Dictionary:
	return {
		"success": false,
		"reason": reason,
		"budget": budget,
		"cost": 0,
	}


## Esito positivo con il budget aggiornato e il costo effettivamente addebitato.
static func _succeeded(new_budget: int, cost: int) -> Dictionary:
	return {
		"success": true,
		"reason": "",
		"budget": new_budget,
		"cost": cost,
	}
