package main
import "core:fmt"
import "core:math/rand"
import "core:strings"
import rl "vendor:raylib"

GRAVITY :: 10000
BOTTOM :: 400
GRID_SIZE :: 4
WORLD_WIDTH :: i32(300)
WORLD_HEIGHT :: i32(200)
WINDOW_WIDTH :: WORLD_WIDTH * GRID_SIZE
WINDOW_HEIGHT :: WORLD_HEIGHT * GRID_SIZE

sand_particles: [dynamic]Particle

Particles :: enum {
	EMPTY,
	SAND,
	WATER,
	WOOD,
	FIRE,
	// add more if you want
}

Particle :: struct {
	type:             Particles,
	has_been_updated: bool,
	ra:               u8,
	rb:               u8,
	color:            rl.Color,
	flow_direction:   i32,
}

selected_particle := 1

World :: struct {
	height: i32,
	width:  i32,
	cells:  [WORLD_HEIGHT][WORLD_WIDTH]Particle,
}

world := World {
	width  = WORLD_WIDTH,
	height = WORLD_HEIGHT,
}

initalize_world :: proc() {
	for y in 0 ..< WORLD_HEIGHT {
		for x in 0 ..< WORLD_WIDTH {
			world.cells[y][x] = Particle {
				type  = .EMPTY,
				color = rl.BLACK,
			}
		}
	}
}

main :: proc() {
	initalize_world()

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "particles")
	for !rl.WindowShouldClose() {
		rl.SetTargetFPS(144)

		rl.BeginDrawing();defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)
		#partial switch rl.GetKeyPressed() {
		case .ONE:
			selected_particle = 1
		case .TWO:
			selected_particle = 2
		}

		if rl.IsMouseButtonDown(.LEFT) {
			switch selected_particle {
			case 1:
				place_particle(Particle{type = .SAND, color = rl.BEIGE})
			case 2:
				place_particle(Particle{type = .WATER, color = rl.BLUE})
			}
		}

		for y in 0 ..< WORLD_HEIGHT {
			for x in 0 ..< WORLD_WIDTH {
				world.cells[y][x].has_been_updated = false
			}
		}

		render_particles()
		apply_gravity()

		fps := 1 / rl.GetFrameTime()
		rl.DrawText(rl.TextFormat("fps: %f", fps), 10, 10, 50, rl.WHITE)
		rl.DrawText(rl.TextFormat("Selected: %d", selected_particle), 10, 70, 20, rl.WHITE)
	}
}

get_mouse_pos :: proc() -> (x, y: i32) {
	mouse_pos := rl.GetMousePosition()
	x = i32(mouse_pos.x) / GRID_SIZE
	y = i32(mouse_pos.y) / GRID_SIZE
	return
}


//TODO: write generic function to just place any type of particle 
//

place_particle :: proc(particle: Particle) {
	x, y := get_mouse_pos()

	if !is_in_bounds(x, y) do return

	// place like 10 at a time in like a squareish circle 
	for i: i32 = 0; i < 10; i += 1 {
		for j: i32 = 0; j < 10; j += 1 {
			world.cells[y + j][x + i] = particle
		}

	}


}

place_sand :: proc() {
	x, y := get_mouse_pos()
	if !is_in_bounds(x, y) do return

	particle := Particle {
		type             = .SAND,
		color            = rl.BEIGE,
		has_been_updated = false,
	}
	world.cells[y][x] = particle
}

place_water :: proc() {
	x, y := get_mouse_pos()
	if !is_in_bounds(x, y) do return

	particle := Particle {
		type             = .WATER,
		color            = rl.BLUE,
		has_been_updated = false,
		flow_direction   = rand.choice([]i32{-1, 1}),
	}
	world.cells[y][x] = particle
}

render_particles :: proc() {
	for y in 0 ..< WORLD_HEIGHT {
		for x in 0 ..< WORLD_WIDTH {
			particle := world.cells[y][x]
			if particle.type != .EMPTY {
				rl.DrawRectangle(
					x * GRID_SIZE,
					y * GRID_SIZE,
					GRID_SIZE,
					GRID_SIZE,
					particle.color,
				)
			}
		}
	}
}

Position :: struct {
	x: i32,
	y: i32,
}

apply_gravity :: proc() {
	for y := WORLD_HEIGHT - 2; y >= 0; y -= 1 {
		for x in 0 ..< WORLD_WIDTH {
			if !world.cells[y][x].has_been_updated && world.cells[y][x].type != .EMPTY {
				move_particles(x, y)
			}
		}
	}
}

is_in_bounds :: proc(x, y: i32) -> bool {
	return x >= 0 && x < WORLD_WIDTH && y >= 0 && y < WORLD_HEIGHT
}

move_particles :: proc(x, y: i32) {
	if !is_in_bounds(x, y) do return

	particle := world.cells[y][x]
	if particle.type == .EMPTY do return
	if particle.has_been_updated == true do return

	// Try to move down first
	if is_in_bounds(x, y + 1) && world.cells[y + 1][x].type == .EMPTY {
		world.cells[y][x] = Particle {
			type  = .EMPTY,
			color = rl.BLACK,
		}
		world.cells[y + 1][x] = particle
		world.cells[y + 1][x].has_been_updated = true
		return
	}


	if is_in_bounds(x - 1, y + 1) && world.cells[y + 1][x - 1].type == .EMPTY {
		world.cells[y][x] = Particle {
			type  = .EMPTY,
			color = rl.BLACK,
		}
		world.cells[y + 1][x - 1] = particle
		world.cells[y + 1][x - 1].has_been_updated = true
		return
	}

	if is_in_bounds(x + 1, y + 1) && world.cells[y + 1][x + 1].type == .EMPTY {
		world.cells[y][x] = Particle {
			type  = .EMPTY,
			color = rl.BLACK,
		}
		world.cells[y + 1][x + 1] = particle
		world.cells[y + 1][x + 1].has_been_updated = true
		return
	}

	if particle.type == .WATER {


		// move left
		if is_in_bounds(x - 1, y) && world.cells[y][x - 1].type == .EMPTY {
			// can move left so do so
			world.cells[y][x] = Particle {
				type  = .EMPTY,
				color = rl.BLACK,
			}
			world.cells[y][x - 1] = particle
			world.cells[y][x - 1].has_been_updated = true
			return

		}
		if is_in_bounds(x + 1, y) && world.cells[y][x + 1].type == .EMPTY {
			// can move right so do so
			world.cells[y][x] = Particle {
				type  = .EMPTY,
				color = rl.BLACK,
			}
			world.cells[y][x + 1] = particle
			world.cells[y][x + 1].has_been_updated = true
			return

		}
		// move down if nothing is under it 
		if is_in_bounds(x, y + 1) && world.cells[y + 1][x].type == .EMPTY {
			world.cells[y][x] = Particle {
				type  = .EMPTY,
				color = rl.BLACK,
			}
			world.cells[y + 1][x] = particle
			world.cells[y + 1][x].has_been_updated = true
			return
		}
		// if sand is above it the sand should sink 
		if is_in_bounds(x, y) && world.cells[y - 1][x].type == .SAND {
			world.cells[y][x] = Particle {
				type  = .SAND,
				color = rl.BEIGE,
			}
			world.cells[y - 1][x] = particle
			world.cells[y - 1][x].has_been_updated = true

		}
	}
}

draw_floor :: proc() {
	rl.DrawRectangle(0, BOTTOM, rl.GetScreenWidth(), 50, rl.WHITE)
}
