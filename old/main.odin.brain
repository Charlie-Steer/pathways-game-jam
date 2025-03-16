package main

import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

TAU :: 6.2831855

// SETTINGS
win_width: i32 = 800
win_height: i32 = 600

PLAYER_SIZE :: vector2{20, 20}
PLAYER_COLOR :: rl.DARKPURPLE

NODE_COLOR :: rl.PINK
NODE_RADIUS :: 16
MAX_LINK_LEN :: 100

PULSE_COLOR :: rl.BLUE
PULSE_RADIUS :: 8
PULSE_SPEED :: 50

// NOTE: Might be better to do it based on time.
MAX_PULSE_MOVES :: 8


// TYPES
vector2 :: [2]f32
ID :: i64
Node_Map :: map[ID]Node
Pulse_Map :: map[ID]Pulse
Node :: struct {
	position:   vector2,
	linked_ids: [dynamic]ID,
}

Pulse :: struct {
	node_from:                  ID,
	node_to:                    ID,
	movement_vector:            vector2,
	normalized_movement_vector: vector2,
	position:                   vector2,
	moves_performed:            int,
}

Character :: struct {
	position: vector2,
}

// VARIABLES
win_dimensions := vector2{f32(win_width), f32(win_height)}
next_node_id: i64
next_pulse_id: i64
all_nodes := make_map_cap(Node_Map, 64)
all_pulses := make_map_cap(Pulse_Map, 64)
player := Character {
	position = vector2{(win_dimensions.x - PLAYER_SIZE.x) / 2, win_dimensions.y / 4},
}

main :: proc() {
	rl.InitWindow(win_width, win_height, "Pathways")
	defer rl.CloseWindow()
	rl.SetWindowPosition(1924, 64) // TODO: Change to normal default.
	rl.SetTargetFPS(30) // TODO: Set to 60.

	for !rl.WindowShouldClose() {
		// Frame Setup
		mouse_position := rl.GetMousePosition()
		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			last_node_id := create_node(mouse_position)
			// temp
			if len(all_nodes[last_node_id].linked_ids) != 0 {
				generate_pulse(last_node_id)
			}
		}

		move_pulses(&all_pulses)

		// Draw Calls
		rl.BeginDrawing()
		draw_ui()
		draw_links(all_nodes)
		draw_nodes(all_nodes)
		draw_pulses(all_pulses)
		rl.DrawRectangleV(player.position, PLAYER_SIZE, PLAYER_COLOR)
		rl.EndDrawing()
	}
}

move_pulses :: proc(pulses: ^Pulse_Map) {
	for id, &pulse in pulses {
		movement_vector := all_nodes[pulse.node_to].position - all_nodes[pulse.node_from].position
		pulse.position +=
			PULSE_SPEED * linalg.vector_normalize(movement_vector) * rl.GetFrameTime()
		if linalg.vector_length2(pulse.position - all_nodes[pulse.node_from].position) >=
		   linalg.vector_length2(pulse.movement_vector) {
			generate_pulse(pulse.node_to, pulse.node_from, pulse.moves_performed)
			delete_key(pulses, id)
		}
	}
}

generate_pulse :: proc(origin_node_id: ID, ignore_id: ID = -1, moves_performed := 0) {
	origin_node := all_nodes[origin_node_id]
	for id in origin_node.linked_ids {
		// NOTE: I don't think ignore_id is necessary.
		if id != ignore_id {
			// trigger_action
			player.position += rand.float32_range(-1, 1) * 10

			movement_vector := all_nodes[origin_node_id].position - all_nodes[id].position

			// Update moves_performed based on number of links. Exit if exceeds limit.
			moves_performed := moves_performed + len(origin_node.linked_ids)
			if moves_performed > MAX_PULSE_MOVES do return

			pulse := Pulse {
				node_from                  = origin_node_id,
				node_to                    = id,
				position                   = origin_node.position, //+ {rand.float32_range(-10, 10), rand.float32_range(-10, 10)},
				movement_vector            = movement_vector,
				normalized_movement_vector = linalg.vector_normalize(movement_vector),
				moves_performed            = moves_performed,
			}
			all_pulses[next_pulse_id] = pulse
			next_pulse_id += 1
		}
	}
}

draw_pulses :: proc(pulses: Pulse_Map) {
	for id, pulse in pulses {
		rl.DrawCircleV(pulse.position, PULSE_RADIUS, PULSE_COLOR)
	}
}

find_nodes_in_range :: proc(origin: vector2, nodes: Node_Map) -> (node_ids: [dynamic]ID) {
	for id, node in nodes {
		displacement_vector := node.position - origin
		displacement_vector_length2 := linalg.vector_length2(displacement_vector)
		if displacement_vector_length2 <= MAX_LINK_LEN * MAX_LINK_LEN {
			append_elem(&node_ids, id)
		}
	}
	fmt.println("LINKS:", node_ids)
	return node_ids
}

create_node :: proc(position: vector2) -> ID {
	nodes_in_range := find_nodes_in_range(position, all_nodes)
	all_nodes[next_node_id] = Node {
		position   = position,
		linked_ids = nodes_in_range,
	}
	add_node_to_links(next_node_id, nodes_in_range)
	next_node_id += 1
	return next_node_id - 1
}

add_node_to_links :: proc(node: ID, node_ids: [dynamic]ID) {
	for id in node_ids {
		// TODO: I don't like this. Using maps with non-pointer nodes probably was a mistake.
		node_struct := all_nodes[id]
		append_elem(&node_struct.linked_ids, node)
		all_nodes[id] = node_struct
	}
}

draw_nodes :: proc(nodes: Node_Map) {
	for id, node in nodes {
		// fmt.println("id:", id)
		rl.DrawCircleV(node.position, NODE_RADIUS, NODE_COLOR)
	}
}

draw_links :: proc(nodes: Node_Map) {
	// NOTE: This draws over twice.
	for _, node in nodes {
		for id in node.linked_ids {
			rl.DrawLineV(node.position, nodes[ID(id)].position, NODE_COLOR)
		}
	}
}

draw_ui :: proc() {
	rl.ClearBackground(rl.GRAY)
	rl.DrawRectangleV(
		{0, win_dimensions.y / 2},
		{win_dimensions.x, win_dimensions.y / 2},
		rl.DARKGRAY,
	)
}
