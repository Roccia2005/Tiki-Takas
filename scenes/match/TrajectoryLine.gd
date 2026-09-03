class_name TrajectoryLine
extends Node2D

## Linea di mira del passaggio o del tiro, disegnata mentre si trascina il mouse
## dal portatore di palla (GDD §4 e §4.1).
##
## Comunica l'esito atteso col solo colore e tratto: verde continuo entro la
## Gittata, ambra tratteggiato fuori Gittata (perdita di potenza del GDD §4.1),
## rosso tratteggiato per una mira non valida, oro continuo per una conclusione
## verso la porta. Nessuna etichetta numerica sul campo: distanza, gittata e
## Potenza Azione restano nei pannelli dell'HUD (GDD §12).

## Stato della mira corrente.
enum AimState {
	NONE,
	PASS_VALID,
	PASS_OUT_OF_RANGE,
	PASS_INVALID,
	SHOT,
}

const LINE_WIDTH: float = 4.0
const DASH_LENGTH: float = 16.0
const ARROW_LENGTH: float = 26.0
const ARROW_HALF_WIDTH: float = 11.0
const TIP_RADIUS: float = 7.0

const COLOR_VALID := Color("46f0c0")
const COLOR_OUT_OF_RANGE := Color("ffb703")
const COLOR_INVALID := Color("ff5f6d")
const COLOR_SHOT := Color("ffd166")

## Estremi della mira in coordinate pitch (GDD §9).
var origin: Vector2 = Vector2.ZERO
var tip: Vector2 = Vector2.ZERO

## Stato corrente, da AimState.
var state: int = AimState.NONE


## Aggiorna la mira e ridisegna.
func aim(from_pos: Vector2, to_pos: Vector2, aim_state: int) -> void:
	origin = from_pos
	tip = to_pos
	state = aim_state
	visible = state != AimState.NONE
	queue_redraw()


## Spegne la linea di mira.
func clear_aim() -> void:
	state = AimState.NONE
	visible = false
	queue_redraw()


## Colore associato allo stato corrente della mira.
func get_state_color() -> Color:
	match state:
		AimState.PASS_VALID:
			return COLOR_VALID
		AimState.PASS_OUT_OF_RANGE:
			return COLOR_OUT_OF_RANGE
		AimState.PASS_INVALID:
			return COLOR_INVALID
		AimState.SHOT:
			return COLOR_SHOT
		_:
			return COLOR_INVALID


func _draw() -> void:
	if state == AimState.NONE:
		return
	var span := tip - origin
	if is_zero_approx(span.length_squared()):
		return
	var color := get_state_color()
	var shaft_end := tip - span.normalized() * ARROW_LENGTH
	if state == AimState.PASS_VALID or state == AimState.SHOT:
		draw_line(origin, shaft_end, Color(color.r, color.g, color.b, 0.35), LINE_WIDTH * 2.2)
		draw_line(origin, shaft_end, color, LINE_WIDTH)
	else:
		draw_dashed_line(origin, shaft_end, color, LINE_WIDTH, DASH_LENGTH)
	_draw_arrow_head(span.normalized(), color)
	draw_arc(tip, TIP_RADIUS, 0.0, TAU, 16, color, 2.0)


## Punta della freccia sul bersaglio della mira.
func _draw_arrow_head(direction: Vector2, color: Color) -> void:
	var base := tip - direction * ARROW_LENGTH
	var side := direction.orthogonal() * ARROW_HALF_WIDTH
	draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), color)
