class_name FormationData
extends Resource

## Licenza tattica: coordinate assolute dei 11 slot in campo (GDD §9).
##
## Cambiare modulo sposta solo le coordinate degli slot: i cartellini dei
## calciatori non vengono toccati.

## Slot disponibili in campo, numerati da 1 (portiere) a 11.
const SLOT_COUNT: int = 11

## Ruoli di movimento nell'ordine in cui il nome del modulo li elenca.
const OUTFIELD_ROLES := ["DIF", "CEN", "ATT"]

## Nome del modulo così come appare a schermo, es. "4-4-2".
@export var formation_name: String = ""

## Mappa slot -> posizione. Chiavi int da 1 a SLOT_COUNT, valori Vector2(x, y)
## sulla griglia pitch 1000x600 (x = 0 linea di fondo propria, x = 1000 porta
## avversaria; y = 0 fascia alta, y = 600 fascia bassa).
@export var slot_coordinates: Dictionary[int, Vector2] = {}


## Coordinate dello slot richiesto, Vector2.ZERO se lo slot non è definito.
func get_slot_position(slot: int) -> Vector2:
	if not slot_coordinates.has(slot):
		return Vector2.ZERO
	return slot_coordinates[slot]


## True se il modulo definisce tutti e 11 gli slot di campo.
func is_complete() -> bool:
	for slot in range(1, SLOT_COUNT + 1):
		if not slot_coordinates.has(slot):
			return false
	return true


## Ruolo atteso per ogni slot, dedotto dal nome del modulo (GDD §9): lo slot 1
## è sempre il portiere, il primo numero del nome conta i difensori, l'ultimo
## gli attaccanti e i numeri intermedi i centrocampisti.
## Es. "4-2-3-1" -> 1 POR, 4 DIF, 5 CEN, 1 ATT.
func get_slot_roles() -> Dictionary[int, String]:
	var counts := _parse_line_counts()
	var roles: Dictionary[int, String] = {}
	roles[1] = "POR"
	var slot := 2
	for index in OUTFIELD_ROLES.size():
		var role: String = OUTFIELD_ROLES[index]
		for _i in counts[index]:
			roles[slot] = role
			slot += 1
	return roles


## Ruolo atteso per un singolo slot, stringa vuota se lo slot non esiste.
func get_slot_role(slot: int) -> String:
	var roles := get_slot_roles()
	if not roles.has(slot):
		return ""
	return roles[slot]


## Difensori, centrocampisti e attaccanti ricavati dal nome del modulo.
## Ricade sul 4-4-2 se il nome non è interpretabile o non somma 10 giocatori
## di movimento.
func _parse_line_counts() -> Array[int]:
	var fallback: Array[int] = [4, 4, 2]
	var parts := formation_name.split("-", false)
	if parts.size() < 3:
		push_warning("FormationData: nome modulo non interpretabile '%s'" % formation_name)
		return fallback
	var numbers: Array[int] = []
	for part in parts:
		if not part.is_valid_int():
			push_warning("FormationData: nome modulo non numerico '%s'" % formation_name)
			return fallback
		numbers.append(part.to_int())
	var defenders := numbers[0]
	var attackers := numbers[numbers.size() - 1]
	var midfielders := 0
	for index in range(1, numbers.size() - 1):
		midfielders += numbers[index]
	if defenders + midfielders + attackers != SLOT_COUNT - 1:
		push_warning("FormationData: il modulo '%s' non somma %d giocatori di movimento" % [formation_name, SLOT_COUNT - 1])
		return fallback
	var counts: Array[int] = [defenders, midfielders, attackers]
	return counts
