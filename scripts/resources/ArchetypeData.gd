class_name ArchetypeData
extends Resource

## Archetipo: tratto unico inseribile in uno slot del cartellino (GDD §10.2).

## Identificativo univoco in snake_case, es. "bomber", "long_shot".
@export var id: String = ""

## Nome mostrato a schermo, es. "Bomber".
@export var name: String = ""

## Testo dell'effetto, mostrato nell'enciclopedia e nel Calcio Mercato.
@export_multiline var description: String = ""
