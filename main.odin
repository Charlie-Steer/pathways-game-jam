package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

PLAYER_COLOR :: rl.VIOLET
BACKGROUND_COLOR :: rl.LIGHTGRAY
NEURON_COLOR :: rl.PINK
TERMINAL_SPEED :: 300
NEURON_RADIUS :: 16

UP :: Vector2{0, -1}
DOWN :: Vector2{0, 1}
LEFT :: Vector2{-1, 0}
RIGHT :: Vector2{1, 0}

Vector2 :: [2]f32
window_width: i32 = 800
window_height: i32 = 600
window_dimensions := Vector2{f32(window_width), f32(window_height)}

player_dimensions := Vector2{50, 50}

time_since_last_pulse: f32

Character :: struct {
	position: Vector2,
	velocity: Vector2,
}

brain_panel := struct {
	position:   Vector2,
	dimensions: Vector2,
} {
	position   = {0, window_dimensions.y / 2},
	dimensions = {window_dimensions.x, window_dimensions.y / 2},
}

main :: proc() {
	rl.InitWindow(window_width, window_height, "Pathways") // NOTE: Change Name.
	defer rl.CloseWindow()
	rl.SetTargetFPS(30) // NOTE: Change to 60

	player_origin := Vector2 {
		(window_dimensions.x - player_dimensions.x) / 2,
		(window_dimensions.y - player_dimensions.y) / 4,
	}
	player := Character {
		position = player_origin,
	}

	// CAMERA

	camera := rl.Camera2D {
		target = player.position + (player_dimensions / 2),
		offset = {window_dimensions.x / 2, window_dimensions.y / 4},
		zoom   = 1,
	}

	for !rl.WindowShouldClose() {
		delta_time := rl.GetFrameTime()
		time_since_last_pulse += delta_time
		mouse_position := rl.GetMousePosition()
		mouse_is_in_brain := is_mouse_in_brain(mouse_position)
		player.velocity = {0, 0}

		// PROCESS INPUT
		movement_key_is_down := is_movement_key_down()
		if movement_key_is_down {
			if rl.IsKeyDown(rl.KeyboardKey.W) do player.velocity += UP
			if rl.IsKeyDown(rl.KeyboardKey.A) do player.velocity += LEFT
			if rl.IsKeyDown(rl.KeyboardKey.S) do player.velocity += DOWN
			if rl.IsKeyDown(rl.KeyboardKey.D) do player.velocity += RIGHT
		}
		if mouse_is_in_brain {
			if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
				create_neuron(mouse_position)
			}
		}

		// PULSES
		// WARN: Probably imprecise
		update_pulses()
		if time_since_last_pulse >= PULSE_NODE_TRAVEL_DURATION {
			generate_pulses()
		}


		// UPDATE PLAYER VELOCITY
		player.velocity = linalg.vector_normalize0(player.velocity)
		player.velocity *= TERMINAL_SPEED
		player.position += player.velocity * delta_time

		// UPDATE CAMERA
		camera.target = player.position + (player_dimensions / 2)

		// DRAWING
		rl.BeginDrawing()
		rl.ClearBackground(BACKGROUND_COLOR)

		rl.BeginMode2D(camera)
		rl.DrawRectangleV({300, 0}, player_dimensions, rl.MAROON)
		rl.DrawRectangleV(player.position, player_dimensions, PLAYER_COLOR)

		rl.EndMode2D()

		rl.DrawRectangleV(brain_panel.position, brain_panel.dimensions, rl.DARKGRAY)

		// Draw Neurons
		// Draw temp connections.
		if mouse_is_in_brain {
			for neuron_id in get_ids_of_neurons_in_range(mouse_position) {
				rl.DrawLineV(mouse_position, all_neurons[neuron_id].position, rl.MAROON)
			}
		}

		// Draw neurons.
		for id, neuron in all_neurons {
			// Links
			for link_id in neuron.link_ids {
				rl.DrawLineV(neuron.position, all_neurons[link_id].position, NEURON_COLOR)
			}

			color := neuron.is_pulse_generator ? rl.BLUE : NEURON_COLOR
			rl.DrawCircleV(neuron.position, NEURON_RADIUS, color)
		}

		// Draw pulses.
		for id, pulse in all_pulses {
			fmt.println(len(all_pulses))
			rl.DrawCircleV(pulse.position, PULSE_INITIAL_RADIUS, PULSE_COLOR)
		}

		// Draw cursor neuron.
		if mouse_is_in_brain {
			rl.DrawCircleLinesV(mouse_position, NEURON_RADIUS, rl.BLACK)
		}

		rl.EndDrawing()

		if time_since_last_pulse >= PULSE_NODE_TRAVEL_DURATION {
			time_since_last_pulse = 0
		}

		free_all(context.temp_allocator)
	}
}

@(require_results)
is_mouse_in_brain :: proc(mouse_position: Vector2) -> bool {
	fmt.println(mouse_position)
	if brain_panel.position.x <= mouse_position.x &&
	   brain_panel.position.x + brain_panel.dimensions.x >= mouse_position.x &&
	   brain_panel.position.y <= mouse_position.y &&
	   brain_panel.position.y + brain_panel.dimensions.y >= mouse_position.y {
		return true
	} else do return false
}

@(require_results)
is_movement_key_down :: proc() -> bool {
	if rl.IsKeyDown(rl.KeyboardKey.W) ||
	   rl.IsKeyDown(rl.KeyboardKey.A) ||
	   rl.IsKeyDown(rl.KeyboardKey.S) ||
	   rl.IsKeyDown(rl.KeyboardKey.D) {
		return true
	} else {
		return false
	}
}
