class_name ShopView
extends Control

## Schermata del Calcio Mercato e della gestione rosa (GDD §6, §6.1 e §10).
##
## Riceve l'istanza di [GameManager] della run e mostra la vetrina generata da
## [ShopManager]: 3 cartellini, 2 talismani e 1 allenamento. Acquisti, cessioni
## e reroll passano sempre dai metodi del core, unico proprietario di prezzi e
## regole: qui si legge il budget, si disegnano le carte e si inoltrano i clic.
## Il pulsante "Scendi in Campo" chiude la visita ed emette
## [signal next_match_requested].

## Richiesta di lasciare il mercato e giocare il match successivo (GDD §3).
signal next_match_requested

## Composizione della vetrina, allineata a [method ShopManager.generate_offer].
const OFFER_PLAYERS: int = ShopManager.OFFER_PLAYERS
const OFFER_TALISMANS: int = ShopManager.OFFER_TALISMANS
const OFFER_TRAININGS: int = ShopManager.OFFER_TRAININGS
const SLOT_COUNT: int = OFFER_PLAYERS + OFFER_TALISMANS + OFFER_TRAININGS

## Riquadri del layout in coordinate di design 1920x1080 (GDD §12).
const HEADER_PANEL := Rect2(40.0, 22.0, 1840.0, 96.0)
const ROSTER_PANEL := Rect2(40.0, 540.0, 1840.0, 460.0)
const STATUS_PANEL := Rect2(40.0, 1008.0, 1840.0, 48.0)
const CARD_ORIGIN := Vector2(46.0, 138.0)
const CARD_STRIDE: float = 308.0
const SELECT_ROW_Y: float = 488.0
const STARTER_ORIGIN := Vector2(58.0, 604.0)
const STARTER_SIZE := Vector2(296.0, 62.0)
const STARTER_STRIDE := Vector2(302.0, 68.0)
const STARTER_COLUMNS: int = 6
const BENCH_ORIGIN := Vector2(58.0, 776.0)
const BENCH_SIZE := Vector2(424.0, 104.0)
const BENCH_STRIDE: float = 436.0
const STARTER_RULE_Y: float = 596.0
const BENCH_RULE_Y: float = 766.0

## Partita da giocare dopo il mercato, mostrata sul pulsante di uscita.
const PLAY_LABEL := "SCENDI IN CAMPO"

## Run osservata dalla schermata.
var run: GameManager = null

var _budget_label: Label = null
var _context_label: Label = null
var _status_label: Label = null
var _talisman_label: Label = null
var _target_option: OptionButton = null
var _role_option: OptionButton = null
var _reroll_button: Button = null
var _play_button: Button = null
var _cards: Array[ShopCard] = []
var _starter_labels: Array[Label] = []
var _bench_labels: Array[Label] = []
var _bench_buttons: Array[Button] = []
var _targets: Array[PlayerData] = []
var _bench_slots: Array[PlayerData] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	refresh()


## Collega la run in corso: se la vetrina è vuota ne genera una nuova, così la
## schermata resta utilizzabile anche aperta a mano (GDD §6).
func bind_run(game_run: GameManager) -> void:
	run = game_run
	if run != null and run.current_shop_offer.is_empty():
		run.generate_shop_offer()
	_set_status("Spendi i Football Coins prima del prossimo match", UIStyle.TEXT_DIM)
	refresh()


## Riscrive tutta la schermata leggendo budget, vetrina e rosa dal core.
func refresh() -> void:
	if _budget_label == null:
		return
	if run == null:
		_budget_label.text = "-- FC"
		_context_label.text = "Nessuna run collegata"
		return
	_budget_label.text = "%d FC" % run.budget
	_context_label.text = _build_context()
	var reroll_cost := run.get_reroll_cost()
	_reroll_button.text = "REROLL   -%d FC" % reroll_cost
	_reroll_button.disabled = reroll_cost > run.budget
	_play_button.text = PLAY_LABEL
	_refresh_offer()
	_refresh_targets()
	_refresh_roster()
	_refresh_availability()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, UIStyle.DESIGN_SIZE), UIStyle.BACKDROP, true)
	UIStyle.draw_panel(self, HEADER_PANEL)
	UIStyle.draw_panel(self, ROSTER_PANEL)
	UIStyle.draw_panel(self, STATUS_PANEL)
	UIStyle.draw_rule(self, Vector2(58.0, STARTER_RULE_Y), Vector2(1862.0, STARTER_RULE_Y))
	UIStyle.draw_rule(self, Vector2(58.0, BENCH_RULE_Y), Vector2(1862.0, BENCH_RULE_Y))


## Riga di contesto: Ante, match, dimensione della rosa e posti in panchina.
func _build_context() -> String:
	var bench_used := 0
	var roster := 0
	if run.player_team != null:
		bench_used = run.player_team.get_bench().size()
		roster = run.player_team.players.size()
	var next_cup := run.current_cup
	var next_match := run.current_match_index + 1
	if next_match > GameManager.MATCHES_PER_CUP:
		next_match = 1
		next_cup = mini(GameManager.LAST_CUP, next_cup + 1)
	return "Prossimo: Ante %d/%d   ·   match %d/%d   ·   rosa %d   ·   panchina %d/%d   ·   reroll pagati %d" % [next_cup, GameManager.LAST_CUP, next_match, GameManager.MATCHES_PER_CUP, roster, bench_used, TeamData.MAX_BENCH, run.shop_rerolls]


## Riporta i sei slot sulla vetrina corrente: gli articoli acquistati sono già
## stati rimossi dal core, quindi lo slot in coda resta vuoto (GDD §6.1).
func _refresh_offer() -> void:
	var offer := run.current_shop_offer
	var players: Array = offer.get("players", [])
	var talismans: Array = offer.get("talismans", [])
	var trainings: Array = offer.get("trainings", [])
	for index in _cards.size():
		var card := _cards[index]
		var kind := _kind_of_slot(index)
		var item: Resource = null
		match kind:
			ShopCard.Kind.PLAYER:
				item = _pick(players, index)
			ShopCard.Kind.TALISMAN:
				item = _pick(talismans, index - OFFER_PLAYERS)
			_:
				item = _pick(trainings, index - OFFER_PLAYERS - OFFER_TALISMANS)
		card.setup(kind, item, _cost_of(kind, item))


## Tipo di articolo atteso dallo slot indicato.
func _kind_of_slot(index: int) -> int:
	if index < OFFER_PLAYERS:
		return ShopCard.Kind.PLAYER
	if index < OFFER_PLAYERS + OFFER_TALISMANS:
		return ShopCard.Kind.TALISMAN
	return ShopCard.Kind.TRAINING


## Elemento della lista se esiste, null se lo slot è esaurito.
func _pick(pool: Array, index: int) -> Resource:
	if index < 0 or index >= pool.size():
		return null
	return pool[index]


## Prezzo dello slot: i cartellini lo ricavano dalla formula del GDD §6.1, gli
## altri articoli dal costo scritto nella risorsa (GDD §10).
func _cost_of(kind: int, item: Resource) -> int:
	if item == null:
		return 0
	if kind == ShopCard.Kind.PLAYER:
		return ShopManager.get_player_cost(item as PlayerData)
	if kind == ShopCard.Kind.TALISMAN:
		var talisman := item as TalismanData
		return talisman.cost if talisman != null else 0
	var training := item as TrainingData
	return training.cost if training != null else 0


## Abilita o blocca ogni slot spiegando il motivo: budget, posti in panchina,
## talismani al completo o bersaglio dell'allenamento mancante (GDD §6.1, §10).
func _refresh_availability() -> void:
	for card in _cards:
		if card.item == null:
			continue
		card.set_availability(_refusal(card).is_empty(), _refusal(card))


## Motivo che impedisce l'acquisto dello slot, stringa vuota se è comprabile.
func _refusal(card: ShopCard) -> String:
	var team := run.player_team
	if card.cost > run.budget:
		return "servono %d FC" % card.cost
	if team == null:
		return "rosa non valida"
	match card.kind:
		ShopCard.Kind.PLAYER:
			if not team.has_bench_space():
				return "panchina piena (%d)" % TeamData.MAX_BENCH
		ShopCard.Kind.TALISMAN:
			var talisman := card.item as TalismanData
			if talisman != null and team.find_talisman(talisman.id) == null and not team.has_talisman_space():
				return "talismani al completo (%d)" % TalismanData.MAX_EQUIPPED
		_:
			if _selected_target() == null:
				return "scegli il bersaglio"
	return ""


## Acquisto richiesto da uno slot: il core decide, la schermata riferisce.
func _on_buy_requested(card: ShopCard) -> void:
	if run == null or card.item == null:
		return
	var result := {}
	match card.kind:
		ShopCard.Kind.PLAYER:
			result = run.buy_player(card.item as PlayerData)
		ShopCard.Kind.TALISMAN:
			result = run.buy_talisman(card.item as TalismanData)
		_:
			var target := _selected_target()
			if target == null:
				_set_status("Scegli il giocatore da allenare", UIStyle.WARN)
				return
			result = run.buy_training(card.item as TrainingData, target, _selected_role())
	var label := card.get_item_name()
	if bool(result.get("success", false)):
		_set_status("%s acquistato per %d FC" % [label, int(result.get("cost", 0))], UIStyle.ACCENT)
	else:
		_set_status("%s: %s" % [label, str(result.get("reason", "acquisto rifiutato"))], UIStyle.DANGER)
	refresh()


## Cessione di un panchinaro: il ricavo arriva dalla formula del GDD §10.
func _on_sell_pressed(index: int) -> void:
	if run == null or index < 0 or index >= _bench_slots.size():
		return
	var card := _bench_slots[index]
	var result := run.sell_player(card)
	if bool(result.get("success", false)):
		_set_status("%s venduto per %d FC" % [card.player_name, int(result.get("revenue", 0))], UIStyle.GOLD)
	else:
		_set_status(str(result.get("reason", "cessione rifiutata")), UIStyle.DANGER)
	refresh()


## Reroll della vetrina a costo progressivo (GDD §6.1).
func _on_reroll_pressed() -> void:
	if run == null:
		return
	var result := run.reroll_shop_offer()
	if bool(result.get("success", false)):
		_set_status("Vetrina rimescolata per %d FC" % int(result.get("cost", 0)), UIStyle.INFO)
	else:
		_set_status(str(result.get("reason", "reroll rifiutato")), UIStyle.DANGER)
	refresh()


## Uscita dal mercato: la transizione al match spetta a [Main].
func _on_play_pressed() -> void:
	next_match_requested.emit()


## Rigenera la lista dei bersagli dell'allenamento conservando la scelta.
func _refresh_targets() -> void:
	var previous := _selected_target()
	_targets.clear()
	_target_option.clear()
	if run.player_team == null:
		_target_option.disabled = true
		return
	for card in run.player_team.players:
		_targets.append(card)
		var slot := run.player_team.find_slot(card)
		var place := "panchina" if slot < 1 else "titolare %02d" % slot
		_target_option.add_item("%s   %s   F%d   %s" % [card.player_name, card.role, card.power, place])
	_target_option.disabled = _targets.is_empty()
	if _targets.is_empty():
		return
	_target_option.selected = maxi(0, _targets.find(previous))


## Cartellino selezionato per l'allenamento, null se la rosa è vuota.
func _selected_target() -> PlayerData:
	if _target_option == null or _targets.is_empty():
		return null
	var index := _target_option.selected
	if index < 0 or index >= _targets.size():
		return null
	return _targets[index]


## Ruolo di destinazione della Masterclass Tattica, ignorato dagli altri
## allenamenti (GDD §10.3).
func _selected_role() -> String:
	if _role_option == null:
		return ""
	var index := _role_option.selected
	if index < 0 or index >= PlayerData.ROLES.size():
		return ""
	return str(PlayerData.ROLES[index])


## Riscrive titolari, panchina e talismani equipaggiati con i valori di
## cessione calcolati da [ShopManager] (GDD §10).
func _refresh_roster() -> void:
	var team := run.player_team
	for slot in range(1, TeamData.LINEUP_SIZE + 1):
		var label := _starter_labels[slot - 1]
		var starter: PlayerData = team.get_starter(slot) if team != null else null
		if starter == null:
			label.text = "%02d   slot vuoto" % slot
			label.add_theme_color_override("font_color", UIStyle.TEXT_DIM)
			continue
		label.text = "%02d  %s\n%s   Forza %d   Gittata %.0f   cessione %d FC" % [slot, starter.player_name, starter.role, starter.power, starter.range_dist, ShopManager.get_sell_value(starter, team)]
		label.add_theme_color_override("font_color", UIStyle.role_color(starter.role))
	_bench_slots.clear()
	if team != null:
		_bench_slots = team.get_bench()
	for index in _bench_labels.size():
		var label := _bench_labels[index]
		var button := _bench_buttons[index]
		if index >= _bench_slots.size():
			label.text = "PANCHINA LIBERA\nacquista un cartellino dalla vetrina"
			label.add_theme_color_override("font_color", UIStyle.TEXT_DIM)
			button.text = "VENDI"
			button.disabled = true
			continue
		var card := _bench_slots[index]
		var value := ShopManager.get_sell_value(card, team)
		label.text = "%s\n%s   %d anni   Forza %d   Gittata %.0f" % [card.player_name, card.role, card.age, card.power, card.range_dist]
		label.add_theme_color_override("font_color", UIStyle.role_color(card.role))
		button.text = "VENDI  +%d FC" % value
		button.disabled = false
	_talisman_label.text = _build_talisman_text(team)


## Elenco dei talismani attivi con rarità, per ricordare gli slot residui.
func _build_talisman_text(team: TeamData) -> String:
	if team == null:
		return "TALISMANI\nrosa non valida"
	var lines := "TALISMANI  %d/%d\n" % [team.talismans.size(), TalismanData.MAX_EQUIPPED]
	if team.talismans.is_empty():
		return lines + "nessun talismano equipaggiato"
	for entry in team.talismans:
		var talisman := entry as TalismanData
		if talisman == null:
			continue
		lines += "%s  %s\n" % [UIStyle.stars(talisman.rarity), talisman.name]
	return lines


## Messaggio di esito nella barra di stato in fondo alla schermata.
func _set_status(text: String, color: Color = UIStyle.TEXT_DIM) -> void:
	if _status_label == null:
		return
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", color)


## Costruisce l'intera interfaccia da codice: nessun asset e nessun file .tres.
func _build() -> void:
	_budget_label = UIStyle.make_label("-- FC", Rect2(60.0, 32.0, 420.0, 52.0), 40, UIStyle.GOLD)
	_context_label = UIStyle.make_label("", Rect2(60.0, 82.0, 900.0, 26.0), 17, UIStyle.TEXT_DIM)
	add_child(_budget_label)
	add_child(_context_label)
	var title := UIStyle.make_label("CALCIO MERCATO", Rect2(700.0, 36.0, 420.0, 40.0), 28, UIStyle.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(title)
	_reroll_button = UIStyle.make_button("REROLL", Rect2(1150.0, 40.0, 260.0, 60.0), 21, UIStyle.INFO)
	_reroll_button.pressed.connect(_on_reroll_pressed)
	add_child(_reroll_button)
	_play_button = UIStyle.make_button(PLAY_LABEL, Rect2(1440.0, 40.0, 420.0, 60.0), 24, UIStyle.GOLD)
	_play_button.pressed.connect(_on_play_pressed)
	add_child(_play_button)
	for index in SLOT_COUNT:
		var card := ShopCard.new()
		card.name = "Slot%d" % index
		card.position = CARD_ORIGIN + Vector2(float(index) * CARD_STRIDE, 0.0)
		card.buy_requested.connect(_on_buy_requested)
		add_child(card)
		_cards.append(card)
	_build_selectors()
	_build_roster()
	_status_label = UIStyle.make_label("", Rect2(60.0, STATUS_PANEL.position.y + 6.0, 1800.0, 36.0), 19, UIStyle.TEXT_DIM)
	add_child(_status_label)


## Selettori dell'allenamento: bersaglio in rosa e ruolo per la Masterclass.
func _build_selectors() -> void:
	var hint := UIStyle.make_label("Allenamento: scegli il bersaglio in rosa; il ruolo serve solo alla Masterclass Tattica (GDD §10.3)", Rect2(46.0, SELECT_ROW_Y, 900.0, 38.0), 16, UIStyle.TEXT_DIM)
	add_child(hint)
	_target_option = UIStyle.make_option(Rect2(1100.0, SELECT_ROW_Y, 478.0, 38.0))
	_target_option.item_selected.connect(_on_target_selected)
	add_child(_target_option)
	_role_option = UIStyle.make_option(Rect2(1586.0, SELECT_ROW_Y, 285.0, 38.0))
	for role in PlayerData.ROLES:
		_role_option.add_item("Masterclass -> %s" % str(role))
	_role_option.selected = 0
	add_child(_role_option)


## Nuovo bersaglio scelto: cambia solo la disponibilità dello slot allenamento.
func _on_target_selected(_index: int) -> void:
	if run != null:
		_refresh_availability()


## Griglia dei titolari, righe della panchina e riquadro dei talismani.
func _build_roster() -> void:
	add_child(UIStyle.make_label("ROSA ATTIVA", Rect2(58.0, 550.0, 400.0, 30.0), 24, UIStyle.ACCENT))
	add_child(UIStyle.make_label("TITOLARI  ·  valori di cessione dal GDD §10", Rect2(58.0, 572.0, 700.0, 22.0), 15, UIStyle.TEXT_DIM))
	for slot in range(1, TeamData.LINEUP_SIZE + 1):
		var column := (slot - 1) % STARTER_COLUMNS
		var row := floori(float(slot - 1) / float(STARTER_COLUMNS))
		var origin := STARTER_ORIGIN + Vector2(float(column) * STARTER_STRIDE.x, float(row) * STARTER_STRIDE.y)
		var label := UIStyle.make_label("", Rect2(origin, STARTER_SIZE), 15, UIStyle.TEXT_MAIN)
		label.name = "Titolare%02d" % slot
		_starter_labels.append(label)
		add_child(label)
	add_child(UIStyle.make_label("PANCHINA  ·  massimo %d cartellini, solo i panchinari sono cedibili" % TeamData.MAX_BENCH, Rect2(58.0, 742.0, 900.0, 22.0), 15, UIStyle.TEXT_DIM))
	for index in TeamData.MAX_BENCH:
		var origin := BENCH_ORIGIN + Vector2(float(index) * BENCH_STRIDE, 0.0)
		var label := UIStyle.make_label("", Rect2(origin + Vector2(12.0, 4.0), Vector2(BENCH_SIZE.x - 24.0, 52.0)), 17, UIStyle.TEXT_MAIN)
		label.name = "Panchina%d" % index
		_bench_labels.append(label)
		add_child(label)
		var button := UIStyle.make_button("VENDI", Rect2(origin + Vector2(12.0, 60.0), Vector2(BENCH_SIZE.x - 24.0, 38.0)), 18, UIStyle.GOLD)
		button.name = "Vendi%d" % index
		button.pressed.connect(_on_sell_pressed.bind(index))
		_bench_buttons.append(button)
		add_child(button)
	_talisman_label = UIStyle.make_paragraph("", Rect2(1400.0, 748.0, 466.0, 232.0), 16, UIStyle.TEXT_MAIN)
	add_child(_talisman_label)
