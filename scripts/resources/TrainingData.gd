class_name TrainingData
extends Resource

## Allenamento: card consumabile che potenzia in modo permanente un singolo
## calciatore (GDD §10.3). Gli allenamenti sono cumulabili all'infinito.

## Identificativo univoco in snake_case, es. "bulk_up", "compleanno".
@export var id: String = ""

## Nome mostrato a schermo, es. "Bulk-Up".
@export var name: String = ""

## Testo dell'effetto, mostrato nell'enciclopedia e nel Calcio Mercato.
@export_multiline var description: String = ""

## Rarità in stelle: 1 (★), 2 (★★) oppure 3 (★★★).
@export_range(1, 3) var rarity: int = 1

## Costo in Football Coins al Calcio Mercato: 5 / 7 / 15 secondo la rarità.
@export var cost: int = 5
