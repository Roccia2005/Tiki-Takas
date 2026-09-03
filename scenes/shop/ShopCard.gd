class_name ShopCard
extends Control

## Un singolo slot della vetrina del Calcio Mercato (GDD §6 e §6.1).
##
## Disegna il cartellino, il talismano o l'allenamento esposto con rarità,
## effetto e costo in Football Coins, e pubblica il pulsante di acquisto. Non
## conosce budget né rosa: ShopView gli comunica se l'acquisto è possibile e
## ShopManager resta l'unico proprietario delle formule (GDD §6.1, §10).

## Tipo di articolo esposto nello slot (GDD §6.1).
enum Kind {
	PLAYER,
	TALISMAN,
	TRAINING,
}

## Etichette dei tipi, allineate all'ordine di Kind.
const KIND_NAMES := ["CALCIATORE", "TALISMANO", "ALLENAMENTO"]

const CARD_SIZE := Vector2(285.0, 336.0)
const KIND_RECT := Rect2(14.0, 8.0, 160.0, 22.0)
const COST_RECT := Rect2(165.0, 6.0, 106.0, 28.0)
const NAME_RECT := Rect2(14.0, 36.0, 257.0, 32.0)
const META_RECT := Rect2(14.0, 70.0, 257.0, 24.0)
const STATS_RECT := Rect2(14.0, 96.0, 257.0, 22.0)
const BODY_RECT := Rect2(14.0, 124.0, 257.0, 122.0)
const STATUS_RECT := Rect2(14.0, 250.0, 257.0, 24.0)
const BUY_RECT := Rect2(14.0, 280.0, 257.0, 44.0)
const RULE_Y: float = 118.0

## Richiesta di acquisto di questo slot, gestita da ShopView.
signal buy_requested(card: ShopCard)

## Tipo di articolo, da Kind.
var kind: int = Kind.PLAYER

## Articolo esposto: PlayerData, TalismanData oppure TrainingData.
var item: Resource = null

## Prezzo in Football Coins calcolato da ShopManager (GDD §6.1).
var cost: int = 0

## True quando lo slot è stato acquistato in questa visita al mercato.
var spent: bool = false

var _kind_label: Label = null
var _cost_label: Label = null
var _name_label: Label = null
var _meta_label: Label = null
var _stats_label: Label = null
var _body_label: Label = null
var _status_label: Label = null
var _buy_button: Button = null
var _tint: Color = UIStyle.ACCENT


func _ready() -> void:
	size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()
	_apply_item()


## Espone un articolo nello slot: tipo, risorsa e prezzo già calcolato.
func setup(item_kind: int, resource_item: Resource, item_cost: int) -> void:
	kind = item_kind
	item = resource_item
	cost = maxi(0, item_cost)
	spent = false
	_apply_item()


## Abilita o blocca l'acquisto spiegando il motivo del rifiuto (GDD §6.1).
func set_availability(affordable: bool, reason: String = "") -> void:
	if _buy_button == null:
		return
	if spent or item == null:
		return
	_buy_button.disabled = not affordable
	_status_label.text = reason.to_upper()
	_status_label.add_theme_color_override("font_color", UIStyle.TEXT_DIM if affordable else UIStyle.WARN)


## Segna lo slot come esaurito: l'articolo è stato ritirato dalla vetrina.
func mark_spent(text: String = "ACQUISTATO") -> void:
	spent = true
	if _buy_button != null:
		_buy_button.disabled = true
		_buy_button.text = text
	if _status_label != null:
		_status_label.text = ""
	queue_redraw()


## Nome leggibile dell'articolo, vuoto se lo slot non espone nulla.
func get_item_name() -> String:
	if item == null:
		return ""
	if kind == Kind.PLAYER:
		var card := item as PlayerData
		return card.player_name if card != null else ""
	if kind == Kind.TALISMAN:
		var talisman := item as TalismanData
		return talisman.name if talisman != null else ""
	var training := item as TrainingData
	return training.name if training != null else ""


func _draw() -> void:
	var body := Rect2(Vector2.ZERO, CARD_SIZE)
	var fill: Color = UIStyle.CARD_SPENT if spent else UIStyle.CARD_FILL
	var edge := Color(_tint.r, _tint.g, _tint.b, 0.20 if spent else 0.55)
	UIStyle.draw_panel(self, body, fill, edge, 2.0)
	draw_rect(Rect2(0.0, 0.0, CARD_SIZE.x, 4.0), Color(_tint.r, _tint.g, _tint.b, 0.20 if spent else 0.9), true)
	UIStyle.draw_rule(self, Vector2(14.0, RULE_Y), Vector2(CARD_SIZE.x - 14.0, RULE_Y), Color(_tint.r, _tint.g, _tint.b, 0.25))


## Riscrive le etichette sull'articolo corrente e ricolora lo slot per tipo.
func _apply_item() -> void:
	if _name_label == null:
		return
	_tint = _kind_tint()
	_kind_label.text = KIND_NAMES[clampi(kind, 0, KIND_NAMES.size() - 1)]
	_kind_label.add_theme_color_override("font_color", _tint)
	_cost_label.text = "%d FC" % cost
	_buy_button.text = "COMPRA"
	_buy_button.disabled = item == null
	_status_label.text = ""
	if item == null:
		_name_label.text = "SLOT ESAURITO"
		_meta_label.text = ""
		_stats_label.text = ""
		_body_label.text = ""
		_cost_label.text = ""
		queue_redraw()
		return
	_name_label.text = get_item_name()
	match kind:
		Kind.PLAYER:
			_apply_player(item as PlayerData)
		Kind.TALISMAN:
			_apply_talisman(item as TalismanData)
		_:
			_apply_training(item as TrainingData)
	queue_redraw()


## Cartellino calciatore: ruolo, età, Forza, Gittata e slot archetipi (GDD §5).
func _apply_player(card: PlayerData) -> void:
	if card == null:
		return
	_meta_label.text = "%s   ·   %d anni   ·   %d/%d slot" % [card.role, card.age, card.archetypes.size(), card.archetype_slots]
	_meta_label.add_theme_color_override("font_color", UIStyle.role_color(card.role))
	_stats_label.text = "Forza %d      Gittata %.0f" % [card.power, card.range_dist]
	var lines: Array[String] = []
	for entry in card.archetypes:
		var archetype := entry as ArchetypeData
		if archetype != null:
			lines.append("%s: %s" % [archetype.name, archetype.description])
	if lines.is_empty():
		lines.append("Nessun archetipo equipaggiato: gli slot liberi si riempiono al mercato (GDD §6).")
	_body_label.text = "\n".join(lines)


## Talismano: rarità in stelle ed effetto passivo di squadra (GDD §10.1).
func _apply_talisman(talisman: TalismanData) -> void:
	if talisman == null:
		return
	_meta_label.text = "%s   ·   talismano di squadra" % UIStyle.stars(talisman.rarity)
	_meta_label.add_theme_color_override("font_color", UIStyle.GOLD)
	_stats_label.text = "Massimo %d equipaggiati" % TalismanData.MAX_EQUIPPED
	_body_label.text = talisman.description


## Allenamento: rarità in stelle ed effetto permanente sul cartellino (GDD §10.3).
func _apply_training(training: TrainingData) -> void:
	if training == null:
		return
	_meta_label.text = "%s   ·   card consumabile" % UIStyle.stars(training.rarity)
	_meta_label.add_theme_color_override("font_color", UIStyle.INFO)
	_stats_label.text = "Cumulabile all'infinito"
	_body_label.text = training.description


## Colore guida dello slot in base al tipo di articolo esposto.
func _kind_tint() -> Color:
	match kind:
		Kind.PLAYER:
			return UIStyle.ACCENT
		Kind.TALISMAN:
			return UIStyle.GOLD
		_:
			return UIStyle.INFO


## Costruisce etichette e pulsante dello slot: nessun asset esterno (GDD §12).
func _build() -> void:
	_kind_label = UIStyle.make_label("", KIND_RECT, 15, UIStyle.ACCENT)
	_cost_label = UIStyle.make_label("", COST_RECT, 22, UIStyle.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	_name_label = UIStyle.make_label("", NAME_RECT, 22, UIStyle.TEXT_MAIN)
	_meta_label = UIStyle.make_label("", META_RECT, 16, UIStyle.TEXT_DIM)
	_stats_label = UIStyle.make_label("", STATS_RECT, 17, UIStyle.TEXT_MAIN)
	_body_label = UIStyle.make_paragraph("", BODY_RECT, 14, UIStyle.TEXT_DIM)
	_status_label = UIStyle.make_label("", STATUS_RECT, 14, UIStyle.WARN)
	var labels: Array[Label] = [_kind_label, _cost_label, _name_label, _meta_label, _stats_label, _body_label, _status_label]
	for label in labels:
		add_child(label)
	_buy_button = UIStyle.make_button("COMPRA", BUY_RECT, 19, UIStyle.ACCENT)
	_buy_button.pressed.connect(_on_buy_pressed)
	add_child(_buy_button)


func _on_buy_pressed() -> void:
	if spent or item == null:
		return
	buy_requested.emit(self)
