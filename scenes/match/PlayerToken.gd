class_name PlayerToken
extends Node2D

## Pedina tonda di un calciatore, disegnata senza sprite (GDD §12).
##
## Mostra ruolo, numero di maglia e Forza effettiva del tocco corrente
## ([method PlayerData.get_effective_power], GDD §4 e §5). La pedina non decide
## nulla: legge il cartellino e lo stato che MatchView le passa a ogni refresh.
## Va aggiunta a un genitore in unità pitch: [member Node2D.position] è la
## coordinata dello slot del modulo (GDD §9).

## Squadra a cui appartiene la pedina: la rosa del giocatore oppure una sagoma
## difensiva avversaria (GDD §4.1).
enum Side {
	PLAYER,
	OPPONENT,
}

## Raggio della pedina e del suo alone, in unità pitch.
const RADIUS: float = 26.0
const HALO_RADIUS: float = 34.0

## Raggio di presa del mouse: più generoso del disegno per una mira comoda.
const HIT_RADIUS: float = 36.0

## Corpi di testo, in unità pitch.
const NUMBER_FONT_SIZE: int = 24
const ROLE_FONT_SIZE: int = 15
const POWER_FONT_SIZE: int = 16
const LABEL_BOX_WIDTH: float = 120.0

const ARC_POINTS: int = 40
const OUTLINE_WIDTH: float = 3.0
const HALO_WIDTH: float = 4.0

## Colore di riempimento per ruolo (GDD §5).
const ROLE_COLORS := {
	"POR": Color("f5c944"),
	"DIF": Color("4f8ff7"),
	"CEN": Color("3fd6a4"),
	"ATT": Color("ff7a4d"),
}

const FALLBACK_COLOR := Color("9aa5b1")
const OPPONENT_COLOR := Color("c2415a")
const OPPONENT_CONE_COLOR := Color("ff2e57")
const OUTLINE_COLOR := Color(0.04, 0.09, 0.08, 0.9)
const TEXT_DARK := Color(0.05, 0.11, 0.09)
const TEXT_LIGHT := Color(0.94, 0.98, 0.96)
const CARRIER_COLOR := Color("f9f871")
const TARGET_COLOR := Color("46f0c0")
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.28)

## Cartellino rappresentato dalla pedina.
var player: PlayerData = null

## Squadra della pedina, da Side.
var side: int = Side.PLAYER

## Numero di maglia mostrato al centro: per i titolari è lo slot del modulo.
var shirt_number: int = 0

## True quando questa pedina ha la palla (GDD §4).
var is_carrier: bool = false

## True mentre si mira e la pedina può ricevere il passaggio (GDD §4.1).
var is_valid_target: bool = false

## True quando il mouse è sopra la pedina durante la mira.
var is_hovered: bool = false

## True per le sagome che ostruiscono il cono di tiro (GDD §4).
var is_in_cone: bool = false

## Raggio di intercettazione della sagoma avversaria (GDD §4.1), 0 se non serve.
var intercept_radius: float = 0.0


## Configura la pedina e la ridisegna.
func setup(card: PlayerData, token_side: int = Side.PLAYER, number: int = 0, radius: float = 0.0) -> void:
	player = card
	side = token_side
	shirt_number = number
	intercept_radius = radius
	queue_redraw()


## Aggiorna lo stato di gioco mostrato dalla pedina in un colpo solo.
func set_state(carrier: bool, valid_target: bool, hovered: bool = false, in_cone: bool = false) -> void:
	if is_carrier == carrier and is_valid_target == valid_target and is_hovered == hovered and is_in_cone == in_cone:
		return
	is_carrier = carrier
	is_valid_target = valid_target
	is_hovered = hovered
	is_in_cone = in_cone
	queue_redraw()


## Sposta la pedina sulle coordinate pitch indicate (GDD §9).
func set_field_position(field_pos: Vector2) -> void:
	if position.is_equal_approx(field_pos):
		return
	position = field_pos
	queue_redraw()


## True se [param field_pos], in coordinate del genitore, cade sulla pedina.
func contains_point(field_pos: Vector2) -> bool:
	return position.distance_to(field_pos) <= HIT_RADIUS


## Colore della maglia: per ruolo se è un titolare, rosso avversario altrimenti.
func get_token_color() -> Color:
	if side == Side.OPPONENT:
		return OPPONENT_CONE_COLOR if is_in_cone else OPPONENT_COLOR
	if player == null or not ROLE_COLORS.has(player.role):
		return FALLBACK_COLOR
	var color: Color = ROLE_COLORS[player.role]
	return color


func _draw() -> void:
	if side == Side.OPPONENT and intercept_radius > 0.0:
		_draw_intercept_radius()
	draw_circle(Vector2(0.0, 3.0), RADIUS, SHADOW_COLOR)
	var fill := get_token_color()
	draw_circle(Vector2.ZERO, RADIUS, fill)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, ARC_POINTS, OUTLINE_COLOR, OUTLINE_WIDTH)
	if is_carrier:
		draw_arc(Vector2.ZERO, HALO_RADIUS, 0.0, TAU, ARC_POINTS, CARRIER_COLOR, HALO_WIDTH)
	elif is_hovered and is_valid_target:
		draw_arc(Vector2.ZERO, HALO_RADIUS, 0.0, TAU, ARC_POINTS, TARGET_COLOR, HALO_WIDTH)
	elif is_valid_target:
		_draw_dashed_ring(HALO_RADIUS, Color(TARGET_COLOR.r, TARGET_COLOR.g, TARGET_COLOR.b, 0.55))
	_draw_labels()


## Cerchio tratteggiato del raggio di intercettazione della sagoma (GDD §4.1).
func _draw_intercept_radius() -> void:
	var base := OPPONENT_CONE_COLOR if is_in_cone else OPPONENT_COLOR
	draw_circle(Vector2.ZERO, intercept_radius, Color(base.r, base.g, base.b, 0.12 if is_in_cone else 0.07))
	_draw_dashed_ring(intercept_radius, Color(base.r, base.g, base.b, 0.55))


## Anello tratteggiato di raggio [param radius].
func _draw_dashed_ring(radius: float, color: Color, segments: int = 24) -> void:
	var step := TAU / float(segments)
	for index in segments:
		if index % 2 == 1:
			continue
		var start := float(index) * step
		draw_arc(Vector2.ZERO, radius, start, start + step, 4, color, 2.0)


## Ruolo sopra la pedina, numero al centro, Forza effettiva sotto (GDD §5).
func _draw_labels() -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var number_text := str(shirt_number) if shirt_number > 0 else "-"
	_draw_centered(font, number_text, NUMBER_FONT_SIZE, Vector2(0.0, NUMBER_FONT_SIZE * 0.36), TEXT_DARK)
	if player == null:
		return
	_draw_centered(font, "%s %s" % [player.role, player.player_name], ROLE_FONT_SIZE, Vector2(0.0, -RADIUS - 9.0), TEXT_LIGHT)
	var power_text := "%.1f" % player.get_effective_power()
	if side == Side.OPPONENT:
		power_text = "F %d" % player.power
	_draw_centered(font, power_text, POWER_FONT_SIZE, Vector2(0.0, RADIUS + POWER_FONT_SIZE + 2.0), TEXT_LIGHT)


## Testo centrato sull'ascissa della pedina.
func _draw_centered(font: Font, text: String, size: int, offset: Vector2, color: Color) -> void:
	var origin := offset - Vector2(LABEL_BOX_WIDTH * 0.5, 0.0)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, LABEL_BOX_WIDTH, size, color)
