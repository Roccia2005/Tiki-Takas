class_name BallToken
extends Node2D

## Pallone disegnato in modo programmatico, con scia luminosa che cambia colore
## e intensità in base alla Potenza Azione accumulata (GDD §4 e §12).
##
## Si muove per interpolazione verso [member target_field_position], cioè verso
## la posizione del portatore di palla o del punto di rimessa scelto da
## MatchController. Nessuna logica di gioco: riceve solo coordinate pitch.

## Raggio del pallone e del suo alone, in unità pitch.
const RADIUS: float = 11.0
const GLOW_RADIUS: float = 19.0

## Velocità di spostamento in unità pitch al secondo.
const TRAVEL_SPEED: float = 1400.0

## Distanza sotto la quale il pallone è considerato arrivato.
const ARRIVAL_EPSILON: float = 0.6

## Punti massimi conservati per la scia.
const TRAIL_LENGTH: int = 14

## Potenza Azione a cui la scia raggiunge il colore e l'intensità massimi.
const POWER_REFERENCE: float = 60.0

const ARC_POINTS: int = 24
const BALL_COLOR := Color(0.97, 0.99, 0.98)
const BALL_OUTLINE := Color(0.05, 0.11, 0.09, 0.85)
const GLOW_LOW := Color("46f0c0")
const GLOW_HIGH := Color("ffd166")
const PANEL_COLOR := Color(0.09, 0.16, 0.14)

## Coordinate pitch verso cui il pallone si sta muovendo (GDD §9).
var target_field_position: Vector2 = Vector2.ZERO

## Rapporto 0-1 tra Potenza Azione accumulata e POWER_REFERENCE: guida il
## colore e l'ampiezza dell'alone (GDD §12).
var power_ratio: float = 0.0

var _trail: Array[Vector2] = []


func _ready() -> void:
	target_field_position = position
	set_process(true)


func _process(delta: float) -> void:
	var distance := position.distance_to(target_field_position)
	if distance <= ARRIVAL_EPSILON:
		if not _trail.is_empty():
			_trail.remove_at(0)
			queue_redraw()
		return
	position = position.move_toward(target_field_position, TRAVEL_SPEED * delta)
	_trail.append(position)
	while _trail.size() > TRAIL_LENGTH:
		_trail.remove_at(0)
	queue_redraw()


## Teletrasporta il pallone e cancella la scia: da usare a inizio azione.
func snap_to(field_pos: Vector2) -> void:
	position = field_pos
	target_field_position = field_pos
	_trail.clear()
	queue_redraw()


## Avvia lo scorrimento del pallone verso [param field_pos].
func move_to(field_pos: Vector2) -> void:
	target_field_position = field_pos


## Aggiorna l'intensità della scia con la Potenza Azione corrente (GDD §12).
func set_power(action_power: float) -> void:
	var ratio := clampf(action_power / POWER_REFERENCE, 0.0, 1.0)
	if is_equal_approx(ratio, power_ratio):
		return
	power_ratio = ratio
	queue_redraw()


## True quando il pallone ha raggiunto la posizione richiesta.
func is_settled() -> bool:
	return position.distance_to(target_field_position) <= ARRIVAL_EPSILON


func _draw() -> void:
	var glow := GLOW_LOW.lerp(GLOW_HIGH, power_ratio)
	_draw_trail(glow)
	var glow_radius := lerpf(RADIUS + 3.0, GLOW_RADIUS, power_ratio)
	draw_circle(Vector2.ZERO, glow_radius, Color(glow.r, glow.g, glow.b, 0.18 + 0.30 * power_ratio))
	draw_circle(Vector2.ZERO, RADIUS, BALL_COLOR)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, ARC_POINTS, BALL_OUTLINE, 1.5)
	draw_circle(Vector2.ZERO, RADIUS * 0.34, PANEL_COLOR)


## Scia luminosa dietro il pallone, in dissolvenza dalla coda alla testa.
func _draw_trail(glow: Color) -> void:
	if _trail.size() < 2:
		return
	for index in range(1, _trail.size()):
		var from: Vector2 = _trail[index - 1] - position
		var to: Vector2 = _trail[index] - position
		var ratio := float(index) / float(_trail.size())
		draw_line(from, to, Color(glow.r, glow.g, glow.b, 0.45 * ratio), lerpf(2.0, RADIUS, ratio))
