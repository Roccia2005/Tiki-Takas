class_name TalismanData
extends Resource

## Talismano: modificatore passivo permanente per l'intera squadra (GDD §10.1).

## Talismani equipaggiabili contemporaneamente dalla squadra (GDD §10).
const MAX_EQUIPPED: int = 5

## Identificativo univoco in snake_case, es. "talismano_possesso".
@export var id: String = ""

## Nome mostrato a schermo, es. "Talismano Possesso".
@export var name: String = ""

## Testo dell'effetto, mostrato nell'enciclopedia e nel Calcio Mercato.
@export_multiline var description: String = ""

## Rarità in stelle: 1 (★), 2 (★★) oppure 3 (★★★).
@export_range(1, 3) var rarity: int = 1

## Costo in Football Coins al Calcio Mercato: 5 / 7 / 15 secondo la rarità.
@export var cost: int = 5
