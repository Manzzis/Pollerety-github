extends ParallaxBackground


# En un script dentro del ParallaxBackground
func _process(delta):
	scroll_offset.x -= 500 * delta
	 # El signo negativo hace 
	#que corra hacia la izquierda
