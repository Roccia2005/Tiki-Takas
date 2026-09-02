class_name GameCatalog
extends RefCounted

## Indice di sola lettura di tutte le risorse dati del gioco (GDD §9, §10).
##
## Utility interamente statica: non va istanziata né registrata come autoload.
## Le risorse vengono indicizzate al primo accesso e mantenute in cache.
## [codeblock]
## var bomber := GameCatalog.get_archetype("bomber")
## var modulo := GameCatalog.get_formation("4-3-3")
## [/codeblock]

const FORMATIONS_DIR := "res://data/formations"
const ARCHETYPES_DIR := "res://data/archetypes"
const TALISMANS_DIR := "res://data/talismans"
const TRAININGS_DIR := "res://data/trainings"

## I moduli sono indicizzati per [member FormationData.formation_name],
## tutto il resto per il proprio campo [code]id[/code].
static var _formations: Dictionary[String, FormationData] = {}
static var _archetypes: Dictionary[String, ArchetypeData] = {}
static var _talismans: Dictionary[String, TalismanData] = {}
static var _trainings: Dictionary[String, TrainingData] = {}
static var _indexed: bool = false


## Modulo tattico corrispondente al nome indicato, es. "4-4-2". Null se assente.
static func get_formation(formation_name: String) -> FormationData:
	_ensure_indexed()
	if not _formations.has(formation_name):
		return null
	return _formations[formation_name]


## Archetipo corrispondente all'id indicato, es. "bomber". Null se assente.
static func get_archetype(id: String) -> ArchetypeData:
	_ensure_indexed()
	if not _archetypes.has(id):
		return null
	return _archetypes[id]


## Talismano corrispondente all'id indicato. Null se assente.
static func get_talisman(id: String) -> TalismanData:
	_ensure_indexed()
	if not _talismans.has(id):
		return null
	return _talismans[id]


## Allenamento corrispondente all'id indicato. Null se assente.
static func get_training(id: String) -> TrainingData:
	_ensure_indexed()
	if not _trainings.has(id):
		return null
	return _trainings[id]


## Tutti i moduli tattici indicizzati, in ordine alfabetico di file.
static func get_all_formations() -> Array[FormationData]:
	_ensure_indexed()
	var list: Array[FormationData] = []
	list.assign(_formations.values())
	return list


## Tutti gli archetipi indicizzati.
static func get_all_archetypes() -> Array[ArchetypeData]:
	_ensure_indexed()
	var list: Array[ArchetypeData] = []
	list.assign(_archetypes.values())
	return list


## Tutti i talismani indicizzati.
static func get_all_talismans() -> Array[TalismanData]:
	_ensure_indexed()
	var list: Array[TalismanData] = []
	list.assign(_talismans.values())
	return list


## Tutti gli allenamenti indicizzati.
static func get_all_trainings() -> Array[TrainingData]:
	_ensure_indexed()
	var list: Array[TrainingData] = []
	list.assign(_trainings.values())
	return list


## Talismani della rarità richiesta (1, 2 o 3 stelle).
static func get_talismans_by_rarity(rarity: int) -> Array[TalismanData]:
	var filtered: Array[TalismanData] = []
	for talisman in get_all_talismans():
		if talisman.rarity == rarity:
			filtered.append(talisman)
	return filtered


## Allenamenti della rarità richiesta (1, 2 o 3 stelle).
static func get_trainings_by_rarity(rarity: int) -> Array[TrainingData]:
	var filtered: Array[TrainingData] = []
	for training in get_all_trainings():
		if training.rarity == rarity:
			filtered.append(training)
	return filtered


## Numero di elementi indicizzati per categoria, utile per diagnostica e test.
static func get_counts() -> Dictionary[String, int]:
	_ensure_indexed()
	var counts: Dictionary[String, int] = {
		"formations": _formations.size(),
		"archetypes": _archetypes.size(),
		"talismans": _talismans.size(),
		"trainings": _trainings.size(),
	}
	return counts


## Ricostruisce l'indice leggendo di nuovo le cartelle in res://data/.
static func reload() -> void:
	_formations.clear()
	_archetypes.clear()
	_talismans.clear()
	_trainings.clear()

	for resource in _load_directory(FORMATIONS_DIR):
		var formation := resource as FormationData
		if formation == null:
			continue
		if _formations.has(formation.formation_name):
			push_warning("GameCatalog: modulo duplicato '%s'" % formation.formation_name)
		_formations[formation.formation_name] = formation

	for resource in _load_directory(ARCHETYPES_DIR):
		var archetype := resource as ArchetypeData
		if archetype == null:
			continue
		if _archetypes.has(archetype.id):
			push_warning("GameCatalog: id archetipo duplicato '%s'" % archetype.id)
		_archetypes[archetype.id] = archetype

	for resource in _load_directory(TALISMANS_DIR):
		var talisman := resource as TalismanData
		if talisman == null:
			continue
		if _talismans.has(talisman.id):
			push_warning("GameCatalog: id talismano duplicato '%s'" % talisman.id)
		_talismans[talisman.id] = talisman

	for resource in _load_directory(TRAININGS_DIR):
		var training := resource as TrainingData
		if training == null:
			continue
		if _trainings.has(training.id):
			push_warning("GameCatalog: id allenamento duplicato '%s'" % training.id)
		_trainings[training.id] = training

	_indexed = true


static func _ensure_indexed() -> void:
	if not _indexed:
		reload()


## Carica tutte le risorse .tres di una cartella in ordine alfabetico.
## Gestisce anche i .remap generati quando le risorse testuali vengono
## convertite in binario durante l'esportazione del progetto.
static func _load_directory(dir_path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("GameCatalog: cartella dati non trovata: %s" % dir_path)
		return resources

	var file_names := dir.get_files()
	file_names.sort()
	for file_name in file_names:
		var tres_name := file_name.trim_suffix(".remap")
		if not tres_name.ends_with(".tres"):
			continue
		var resource := ResourceLoader.load(dir_path.path_join(tres_name))
		if resource == null:
			push_warning("GameCatalog: risorsa non caricabile: %s" % tres_name)
			continue
		resources.append(resource)
	return resources
