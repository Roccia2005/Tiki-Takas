class_name TeamData
extends Resource

## Rosa completa di una squadra: cartellini, undici titolare e modulo in uso
## (GDD §5 - "La Rosa: Titolari, Panchina e Sostituzioni").
##
## [member players] elenca tutti i cartellini posseduti, [member lineup] associa
## gli slot 1-11 del modulo ai titolari. I panchinari non sono un campo a sé:
## sono per definizione i giocatori in rosa che non occupano alcuno slot.
## [codeblock]
## var team := TeamGenerator.generate_starter_team(GameCatalog.get_formation("4-4-2"))
## print(team.is_lineup_valid())     # true
## print(team.get_bench().size())    # 0, la panchina parte vuota
## [/codeblock]

## Slot schierabili in campo, uno per ogni titolare (GDD §4).
const LINEUP_SIZE: int = 11

## Capienza massima della panchina (GDD §5): vuota a inizio partita.
const MAX_BENCH: int = 3

## Nome della squadra scelta a inizio run, es. "Standard" (GDD §2.3).
@export var team_name: String = ""

## Tutti i cartellini della rosa, titolari e riserve insieme.
@export var players: Array[PlayerData] = []

## Slot del modulo (1-11) -> titolare che lo occupa.
@export var lineup: Dictionary[int, PlayerData] = {}

## Modulo tattico attivo, da cui provengono le coordinate degli slot (GDD §9).
@export var current_formation: FormationData = null

## Talismani equipaggiati dalla squadra, al massimo TalismanData.MAX_EQUIPPED
## (GDD §10). Tipizzato Array[Resource] per non legare questa risorsa a
## TalismanData: gli elementi attesi sono comunque TalismanData.
@export var talismans: Array[Resource] = []


## Schiera [param player] nello slot indicato e lo registra in rosa se non c'è
## già. Se il giocatore occupava un altro slot, quello viene liberato: un
## cartellino non può stare in due posizioni contemporaneamente.
## Restituisce false se lo slot è fuori dall'intervallo 1-11 o se player è null.
func set_starter(slot: int, player: PlayerData) -> bool:
	if not is_valid_slot(slot):
		push_warning("TeamData: slot %d fuori dall'intervallo 1-%d" % [slot, LINEUP_SIZE])
		return false
	if player == null:
		push_warning("TeamData: impossibile schierare un cartellino null nello slot %d" % slot)
		return false
	if not players.has(player):
		players.append(player)
	var previous := find_slot(player)
	if previous != -1 and previous != slot:
		lineup.erase(previous)
	lineup[slot] = player
	return true


## Titolare che occupa lo slot indicato, null se lo slot è vuoto o non valido.
func get_starter(slot: int) -> PlayerData:
	if not lineup.has(slot):
		return null
	return lineup[slot]


## True se tutti e 11 gli slot sono occupati da cartellini distinti e presenti
## in rosa, senza chiavi estranee all'intervallo 1-11.
func is_lineup_valid() -> bool:
	if lineup.size() != LINEUP_SIZE:
		return false
	var seen: Array[PlayerData] = []
	for slot in range(1, LINEUP_SIZE + 1):
		if not lineup.has(slot):
			return false
		var player: PlayerData = lineup[slot]
		if player == null:
			return false
		if seen.has(player):
			return false
		if not players.has(player):
			return false
		seen.append(player)
	return true


## Libera lo slot indicato: il giocatore resta in rosa e finisce in panchina.
## False se lo slot era già vuoto.
func clear_slot(slot: int) -> bool:
	if not lineup.has(slot):
		return false
	lineup.erase(slot)
	return true


## Slot occupato da [param player], -1 se il giocatore non è schierato.
func find_slot(player: PlayerData) -> int:
	if player == null:
		return -1
	for slot in lineup:
		if lineup[slot] == player:
			return slot
	return -1


## Giocatori in rosa che non occupano alcuno slot in campo (GDD §5).
func get_bench() -> Array[PlayerData]:
	var bench: Array[PlayerData] = []
	for player in players:
		if player == null:
			continue
		if find_slot(player) == -1:
			bench.append(player)
	return bench


## True se la panchina non ha ancora raggiunto i MAX_BENCH posti (GDD §5).
func has_bench_space() -> bool:
	return get_bench().size() < MAX_BENCH


## True se la squadra può equipaggiare un altro talismano (GDD §10).
func has_talisman_space() -> bool:
	return talismans.size() < TalismanData.MAX_EQUIPPED


## Talismano equipaggiato con l'id indicato, null se la squadra non ce l'ha.
func find_talisman(id: String) -> TalismanData:
	for entry in talismans:
		var talisman := entry as TalismanData
		if talisman != null and talisman.id == id:
			return talisman
	return null


## Azzera il contatore tocchi di tutta la rosa: va invocato a ogni tiro in
## porta (GDD §4, rendimento decrescente sui passaggi multipli).
func reset_all_touches() -> void:
	for player in players:
		if player == null:
			continue
		player.reset_action_touches()


## True se il numero di slot è schierabile, cioè compreso fra 1 e LINEUP_SIZE.
static func is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= LINEUP_SIZE
