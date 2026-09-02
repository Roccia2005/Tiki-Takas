class_name FormationData
extends Resource

## Licenza tattica: coordinate assolute dei 11 slot in campo (GDD §9).
##
## Cambiare modulo sposta solo le coordinate degli slot: i cartellini dei
## calciatori non vengono toccati.

## Slot disponibili in campo, numerati da 1 (portiere) a 11.
const SLOT_COUNT: int = 11

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
