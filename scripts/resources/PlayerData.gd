class_name PlayerData
extends Resource

## Cartellino dati di un singolo calciatore (GDD §5 - "La Rosa").
##
## Risorsa di soli dati e calcoli puri: non conosce nodi, scene o UI.
## Le pedine in campo si limiteranno a leggere/scrivere questa risorsa.

## Limiti anagrafici validi per qualsiasi giocatore generato (GDD §7).
const MIN_AGE: int = 17
const MAX_AGE: int = 40

## Numero massimo di slot archetipo che un cartellino può arrivare a ospitare.
const MAX_ARCHETYPE_SLOTS: int = 5

## Ruoli ammessi, ordinati dalla porta all'attacco.
const ROLES := ["POR", "DIF", "CEN", "ATT"]

## Rendimento decrescente sui tocchi multipli nella stessa azione (GDD §4).
const FIRST_TOUCH_MULTIPLIER: float = 1.0
const SECOND_TOUCH_MULTIPLIER: float = 0.5
const EXTRA_TOUCH_MULTIPLIER: float = 0.25

@export var player_name: String = ""

## Età del calciatore, sempre compresa tra MIN_AGE e MAX_AGE.
@export_range(17, 40) var age: int = 17

## Ruolo tattico: "POR", "DIF", "CEN" oppure "ATT".
@export_enum("POR", "DIF", "CEN", "ATT") var role: String = "POR"

## Forza/Potenza base che il giocatore versa nella Potenza Azione a ogni tocco.
@export var power: int = 0

## Gittata in unità pitch (scala 0-1000) entro cui passa o tira senza perdite.
@export var range_dist: float = 0.0

## Quanti archetipi il cartellino può tenere equipaggiati insieme (0-5).
@export_range(0, 5) var archetype_slots: int = 0

## Archetipi equipaggiati. Tipizzato Array[Resource] per non legare questa
## risorsa ad ArchetypeData: gli elementi attesi sono comunque ArchetypeData.
@export var archetypes: Array[Resource] = []

## Allenamenti già applicati al cartellino (GDD §5): sono cumulabili
## all'infinito. Tipizzato Array[Resource] per non legare questa risorsa a
## TrainingData: gli elementi attesi sono comunque TrainingData.
@export var trainings: Array[Resource] = []

## Tocchi già completati da questo giocatore nell'azione in corso.
## Stato di runtime, non serializzato: si azzera a ogni tiro in porta.
var touches_in_action: int = 0


## Moltiplicatore di rendimento del tocco che il giocatore sta eseguendo ora:
## 100% al primo tocco dell'azione, 50% al secondo, 25% dal terzo in avanti.
func get_touch_multiplier() -> float:
	if touches_in_action <= 0:
		return FIRST_TOUCH_MULTIPLIER
	if touches_in_action == 1:
		return SECOND_TOUCH_MULTIPLIER
	return EXTRA_TOUCH_MULTIPLIER


## Forza effettivamente trasferita alla Potenza Azione con il tocco corrente,
## già scalata dal rendimento decrescente.
func get_effective_power() -> float:
	return float(power) * get_touch_multiplier()


## Registra il tocco appena eseguito e restituisce il contributo di Forza
## di quel tocco, incrementando il contatore per i tocchi successivi.
func register_touch() -> float:
	var contribution: float = get_effective_power()
	touches_in_action += 1
	return contribution


## Azzera il contatore dei tocchi individuali: va invocata su tutti gli 11
## giocatori subito dopo un tiro in porta (GDD §4).
func reset_action_touches() -> void:
	touches_in_action = 0
