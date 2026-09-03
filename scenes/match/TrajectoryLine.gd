class_name TrajectoryLine
extends Node2D

## Linea di mira del passaggio o del tiro, disegnata mentre si trascina il mouse
## dal portatore di palla (GDD §4 e §4.1).
##
## Il colore comunica subito l'esito atteso: verde entro la Gittata, ambra fuori
## Gittata (perdita di potenza del GDD §4.1), rosso per una mira non valida, oro
## per una conclusione verso la porta. L'etichetta riporta distanza e malus.

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
const LABEL_FONT_SIZE: int = 17
const LABEL_BOX_WIDTH: float = 320.0
const LABEL_OFFSET: float = 20.0

const COLOR_VALID := Color("46f0c0")
const COLOR_OUT_OF_RANGE := Color("ffb703")
const COLOR_INVALID := Color("ff5f6d")
const COLOR_SHOT := Color("ffd166")
const LABEL_BACKDROP := Color(0.03, 0.08, 0.07, 0.72)

## Estremi della mira in coordinate pitch (GDD §9).
var origin: Vector2 = Vector2.ZERO
var tip: Vector2 = Vector2.ZERO

## Stato corrente, da AimState.
var state: int = AimState.NONE

## Testo informativo mostrato accanto alla linea, può restare vuoto.
var info_text: String = ""


## Aggiorna la mira e ridisegna.
func aim(from_pos: Vector2, to_pos: Vector2, aim_state: int, text: String = "") -> void:
	origin = from_pos
	tip = to_pos
	state = aim_state
	info_text = text
	visible = state != AimState.NONE
	queue_redraw()


## Spegne la linea di mira.
func clear_aim() -> void:
	state = AimState.NONE
	info_text = ""
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
	_draw_info(color)


## Punta della freccia sul bersaglio della mira.
func _draw_arrow_head(direction: Vector2, color: Color) -> void:
	var base := tip - direction * ARROW_LENGTH
	var side := direction.orthogonal() * ARROW_HALF_WIDTH
	draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), color)


## Etichetta con distanza e malus, sopra il punto medio della traiettoria.
func _draw_info(color: Color) -> void:
	if info_text.is_empty():
		return
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var mid := origin.lerp(tip, 0.5)
	var normal := (tip - origin).normalized().orthogonal()
	if normal.y > 0.0:
		normal = -normal
	var anchor := mid + normal * LABEL_OFFSET
	var text_size := font.get_string_size(info_text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, LABEL_FONT_SIZE)
	var backdrop := Rect2(anchor - Vector2(text_size.x * 0.5 + 8.0, text_size.y * 0.8 + 4.0), text_size + Vector2(16.0, 10.0))
	draw_rect(backdrop, LABEL_BACKDROP, true)
	draw_rect(backdrop, Color(color.r, color.g, color.b, 0.55), false, 1.5)
	draw_string(font, anchor - Vector2(LABEL_BOX_WIDTH * 0.5, 0.0), info_text, HORIZONTAL_ALIGNMENT_CENTER, LABEL_BOX_WIDTH, LABEL_FONT_SIZE, color)
