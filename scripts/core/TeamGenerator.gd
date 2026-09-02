class_name TeamGenerator
extends RefCounted

## Generatore procedurale di calciatori e rose iniziali (GDD §5 e §7).
##
## Utility interamente statica: non va istanziata né registrata come autoload.
## I cartellini nascono senza archetipi né allenamenti, come previsto per la
## generazione a inizio run.
## [codeblock]
## var team := TeamGenerator.generate_starter_team(GameCatalog.get_formation("4-4-2"))
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
## Se [param formation] è null viene caricato il 4-4-2 dal GameCatalog.
## Restituisce null solo se nemmeno il modulo di default è disponibile.
static func generate_starter_team(formation: FormationData = null, team_name: String = DEFAULT_TEAM_NAME) -> TeamData:
	var used_formation := formation
	if used_formation == null:
		used_formation = GameCatalog.get_formation(DEFAULT_FORMATION)
	if used_formation == null:
		push_error("TeamGenerator: modulo '%s' non presente nel catalogo" % DEFAULT_FORMATION)
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
