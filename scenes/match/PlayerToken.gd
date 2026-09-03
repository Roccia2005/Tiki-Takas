class_name PlayerToken
extends Node2D

## Pedina tonda di un calciatore, disegnata senza sprite (GDD §12).
##
## Sulla pedina compare solo il numero di maglia: nome, ruolo e Potenza vivono
## nei pannelli dell'HUD, così il campo resta leggibile. L'alone dorato segnala
## il portatore di palla e nient'altro (GDD §4). La pedina non decide nulla:
## legge il cartellino e lo stato che MatchView le passa a ogni refresh.
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

## Corpo del numero di maglia, in unità pitch.
const NUMBER_FONT_SIZE: int = 24

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
const CARRIER_COLOR := Color("f9f871")
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.28)

## Cartellino rappresentato dalla pedina.
var player: PlayerData = null

## Squadra della pedina, da Side.
var side: int = Side.PLAYER

## Numero di maglia mostrato al centro: per i titolari è lo slot del modulo.
var shirt_number: int = 0

## True quando questa pedina ha la palla: l'unico stato con l'alone (GDD §4).
var is_carrier: bool = false

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
func set_state(carrier: bool, in_cone: bool = false) -> void:
	if is_carrier == carrier and is_in_cone == in_cone:
		return
	is_carrier = carrier
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
	draw_circle(Vector2.ZERO, RADIUS, get_token_color())
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, ARC_POINTS, OUTLINE_COLOR, OUTLINE_WIDTH)
	if is_carrier:
		draw_arc(Vector2.ZERO, HALO_RADIUS, 0.0, TAU, ARC_POINTS, CARRIER_COLOR, HALO_WIDTH)
	_draw_number()


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


## Unico testo della pedina: il numero di maglia, centrato sul disco.
func _draw_number() -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var text := str(shirt_number) if shirt_number > 0 else "-"
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, NUMBER_FONT_SIZE).x
	var baseline := (font.get_ascent(NUMBER_FONT_SIZE) - font.get_descent(NUMBER_FONT_SIZE)) * 0.5
	draw_string(font, Vector2(-width * 0.5, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, NUMBER_FONT_SIZE, TEXT_DARK)
