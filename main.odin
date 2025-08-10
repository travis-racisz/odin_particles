package main
import "core:fmt"
import rl "vendor:raylib"


//TODO: make it so the velocity of the paritcles is not tied to the frame rate lol 


GRAVITY :: 10000
BOTTOM :: 400
GRID_SIZE :: 1


sand_particles: [dynamic]Sand

Sand :: struct {
	lifetime: u8,
	color:    rl.Color,
	position: rl.Vector2,
}

main :: proc() {

	rl.InitWindow(500, 500, "particles")
	for !rl.WindowShouldClose() {
		rl.SetTargetFPS(144)

		rl.BeginDrawing();defer rl.EndDrawing()


		rl.ClearBackground(rl.BLACK)
		if rl.IsMouseButtonDown(.LEFT) {
			place_sand()
		}

		//draw_floor()
		render_particles()
		apply_gravity()

	}

}


get_mouse_pos :: proc() -> rl.Vector2 {
	return rl.GetMousePosition()

}

place_sand :: proc() {
	mouse_pos := get_mouse_pos()
	grid_pos := snap_to_grid(mouse_pos)

	new_part := Sand {
		lifetime = 0,
		color    = rl.BEIGE,
		position = {f32(grid_pos.x), f32(grid_pos.y)},
	}

	append(&sand_particles, new_part)

}


render_particles :: proc() {


	for particle in sand_particles {
		rl.DrawRectangle(i32(particle.position.x), i32(particle.position.y), 5, 5, particle.color)

	}

}

Position :: struct {
	x: i32,
	y: i32,
}

snap_to_grid :: proc(pos: rl.Vector2) -> Position {
	return Position {
		x = (i32(pos.x) / GRID_SIZE) * GRID_SIZE,
		y = (i32(pos.y) / GRID_SIZE) * GRID_SIZE,
	}
}

is_position_occupied :: proc(check_pos: Position) -> bool {
	for particle in sand_particles {
		grid_pos := snap_to_grid(particle.position)
		if grid_pos.x == check_pos.x && grid_pos.y == check_pos.y {
			return true
		}
	}
	return false
}
apply_gravity :: proc() {
	for &particle in sand_particles {
		current_grid_pos := snap_to_grid(particle.position)

		if current_grid_pos.y >= BOTTOM {
			continue
		}

		below := Position{current_grid_pos.x, current_grid_pos.y + GRID_SIZE}
		bottom_left := Position{current_grid_pos.x - GRID_SIZE, current_grid_pos.y + GRID_SIZE}
		bottom_right := Position{current_grid_pos.x + GRID_SIZE, current_grid_pos.y + GRID_SIZE}

		if !is_position_occupied(below) {
			particle.position = {f32(below.x), f32(below.y)}
		} else if !is_position_occupied(bottom_left) {
			particle.position = {f32(bottom_left.x), f32(bottom_left.y)}
		} else if !is_position_occupied(bottom_right) {
			particle.position = {f32(bottom_right.x), f32(bottom_right.y)}
		}
	}
}


draw_floor :: proc() {
	rl.DrawRectangle(0, BOTTOM, rl.GetScreenWidth(), 50, rl.WHITE)

}
