class_name BossData
extends Resource

## Boss di coppa: l'avversario del terzo match di ogni Ante, con il malus
## passivo che affligge il giocatore per tutta la partita (GDD §3, §8).
##
## Risorsa di soli dati: il malus è identificato da [member special_rule], che
## il livello di partita interpreta. I due soli malus che agiscono già durante
## il setup del match, cioè i punti parata maggiorati e i passaggi tagliati,
## sono esposti anche come valori numerici pronti all'uso.
## [codeblock]
## var boss := GameCatalog.get_boss("portiere_saracinesca")
## print(boss.apply_to_save_points(60000.0))  # 90000.0, GDD §8 +50%
## [/codeblock]

## Ante presidiabili da un boss: il mondiale ne conta 6 (GDD §3).
const MIN_CUP_LEVEL: int = 1
const MAX_CUP_LEVEL: int = 6

## GDD §8 (Pressing Asfissiante): passaggi minimi garantiti dopo il taglio.
const MIN_PASSES: int = 1

## Identificativo univoco in snake_case, es. "il_bunker".
@export var id: String = ""

## Nome mostrato a schermo, es. "Il Bunker".
@export var boss_name: String = ""

## Ante a cui il boss è assegnato, da MIN_CUP_LEVEL a MAX_CUP_LEVEL.
@export_range(1, 6) var cup_level: int = 1

## Identificativo del malus d'anta, letto dal livello di partita per applicare
## l'effetto meccanico del GDD §8, es. "long_range_penalty".
@export var special_rule: String = ""

## Testo del malus, mostrato in partita e nell'enciclopedia.
@export_multiline var description: String = ""

## GDD §8: moltiplicatore dei punti parata di tabella. Vale 1.0 per tutti i boss
## tranne il Portiere Saracinesca, che li porta a +50%.
@export var save_points_multiplier: float = 1.0

## GDD §8: variazione secca dei passaggi concessi per la partita. Vale 0 per
## tutti i boss tranne il Pressing Asfissiante, che ne toglie 2.
@export var pass_modifier: int = 0

## Modulo con cui il boss si schiera (GDD §9).
@export var formation: FormationData = null

## Rosa avversaria prefissata. Se resta null, chi avvia la partita ne genera una
## proceduralmente con TeamGenerator sul modulo del boss.
@export var base_team: TeamData = null


## Punti parata effettivi del boss, partendo dal valore di tabella del GDD §7.
func apply_to_save_points(base_save_points: float) -> float:
	return maxf(0.0, base_save_points * save_points_multiplier)


## Passaggi disponibili dopo il malus, mai sotto MIN_PASSES (GDD §8).
func apply_to_passes(base_passes: int) -> int:
	if pass_modifier == 0:
		return base_passes
	return maxi(MIN_PASSES, base_passes + pass_modifier)


## True se il boss ha un id ed è assegnato a un'Ante esistente (GDD §3).
func is_valid() -> bool:
	return id != "" and cup_level >= MIN_CUP_LEVEL and cup_level <= MAX_CUP_LEVEL
