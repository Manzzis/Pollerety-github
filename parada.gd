extends Area2D

var color_id: String = ""
@onready var anim_pasajero = $animPasajero

func _ready():
	if color_id != "":
		anim_pasajero.play(color_id)

func _process(delta):
	var nivel = get_parent()
	
	if "esta_frenado" in nivel and nivel.esta_frenado == false:
		position.x += nivel.speed * delta
	
	# Si la parada se pasó de largo y salió de la pantalla (ejemplo: pasó la posición X = 1300)
	if position.x > 1300:
		if nivel.parada_actual == self:
			nivel.parada_actual = null
		queue_free()

func ocultar_pasajero():
	anim_pasajero.hide()
