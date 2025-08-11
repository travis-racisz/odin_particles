package main
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"
import "core:math/rand"

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
  flow_direction: i32
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
	initalize_world() // Don't forget to call this!
	
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
				place_sand()
			case 2:
				place_water()
			}
		}
		
		// Reset update flags
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
		flow_direction = rand.choice([]i32{-1, 1})
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

// Fixed bounds checking
is_in_bounds :: proc(x, y: i32) -> bool {
	return x >= 0 && x < WORLD_WIDTH && y >= 0 && y < WORLD_HEIGHT
}

move_particles :: proc(x, y: i32) {
	if !is_in_bounds(x, y) do return

	particle := world.cells[y][x]
	if particle.type == .EMPTY do return
  if particle.has_been_updated == true do return 

	// Try to move down first (both sand and water fall)
	if is_in_bounds(x, y + 1) && world.cells[y + 1][x].type == .EMPTY {
		world.cells[y][x] = Particle{type = .EMPTY, color = rl.BLACK}
		world.cells[y + 1][x] = particle
		world.cells[y + 1][x].has_been_updated = true
		return
	}


	if is_in_bounds(x - 1, y + 1) && world.cells[y + 1][x - 1].type == .EMPTY {
		world.cells[y][x] = Particle{type = .EMPTY, color = rl.BLACK}
		world.cells[y + 1][x - 1] = particle
		world.cells[y + 1][x - 1].has_been_updated = true
		return
	}

	if is_in_bounds(x + 1, y + 1) && world.cells[y + 1][x + 1].type == .EMPTY {
		world.cells[y][x] = Particle{type = .EMPTY, color = rl.BLACK}
		world.cells[y + 1][x + 1] = particle
		world.cells[y + 1][x + 1].has_been_updated = true
		return
	}

	//Water-specific horizontal movement (only after trying to fall AND nothing above)
	if particle.type == .WATER {
	
		
			// Randomly choose left or right first to avoid bias
//			directions := [2]i32{-1, 1}
//			if (x + y) % 2 == 0 {
//				directions = {1, -1} // Mix it up based on position
//			}
//			
//			for direction in directions {
//				new_x := x + direction
//				if is_in_bounds(new_x, y) && world.cells[y][new_x].type == .EMPTY {
//					world.cells[y][x] = Particle{type = .EMPTY, color = rl.BLACK}
//					world.cells[y][new_x] = particle
//					world.cells[y][new_x].has_been_updated = true
//					return
//				}
//			}
//	}
    spread_rate := 5

    //TODO: the water needs to fall down if there is nothing next to it
    //TODO: the flow direction isnt working, need to think of another way of handling this
    
    if is_in_bounds(x - particle.flow_direction,y) && world.cells[y][x - particle.flow_direction].type == .EMPTY { 
      world.cells[y][x] =  Particle{type = .EMPTY, color = rl.BLACK}
      world.cells[y][x - particle.flow_direction] = particle 
      world.cells[y][x - particle.flow_direction].has_been_updated = true 
      return

    }
}
}

draw_floor :: proc() {
	rl.DrawRectangle(0, BOTTOM, rl.GetScreenWidth(), 50, rl.WHITE)
}
