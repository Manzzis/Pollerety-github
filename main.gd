extends Node2D

@onready var MenuPausa = $MenuPausa
var pausa : bool = Autoload.pausado

@onready var boton_acelerar = $CanvasLayer/BotonAcelerar

var velocidad_normal: float = 300.0
var velocidad_acelerada: float = 600.0 # El doble de rápido

@onready var texto_puntos = $"Label Puntos"
@onready var texto_tiempo = $LabelTiempo
@onready var panel_victoria = $"CanvasLayer/Panel Victoria" # Panel que se muestra al finalizar
@onready var texto_puntuacion = $"CanvasLayer/Panel Victoria/puntuacion"
@export var speed: float = 300.0 
var esta_frenado: bool = false   

# === CONFIGURACIÓN DE PUNTOS Y TIEMPO ===
var puntos: int = 0
@export var tiempo_inicial: float = 60.0 # Segundos de duración
var tiempo_restante: float = 60.0
var juego_terminado: bool = false

# === DISTANCIA Y COLECTIVO ===
@export var posicion_colectivo_x: float = 600.0 
@export var distancia_maxima: float = 120.0    

@export var capas_parallax: Array[Parallax2D] = []

var escena_parada = preload("res://parada.tscn")
var parada_actual: Area2D = null

@onready var spawn_timer = $SpawnTimer
@onready var boton_rojo = $CanvasLayer/HBoxContainer/BotonRojo
@onready var boton_azul = $CanvasLayer/HBoxContainer/BotonAzul
@onready var boton_verde = $CanvasLayer/HBoxContainer/BotonVerde


func _ready():
	boton_rojo.pressed.connect(func(): _verificar_color("rojo"))
	boton_azul.pressed.connect(func(): _verificar_color("azul"))
	boton_verde.pressed.connect(func(): _verificar_color("verde"))
	pausa = false
	get_tree().paused = false
	
	panel_victoria.hide()
	# Inicializamos el tiempo y el marcador de puntos
	tiempo_restante = tiempo_inicial
	_actualizar_ui_puntos()
	
	spawn_timer.timeout.connect(_on_spawn_timeout)
	spawn_timer.start(randf_range(2.0, 4.0))
	speed = velocidad_normal
	
	# Conectamos las señales de "mantener presionado" y "soltar"
	boton_acelerar.button_down.connect(_on_acelerar_presionado)
	boton_acelerar.button_up.connect(_on_acelerar_soltado)


func _process(delta):
	# 1. Lógica del reloj de tiempo
	if not juego_terminado:
		tiempo_restante -= delta
		texto_tiempo.text = "Tiempo: " + str(max(0, ceil(tiempo_restante)))
		
		if tiempo_restante <= 0:
			_terminar_partida()
	# 2. Movimiento del fondo
	if not esta_frenado and not juego_terminado:
		moverFondo(delta)

func moverFondo(delta):
	for capa in capas_parallax:
		var factor_velocidad = capa.scroll_scale.x
		capa.scroll_offset.x += (speed * factor_velocidad) * delta


func _on_spawn_timeout():
	if is_instance_valid(parada_actual) or juego_terminado:
		spawn_timer.start(1.0)
		return
	var nueva_parada = escena_parada.instantiate()
	nueva_parada.position = Vector2(-150, 515) 
	
	var colores_posibles = ["rojo", "azul", "verde"]
	nueva_parada.color_id = colores_posibles.pick_random()
	
	add_child(nueva_parada)
	parada_actual = nueva_parada
	
	spawn_timer.start(randf_range(3.0, 5.0))


func _verificar_color(color_presionado: String):
	if juego_terminado: return
	
	if is_instance_valid(parada_actual):
		var distancia = abs(parada_actual.global_position.x - posicion_colectivo_x)
		
		if distancia <= distancia_maxima:
			if parada_actual.color_id == color_presionado:
				# Sumamos puntos y actualizamos el Label
				puntos += 10
				_actualizar_ui_puntos()
				_rutina_frenar_y_subir()
			else:
				print("Color equivocado.")
		else:
			print("¡Muy lejos! Estás a una distancia de: ", distancia)
	else:
		print("No hay paradas cerca.")


func _actualizar_ui_puntos():
	texto_puntos.text = "Puntos: " + str(puntos)


func _rutina_frenar_y_subir():
	esta_frenado = true
	spawn_timer.paused = true
	
	if is_instance_valid(parada_actual):
		if parada_actual.has_method("ocultar_pasajero"):
			parada_actual.ocultar_pasajero()
	
	await get_tree().create_timer(1.0).timeout
	
	if is_instance_valid(parada_actual):
		parada_actual.queue_free()
	parada_actual = null
	
	# Solo reanudamos si la partida sigue activa
	if not juego_terminado:
		esta_frenado = false
		spawn_timer.paused = false


func _terminar_partida():
	juego_terminado = true
	spawn_timer.stop()
	
	# === NUEVO: Actualizamos el label con los puntos finales ===
	if is_instance_valid(texto_puntuacion):
		texto_puntuacion.text = "Puntaje final: " + str(puntos)
	
	# Mostramos la UI de fin de juego si existe
	if is_instance_valid(panel_victoria):
		panel_victoria.show()
		
	get_tree().paused = true

# Menú de Pausa
func _on_pausa_pressed() -> void:
	if pausa == false:
		get_tree().paused = true
		pausa = true
		MenuPausa.show()
	else:
		get_tree().paused = false
		pausa = false
		MenuPausa.hide()


func _on_reanudar_pressed() -> void:
	MenuPausa.hide()
	get_tree().paused = false
	pausa = false


func _on_volver_menu_pressed() -> void:
	pausa = false
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_acelerar_presionado():
	# Solo aceleramos si el juego está corriendo
	if not juego_terminado:
		speed = velocidad_acelerada


func _on_acelerar_soltado():
	# Al soltar, vuelve a la velocidad original
	speed = velocidad_normal
