class_name PitchView
extends Node2D

## Campo di gioco disegnato in modo interamente programmatico (GDD §9 e §12).
##
## Nessun asset esterno: erba, linee di gesso, cerchio di centrocampo e le due
## porte nascono da [method CanvasItem._draw] sulla griglia pitch 1000x600, la
## stessa che [ActionResolver] e [FormationData] usano per le coordinate.
## Il nodo va tenuto dentro un genitore scalato (PitchRoot in MatchView.tscn):
## qui si ragiona sempre in unità pitch, mai in pixel di schermo.

## Dimensioni del campo in unità pitch (GDD §7 e §9).
const PITCH_WIDTH: float = ActionResolver.GOAL_LINE_X
const PITCH_HEIGHT: float = 600.0

## Ordinata del centro del campo e delle due porte (GDD §9).
const CENTER_Y: float = ActionResolver.GOAL_CENTER_Y

## Strisce di taglio dell'erba, solo estetica (GDD §12).
const STRIPE_COUNT: int = 10

## Geometria delle linee di gesso, in unità pitch.
const CENTER_CIRCLE_RADIUS: float = 92.0
const CENTER_SPOT_RADIUS: float = 6.0
const PENALTY_BOX_DEPTH: float = 165.0
const PENALTY_BOX_HEIGHT: float = 330.0
const GOAL_BOX_DEPTH: float = 62.0
const GOAL_BOX_HEIGHT: float = 170.0
const PENALTY_SPOT_DEPTH: float = 110.0
const CORNER_ARC_RADIUS: float = 24.0
const ARC_POINTS: int = 48

## Porte: semiapertura della bocca e profondità dietro la linea di fondo.
const GOAL_MOUTH_HALF: float = 70.0
const GOAL_DEPTH: float = 46.0
const GOAL_NET_LINES: int = 6

## Zona bersaglio del tiro: il rilascio del mouse qui dentro vale come
## conclusione verso la porta avversaria (GDD §4).
const GOAL_AIM_MARGIN: float = 80.0
const GOAL_AIM_HALF_HEIGHT: float = 150.0

## Spessori di tratto.
const LINE_WIDTH: float = 3.0
const BORDER_WIDTH: float = 5.0

## Palette "lavagna tattica moderna" del GDD §12.
const GRASS_DARK := Color("0b3a2a")
const GRASS_LIGHT := Color("11492f")
const CHALK := Color(0.92, 0.97, 0.94, 0.78)
const CHALK_SOFT := Color(0.92, 0.97, 0.94, 0.32)
const NEON := Color("46f0c0")
const ENEMY_GOAL_COLOR := Color("ff5f6d")
const OWN_GOAL_COLOR := Color("6db3ff")

## Mostra o nasconde la zona bersaglio del tiro: MatchView la accende mentre si
## mira per rendere leggibile dove va rilasciato il mouse.
var highlight_goal_zone: bool = false


func _draw() -> void:
	_draw_grass()
	_draw_markings()
	_draw_goal(0.0, -1.0, OWN_GOAL_COLOR)
	_draw_goal(PITCH_WIDTH, 1.0, ENEMY_GOAL_COLOR)
	if highlight_goal_zone:
		_draw_goal_zone()


## Accende o spegne l'evidenziazione della zona di tiro e ridisegna.
func set_goal_zone_highlight(enabled: bool) -> void:
	if highlight_goal_zone == enabled:
		return
	highlight_goal_zone = enabled
	queue_redraw()


## Rettangolo del campo in unità pitch.
static func pitch_rect() -> Rect2:
	return Rect2(0.0, 0.0, PITCH_WIDTH, PITCH_HEIGHT)


## Centro della porta avversaria (GDD §4): l'obiettivo dei tiri.
static func enemy_goal_position() -> Vector2:
	return ActionResolver.get_goal_position()


## Centro della propria porta, da cui il portiere avvia l'azione (GDD §4).
static func own_goal_position() -> Vector2:
	return Vector2(0.0, CENTER_Y)


## Zona in cui rilasciare il mouse per calciare in porta: comprende la bocca
## della porta e la fascia di campo immediatamente davanti.
static func goal_aim_zone() -> Rect2:
	var left := PITCH_WIDTH - GOAL_AIM_MARGIN
	return Rect2(left, CENTER_Y - GOAL_AIM_HALF_HEIGHT, GOAL_AIM_MARGIN + GOAL_DEPTH, GOAL_AIM_HALF_HEIGHT * 2.0)


## Riporta un punto dentro i limiti del campo, utile per la mira.
static func clamp_to_pitch(field_pos: Vector2) -> Vector2:
	return Vector2(clampf(field_pos.x, 0.0, PITCH_WIDTH), clampf(field_pos.y, 0.0, PITCH_HEIGHT))


## Manto erboso a strisce alternate (GDD §12).
func _draw_grass() -> void:
	draw_rect(pitch_rect(), GRASS_DARK, true)
	var stripe_width := PITCH_WIDTH / float(STRIPE_COUNT)
	for index in STRIPE_COUNT:
		if index % 2 == 1:
			continue
		draw_rect(Rect2(float(index) * stripe_width, 0.0, stripe_width, PITCH_HEIGHT), GRASS_LIGHT, true)


## Linee di gesso: perimetro, mediana, cerchio di centrocampo, aree e archi.
func _draw_markings() -> void:
	draw_rect(pitch_rect(), CHALK, false, BORDER_WIDTH)
	draw_line(Vector2(PITCH_WIDTH * 0.5, 0.0), Vector2(PITCH_WIDTH * 0.5, PITCH_HEIGHT), CHALK, LINE_WIDTH)
	draw_arc(Vector2(PITCH_WIDTH * 0.5, CENTER_Y), CENTER_CIRCLE_RADIUS, 0.0, TAU, ARC_POINTS, CHALK, LINE_WIDTH)
	draw_circle(Vector2(PITCH_WIDTH * 0.5, CENTER_Y), CENTER_SPOT_RADIUS, CHALK)
	_draw_penalty_area(0.0, 1.0)
	_draw_penalty_area(PITCH_WIDTH, -1.0)
	_draw_corner_arcs()


## Area di rigore, area piccola e dischetto di uno dei due lati.
## [param base_x] è la linea di fondo, [param dir] punta verso il centro campo.
func _draw_penalty_area(base_x: float, dir: float) -> void:
	var box_x := minf(base_x, base_x + dir * PENALTY_BOX_DEPTH)
	draw_rect(Rect2(box_x, CENTER_Y - PENALTY_BOX_HEIGHT * 0.5, PENALTY_BOX_DEPTH, PENALTY_BOX_HEIGHT), CHALK, false, LINE_WIDTH)
	var small_x := minf(base_x, base_x + dir * GOAL_BOX_DEPTH)
	draw_rect(Rect2(small_x, CENTER_Y - GOAL_BOX_HEIGHT * 0.5, GOAL_BOX_DEPTH, GOAL_BOX_HEIGHT), CHALK, false, LINE_WIDTH)
	draw_circle(Vector2(base_x + dir * PENALTY_SPOT_DEPTH, CENTER_Y), CENTER_SPOT_RADIUS * 0.7, CHALK)


## Archetti dei quattro calci d'angolo.
func _draw_corner_arcs() -> void:
	draw_arc(Vector2.ZERO, CORNER_ARC_RADIUS, 0.0, PI * 0.5, 12, CHALK_SOFT, LINE_WIDTH)
	draw_arc(Vector2(PITCH_WIDTH, 0.0), CORNER_ARC_RADIUS, PI * 0.5, PI, 12, CHALK_SOFT, LINE_WIDTH)
	draw_arc(Vector2(PITCH_WIDTH, PITCH_HEIGHT), CORNER_ARC_RADIUS, PI, PI * 1.5, 12, CHALK_SOFT, LINE_WIDTH)
	draw_arc(Vector2(0.0, PITCH_HEIGHT), CORNER_ARC_RADIUS, PI * 1.5, TAU, 12, CHALK_SOFT, LINE_WIDTH)


## Porta con pali, rete accennata e bocca colorata. [param dir] vale 1.0 per la
## porta avversaria a destra e -1.0 per la propria a sinistra.
func _draw_goal(base_x: float, dir: float, color: Color) -> void:
	var top := Vector2(base_x, CENTER_Y - GOAL_MOUTH_HALF)
	var bottom := Vector2(base_x, CENTER_Y + GOAL_MOUTH_HALF)
	var back_x := base_x + dir * GOAL_DEPTH
	var net_color := Color(color.r, color.g, color.b, 0.22)
	var frame := Rect2(minf(base_x, back_x), top.y, GOAL_DEPTH, GOAL_MOUTH_HALF * 2.0)
	draw_rect(frame, Color(0.03, 0.06, 0.05, 0.55), true)
	for index in range(1, GOAL_NET_LINES):
		var ratio := float(index) / float(GOAL_NET_LINES)
		var y := lerpf(top.y, bottom.y, ratio)
		draw_line(Vector2(base_x, y), Vector2(back_x, y), net_color, 1.5)
	draw_line(Vector2(back_x, top.y), Vector2(back_x, bottom.y), color, LINE_WIDTH)
	draw_line(top, Vector2(back_x, top.y), color, LINE_WIDTH)
	draw_line(bottom, Vector2(back_x, bottom.y), color, LINE_WIDTH)
	draw_line(top, bottom, color, BORDER_WIDTH + 1.0)


## Riquadro tratteggiato della zona bersaglio del tiro.
func _draw_goal_zone() -> void:
	var zone := goal_aim_zone()
	draw_rect(zone, Color(NEON.r, NEON.g, NEON.b, 0.10), true)
	var corners := [
		zone.position,
		zone.position + Vector2(zone.size.x, 0.0),
		zone.position + zone.size,
		zone.position + Vector2(0.0, zone.size.y),
	]
	for index in corners.size():
		var from: Vector2 = corners[index]
		var to: Vector2 = corners[(index + 1) % corners.size()]
		draw_dashed_line(from, to, Color(NEON.r, NEON.g, NEON.b, 0.75), 2.0, 14.0)
