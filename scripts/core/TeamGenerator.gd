class_name TeamGenerator
extends RefCounted

## Generatore procedurale di calciatori e rose iniziali (GDD §2.3, §5 e §7).
##
## Utility interamente statica: non va istanziata né registrata come autoload.
## I cartellini nascono senza archetipi né allenamenti, salvo i tratti
## identitari della squadra scelta (GDD §2.3).
## [codeblock]
## var standard := TeamGenerator.generate_starter_team()
## var italiana := TeamGenerator.generate_starter_team(null, "Italiana")  # 5-3-2, DIF +3
## var riserva := TeamGenerator.generate_player("CEN")
## [/codeblock]

## Modulo assegnato quando non ne viene passato uno valido (squadra Standard,
## GDD §2.3), caricato tramite GameCatalog.
const DEFAULT_FORMATION := "4-4-2"

## Nome usato per la rosa se il chiamante non ne indica uno.
const DEFAULT_TEAM_NAME := "Standard"

## GDD §7: potenza base minima e massima per ruolo.
const POWER_BOUNDS := {
	"POR": Vector2i(3, 5),
	"DIF": Vector2i(4, 8),
	"CEN": Vector2i(8, 14),
	"ATT": Vector2i(15, 25),
}

## GDD §7: gittata base minima e massima per ruolo, in unità pitch.
const RANGE_BOUNDS := {
	"POR": Vector2i(300, 450),
	"DIF": Vector2i(250, 400),
	"CEN": Vector2i(300, 450),
	"ATT": Vector2i(200, 350),
}

## Peso relativo del numero di slot archetipo: l'indice è il numero di slot.
## GDD §5: "i giocatori con molti slot sono più rari".
const ARCHETYPE_SLOT_WEIGHTS := [40, 30, 16, 9, 4, 1]

## Tentativi massimi per estrarre un nome non già assegnato nella stessa rosa.
const MAX_NAME_ATTEMPTS: int = 24

## GDD §2.3: modulo di partenza di ogni squadra selezionabile.
const TEAM_FORMATIONS := {
	"Standard": "4-4-2",
	"Italiana": "5-3-2",
	"Spagnola": "4-3-3",
	"Portoghese": "4-3-2-1",
	"Brasiliana": "4-2-4",
	"Inglese": "4-4-2",
}

## GDD §2.3: squadre il cui tratto agisce già sui cartellini alla generazione.
## La Standard non ha modificatori e il tratto della Spagnola (moltiplicatore per
## passaggio consecutivo) vale in partita, non sulla rosa.
const GENERATION_TRAITS := ["Italiana", "Portoghese", "Brasiliana", "Inglese"]

## GDD §2.3 (Italiana): Forza in più per ogni difensore.
const ITALIANA_DEFENDER_POWER_BONUS: int = 3

## GDD §2.3 (Portoghese): slot archetipo garantiti al Fuoriclasse.
const PORTOGHESE_CHAMPION_SLOTS: int = 5

## GDD §2.3 (Brasiliana): quante ali offensive ricevono lo Skiller.
const BRASILIANA_SKILLER_COUNT: int = 2

## GDD §2.3 (Inglese): moltiplicatore di Gittata per portiere e difensori.
const INGLESE_RANGE_MULTIPLIER: float = 1.5

## Ordinata centrale del campo sulla griglia pitch 1000x600 (GDD §9): serve a
## distinguere i giocatori centrali dalle ali.
const PITCH_CENTER_Y: float = 300.0

const FIRST_NAMES := [
	"Alessio", "Matteo", "Davide", "Luca", "Simone", "Andrea", "Gabriele",
	"Nicolò", "Tommaso", "Federico", "Diego", "Rafael", "Iker", "Milos",
	"Tomas", "Yannick", "Sven", "Adama", "Kofi", "Hugo",
]

const LAST_NAMES := [
	"Bertolini", "Corradi", "Fabbri", "Marchetti", "Pellegrini", "Rossetti",
	"Salvatori", "Vitali", "Zanetti", "Lombardi", "Moretti", "Barbieri",
	"Ferrero", "Costa", "Duarte", "Almeida", "Nowak", "Kovac", "Halvorsen",
	"Bakker", "Traoré", "Owusu", "Vermeulen", "Radic",
]

static var _rng := RandomNumberGenerator.new()
static var _seeded := false


## Genera la rosa iniziale di una run: 11 titolari casuali senza potenziamenti,
## assegnati agli slot del modulo indicato secondo il ruolo che ogni slot
## prevede (GDD §5 e §9). La panchina resta vuota, come da GDD §5.
## Se [param formation] è null viene caricato dal GameCatalog il modulo di
## partenza che il GDD §2.3 assegna a [param team_name], con ripiego sul 4-4-2.
## Con [param apply_trait] attivo la rosa riceve subito il tratto identitario
## della squadra, se ne ha uno che agisce alla generazione.
## Restituisce null solo se nemmeno il modulo richiesto è disponibile.
static func generate_starter_team(formation: FormationData = null, team_name: String = DEFAULT_TEAM_NAME, apply_trait: bool = true) -> TeamData:
	var used_formation := formation
	var formation_name := _formation_name_for(team_name)
	if used_formation == null:
		used_formation = GameCatalog.get_formation(formation_name)
	if used_formation == null:
		push_error("TeamGenerator: modulo '%s' non presente nel catalogo" % formation_name)
		return null

	var team := TeamData.new()
	team.resource_name = team_name
	team.team_name = team_name
	team.current_formation = used_formation

	var slot_roles := used_formation.get_slot_roles()
	var used_names: Dictionary[String, bool] = {}
	for slot in range(1, TeamData.LINEUP_SIZE + 1):
		var role := "CEN"
		if slot_roles.has(slot):
			role = slot_roles[slot]
		else:
			push_warning("TeamGenerator: ruolo non definito per lo slot %d" % slot)
		# set_starter registra il cartellino anche in team.players.
		team.set_starter(slot, _build_player(role, _unique_name(used_names)))

	if apply_trait:
		apply_team_trait(team, team_name)
	return team


## Crea un singolo calciatore casuale del ruolo indicato, senza archetipi.
## Utile anche per popolare il Calcio Mercato (GDD §6.1).
static func generate_player(role: String) -> PlayerData:
	return _build_player(role, _random_full_name())


## Fissa il seme del generatore per ottenere rose riproducibili, ad esempio
## nei test o nelle run a seme fisso.
static func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value
	_seeded = true


## Applica alla rosa già generata il tratto identitario della squadra indicata
## (GDD §2.3):
## [br]- Italiana: +3 alla Forza di ogni difensore.
## [br]- Portoghese: la punta più avanzata sale a 5 slot archetipo e riceve Bomber.
## [br]- Brasiliana: le due ali offensive più larghe ricevono Skiller.
## [br]- Inglese: +50% di Gittata a portiere e difensori.
## [br]Restituisce true solo se il tratto ha davvero modificato i cartellini:
## Standard non ha modificatori e il tratto della Spagnola agisce in partita.
static func apply_team_trait(team: TeamData, trait_name: String) -> bool:
	if team == null:
		push_warning("TeamGenerator: impossibile applicare un tratto a una rosa null")
		return false
	match trait_name:
		"Italiana":
			_apply_italiana(team)
		"Portoghese":
			_apply_portoghese(team)
		"Brasiliana":
			_apply_brasiliana(team)
		"Inglese":
			_apply_inglese(team)
		_:
			return false
	return true


## Nomi delle squadre il cui tratto viene applicato alla generazione (GDD §2.3).
static func get_supported_traits() -> Array[String]:
	var traits: Array[String] = []
	traits.assign(GENERATION_TRAITS)
	return traits


## Modulo di partenza previsto dal GDD §2.3 per la squadra indicata, con ripiego
## sul 4-4-2 per i nomi personalizzati.
static func _formation_name_for(team_name: String) -> String:
	if not TEAM_FORMATIONS.has(team_name):
		return DEFAULT_FORMATION
	var mapped: String = TEAM_FORMATIONS[team_name]
	return mapped


## Italiana: catenaccio, ogni difensore parte con Forza maggiorata.
static func _apply_italiana(team: TeamData) -> void:
	for player in team.players:
		if player != null and player.role == "DIF":
			player.power += ITALIANA_DEFENDER_POWER_BONUS


## Portoghese: il Fuoriclasse è la punta più avanzata e centrale, con tutti gli
## slot archetipo aperti e Bomber già equipaggiato.
static func _apply_portoghese(team: TeamData) -> void:
	var champion := _find_most_advanced(team, "ATT")
	if champion == null:
		push_warning("TeamGenerator: tratto Portoghese senza attaccanti schierati")
		return
	champion.archetype_slots = PORTOGHESE_CHAMPION_SLOTS
	_equip_archetype(champion, "bomber")


## Brasiliana: lo Skiller va alle due pedine offensive più larghe, cioè le ali.
static func _apply_brasiliana(team: TeamData) -> void:
	var wingers := _find_widest_offensive(team, BRASILIANA_SKILLER_COUNT)
	if wingers.size() < BRASILIANA_SKILLER_COUNT:
		push_warning("TeamGenerator: tratto Brasiliana con meno di %d pedine offensive" % BRASILIANA_SKILLER_COUNT)
	for winger in wingers:
		_equip_archetype(winger, "skiller")


## Inglese: palla lunga e pedalare, gittata maggiorata per portiere e difensori.
static func _apply_inglese(team: TeamData) -> void:
	for player in team.players:
		if player == null:
			continue
		if player.role == "POR" or player.role == "DIF":
			player.range_dist *= INGLESE_RANGE_MULTIPLIER


## Cartellino con età, potenza, gittata e slot archetipo casuali entro i limiti
## di ruolo del GDD §7.
static func _build_player(role: String, player_name: String) -> PlayerData:
	_ensure_seeded()
	var checked_role := _normalize_role(role)
	var power_bounds: Vector2i = POWER_BOUNDS[checked_role]
	var range_bounds: Vector2i = RANGE_BOUNDS[checked_role]

	var player := PlayerData.new()
	player.resource_name = player_name
	player.player_name = player_name
	player.role = checked_role
	player.age = _rng.randi_range(PlayerData.MIN_AGE, PlayerData.MAX_AGE)
	player.power = _rng.randi_range(power_bounds.x, power_bounds.y)
	player.range_dist = float(_rng.randi_range(range_bounds.x, range_bounds.y))
	player.archetype_slots = _random_archetype_slots()
	player.archetypes = []
	return player


## Ruolo in maiuscolo se ammesso da PlayerData.ROLES, "CEN" come ripiego.
static func _normalize_role(role: String) -> String:
	var upper := role.to_upper()
	if not PlayerData.ROLES.has(upper):
		push_warning("TeamGenerator: ruolo non riconosciuto '%s', assegnato CEN" % role)
		return "CEN"
	return upper


## Estrazione pesata del numero di slot archetipo (0-5): più slot, più raro.
static func _random_archetype_slots() -> int:
	_ensure_seeded()
	var total := 0
	for weight in ARCHETYPE_SLOT_WEIGHTS:
		total += int(weight)
	var pick := _rng.randi_range(1, total)
	var cumulative := 0
	for index in ARCHETYPE_SLOT_WEIGHTS.size():
		cumulative += int(ARCHETYPE_SLOT_WEIGHTS[index])
		if pick <= cumulative:
			return index
	return 0


## Nome completo non ancora usato nella rosa in costruzione. Dopo troppi
## tentativi a vuoto aggiunge un suffisso numerico per garantire l'unicità.
static func _unique_name(used_names: Dictionary[String, bool]) -> String:
	for _attempt in MAX_NAME_ATTEMPTS:
		var candidate := _random_full_name()
		if not used_names.has(candidate):
			used_names[candidate] = true
			return candidate
	var fallback := "%s %d" % [_random_full_name(), used_names.size() + 1]
	used_names[fallback] = true
	return fallback


## Combinazione casuale di nome e cognome dai pool interni.
static func _random_full_name() -> String:
	_ensure_seeded()
	var first: String = FIRST_NAMES[_rng.randi_range(0, FIRST_NAMES.size() - 1)]
	var last: String = LAST_NAMES[_rng.randi_range(0, LAST_NAMES.size() - 1)]
	return "%s %s" % [first, last]


## Semina il generatore al primo utilizzo, se set_seed() non è stato chiamato.
static func _ensure_seeded() -> void:
	if not _seeded:
		_rng.randomize()
		_seeded = true


## Titolare del ruolo indicato più vicino alla porta avversaria; a pari ascissa
## vince quello più centrale. Null se nessuno slot ospita quel ruolo.
static func _find_most_advanced(team: TeamData, role: String) -> PlayerData:
	var best: PlayerData = null
	var best_x := -1.0
	var best_offset := INF
	for slot in range(1, TeamData.LINEUP_SIZE + 1):
		var player := team.get_starter(slot)
		if player == null or player.role != role:
			continue
		var field_pos := _slot_position(team, slot)
		var offset := absf(field_pos.y - PITCH_CENTER_Y)
		if field_pos.x > best_x or (is_equal_approx(field_pos.x, best_x) and offset < best_offset):
			best = player
			best_x = field_pos.x
			best_offset = offset
	return best


## Titolari offensivi (ATT o CEN) ordinati dal più larghe rispetto all'asse del
## campo: sono le ali, destinatarie naturali dello Skiller (GDD §2.3).
## A pari larghezza precede chi è più avanzato.
static func _find_widest_offensive(team: TeamData, count: int) -> Array[PlayerData]:
	var ranked: Array[Dictionary] = []
	for slot in range(1, TeamData.LINEUP_SIZE + 1):
		var player := team.get_starter(slot)
		if player == null:
			continue
		if player.role != "ATT" and player.role != "CEN":
			continue
		var field_pos := _slot_position(team, slot)
		var wide := absf(field_pos.y - PITCH_CENTER_Y)
		var insert_at := ranked.size()
		for index in ranked.size():
			var other_wide: float = ranked[index]["wide"]
			var other_x: float = ranked[index]["x"]
			if wide > other_wide or (is_equal_approx(wide, other_wide) and field_pos.x > other_x):
				insert_at = index
				break
		ranked.insert(insert_at, {"player": player, "wide": wide, "x": field_pos.x})

	var picked: Array[PlayerData] = []
	for entry in ranked:
		if picked.size() >= count:
			break
		var player: PlayerData = entry["player"]
		picked.append(player)
	return picked


## Coordinate dello slot nel modulo attivo, Vector2.ZERO se manca il modulo.
static func _slot_position(team: TeamData, slot: int) -> Vector2:
	if team.current_formation == null:
		return Vector2.ZERO
	return team.current_formation.get_slot_position(slot)


## Equipaggia l'archetipo indicato prendendolo dal GameCatalog e allarga se serve
## gli slot del cartellino, fino al limite di PlayerData.MAX_ARCHETYPE_SLOTS.
static func _equip_archetype(player: PlayerData, archetype_id: String) -> bool:
	if player == null:
		return false
	var archetype := GameCatalog.get_archetype(archetype_id)
	if archetype == null:
		push_warning("TeamGenerator: archetipo '%s' non presente nel catalogo" % archetype_id)
		return false
	if player.archetypes.has(archetype):
		return false
	player.archetypes.append(archetype)
	player.archetype_slots = mini(PlayerData.MAX_ARCHETYPE_SLOTS, maxi(player.archetype_slots, player.archetypes.size()))
	return true
