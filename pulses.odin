package main

import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

PULSE_COLOR :: rl.SKYBLUE
PULSE_INITIAL_RADIUS :: 8
PULSE_LIFETIME :: 6 // In seconds
PULSE_RATE :: 1 // In seconds
PULSE_NODE_TRAVEL_DURATION :: 1

Pulse :: struct {
	position:       Vector2,
	life_remaining: f32,
	node_from_id:   Id,
	node_to_id:     Id,
}

all_pulses := make_map_cap(map[Id]^Pulse, 8)

generate_pulses :: proc() {
	for neuron_id, neuron in all_neurons {
		if neuron.is_pulse_generator {
			for link_id in neuron.link_ids {
				pulse_id := generate_id()
				pulse := new(Pulse)
				pulse^ = {
					position       = neuron.position,
					node_from_id   = neuron_id,
					node_to_id     = link_id,
					life_remaining = PULSE_LIFETIME / f32(len(neuron.link_ids)),
				}
				all_pulses[pulse_id] = pulse
			}
		}
	}
}

// TODO: Make pulses reduce their lifetime every frame.

transmit_pulse :: proc(pulse_id: Id) {
	old_pulse := all_pulses[pulse_id]

	new_neuron_from := all_neurons[old_pulse.node_to_id]

	number_of_links := len(new_neuron_from.link_ids)

	for link_id in new_neuron_from.link_ids {
		if link_id == old_pulse.node_from_id {
			continue
		}
		new_pulse := new(Pulse)
		new_pulse^ = {
			position       = new_neuron_from.position,
			node_from_id   = old_pulse.node_to_id,
			node_to_id     = link_id,
			life_remaining = old_pulse.life_remaining / f32(number_of_links),
		}
		all_pulses[generate_id()] = new_pulse
	}

	delete_key(&all_pulses, pulse_id)
}

update_pulses :: proc() {
	distance_travelled_0_to_1 := math.remap(
		time_since_last_pulse,
		0,
		PULSE_NODE_TRAVEL_DURATION,
		0,
		1,
	)

	for id, &pulse in all_pulses {
		node_from := all_neurons[pulse.node_from_id]
		node_to := all_neurons[pulse.node_to_id]
		origin_to_target := node_to.position - node_from.position

		delta_time := rl.GetFrameTime()

		pulse.position = node_from.position + (origin_to_target * distance_travelled_0_to_1)
	}

	if time_since_last_pulse >= PULSE_NODE_TRAVEL_DURATION {
		for id, _ in all_pulses {
			transmit_pulse(id)
		}
	}

	for id, pulse in all_pulses {
		if pulse.life_remaining <= 0 {
			delete_key(&all_pulses, id)
		}
	}
}
