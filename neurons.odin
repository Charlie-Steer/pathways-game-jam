package main

import "core:math/linalg"

MAX_LINK_DISTANCE :: 100

Id :: i64

Neuron :: struct {
	position:           Vector2,
	link_ids:           [dynamic]Id,
	is_pulse_generator: bool,
}

all_neurons := make_map_cap(map[Id]^Neuron, 64)

// @(require_results)
create_neuron :: proc(position: Vector2) -> Id {
	neuron := new(Neuron) // NOTE: Naive allocation strategy.
	neuron^ = {
		position = position,
		link_ids = get_ids_of_neurons_in_range(position, context.allocator),
	}
	id := generate_id()
	if id == 0 do neuron.is_pulse_generator = true // WARN: Temp hack.
	all_neurons[id] = neuron

	// Update other linked neurons.
	for link_id in neuron.link_ids {
		append_elem(&all_neurons[link_id].link_ids, id)
	}

	return id
}

get_ids_of_neurons_in_range :: proc(
	position: Vector2,
	allocator := context.temp_allocator,
) -> [dynamic]Id {
	neuron_ids := make([dynamic]Id, 0, 8, allocator)
	for id, neuron in all_neurons {
		displacement_vector := neuron.position - position
		if linalg.length2(displacement_vector) <= MAX_LINK_DISTANCE * MAX_LINK_DISTANCE {
			append_elem(&neuron_ids, id)
		}
	}
	return neuron_ids
}

generate_id :: proc() -> Id {
	@(static) next_id: Id
	id := next_id
	next_id += 1
	return id
}
