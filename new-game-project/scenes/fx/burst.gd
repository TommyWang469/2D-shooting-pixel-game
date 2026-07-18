extends CPUParticles2D
## One-shot particle burst for impacts and deaths. Instantiate, add to the scene,
## then call burst(color, amount, speed). Frees itself when the emission finishes.


func _ready() -> void:
	texture = load("res://assets/spark.png")
	finished.connect(queue_free)


func burst(p_color: Color, p_amount := 8, p_speed := 70.0) -> void:
	color = p_color
	amount = maxi(1, p_amount)
	initial_velocity_min = p_speed * 0.4
	initial_velocity_max = p_speed
	emitting = true
