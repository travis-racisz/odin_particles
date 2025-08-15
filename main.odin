package main
import "core:fmt"
import "core:math/rand"
import "core:strings"
import rl "vendor:raylib"

GRAVITY :: 10000
BOTTOM :: 400
GRID_SIZE :: 4
WORLD_WIDTH :: i32(400)
WORLD_HEIGHT :: i32(250)
WINDOW_WIDTH :: WORLD_WIDTH * GRID_SIZE
WINDOW_HEIGHT :: WORLD_HEIGHT * GRID_SIZE
FIRE_DISPERSION_CHANCE :: 5
FIRE_LIFETIME :: 50
LAVA_BURN_DELAY :: 12
LAVA_SINK_RATE :: 5
WOOD_FLAMMABILITY :: 25

// Water physics constants
WATER_DISPERSION_RATE :: u8(100) // this doesnt do anything currently 


sand_particles: [dynamic]Particle
prev_mouse_x: i32 = -1
prev_mouse_y: i32 = -1
Particles :: enum {
	EMPTY,
	SAND,
	WATER,
	WOOD,
	FIRE,
	SMOKE,
	LAVA,
	STONE,
	// add more if you want
}

Particle :: struct {
	type:             Particles,
	has_been_updated: bool,
	ra:               u8, // can use this value for dispersion rate or life time or whatever 
	rb:               u8, // I predict Particles only needing like two values such as lifetime/flamibility or dispersion rate 
	color:            rl.Color,
}

selected_particle: Particles

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

r :: u8
Beige: rl.Color
Blue: rl.Color
Wood: rl.Color
Smoke: rl.Color
Fire: rl.Color
Lava: rl.Color
Stone: rl.Color

main :: proc() {
	initalize_world()

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "particles")
	for !rl.WindowShouldClose() {
		rl.SetTargetFPS(60)
		r := u8(rand.float32_range(150, 255))
		Beige = rl.Color{211, 176, 131, r}
		Blue = rl.Color{0, 121, 241, r}
		Wood = rl.Color{62, 36, 4, r}
		Fire = rl.Color{211, 18, 0, r}
		Smoke = rl.Color{128, 128, 128, r}
		Lava = rl.Color{106, 15, 0, r}
		Stone = rl.Color{80, 80, 80, r}
		rl.BeginDrawing();defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)
		#partial switch rl.GetKeyPressed() {
		case .ONE:
			selected_particle = .SAND
		case .TWO:
			selected_particle = .WATER
		case .THREE:
			selected_particle = .WOOD
		case .FOUR:
			selected_particle = .FIRE
		case .FIVE:
			selected_particle = .LAVA
		case .SIX:
			selected_particle = .STONE
		}
		if rl.IsMouseButtonDown(.LEFT) {
			// Check if mouse is over UI area before spawning particles
			mouse_pos := rl.GetMousePosition()
			ui_x := WINDOW_WIDTH - 150
			ui_y := i32(10)
			ui_width := i32(140) + 20 // button_width + padding
			ui_height := 7 * (i32(40) + 5) + 10 // 7 buttons * (height + spacing) + padding

			// Only spawn particles if mouse is NOT over the UI
			if !(mouse_pos.x >= f32(ui_x - 10) &&
				   mouse_pos.x <= f32(ui_x + ui_width) &&
				   mouse_pos.y >= f32(ui_y - 10) &&
				   mouse_pos.y <= f32(ui_y + ui_height)) {

				#partial switch selected_particle {
				case .SAND:
					place_particle(Particle{type = .SAND, color = Beige})
				case .WATER:
					place_particle(
						Particle {
							type  = .WATER,
							color = Blue,
							ra    = u8(rand.int31_max(256)),
							rb    = u8(rand.int31_max(2)), // Random direction: 0 or 1
						},
					)
				case .WOOD:
					// ra here refers to flamability chance 
					place_particle(Particle{type = .WOOD, color = Wood, ra = WOOD_FLAMMABILITY})
				case .FIRE:
					// ra is life time value, fire will last for 100 steps rb is the dispersion rate of the fire  
					place_particle(
						Particle {
							type = .FIRE,
							color = Fire,
							ra = FIRE_LIFETIME,
							rb = FIRE_DISPERSION_CHANCE,
						},
					)
				case .LAVA:
					place_particle(
						Particle {
							type = .LAVA,
							color = Lava,
							ra = LAVA_BURN_DELAY,
							rb = LAVA_SINK_RATE,
						},
					)
				case .STONE:
					place_particle(Particle{type = .STONE, color = Stone})
				}
			}
		} else {
			prev_mouse_x = -1
			prev_mouse_y = -1
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
		sp_text: string
		#partial switch selected_particle {
		case .FIRE:
			sp_text = "Fire"
		case .SAND:
			sp_text = "Sand"
		case .WOOD:
			sp_text = "Wood"
		case .WATER:
			sp_text = "Water"
		case .LAVA:
			sp_text = "Lava"
		case .STONE:
			sp_text = "Stone"
		case .EMPTY:
			sp_text = "Empty"

		}
		rl.DrawText(rl.TextFormat("Selected: %s", sp_text), 10, 70, 20, rl.WHITE)

		// Draw particle selection UI
		draw_particle_ui()
	}
}

draw_particle_ui :: proc() {
	ui_x := WINDOW_WIDTH - 150
	ui_y := i32(10)
	button_height := i32(40)
	button_width := i32(140)

	// Background panel
	rl.DrawRectangle(
		ui_x - 10,
		ui_y - 10,
		button_width + 20,
		7 * (button_height + 5) + 10,
		rl.Color{50, 50, 50, 200},
	)

	// Title
	rl.DrawText("Particles", ui_x, ui_y, 20, rl.WHITE)
	ui_y += 25

	// Particle buttons
	particles := [?]struct {
		name:  string,
		type:  Particles,
		color: rl.Color,
	} {
		{"Sand", .SAND, Beige},
		{"Water", .WATER, Blue},
		{"Wood", .WOOD, Wood},
		{"Fire", .FIRE, Fire},
		{"Lava", .LAVA, Lava},
		{"Stone", .STONE, Stone},
	}

	for particle_info, i in particles {
		button_y := ui_y + i32(i) * (button_height + 5)

		// Highlight selected particle
		button_color := rl.Color{80, 80, 80, 255}
		if selected_particle == particle_info.type {
			button_color = rl.Color{120, 120, 120, 255}
		}

		// Draw button
		rl.DrawRectangle(ui_x, button_y, button_width, button_height, button_color)
		rl.DrawRectangleLines(ui_x, button_y, button_width, button_height, rl.WHITE)

		// Draw particle color sample
		rl.DrawRectangle(ui_x + 5, button_y + 5, 20, button_height - 10, particle_info.color)

		// Draw text
		rl.DrawText(
			rl.TextFormat("%s", particle_info.name),
			ui_x + 35,
			button_y + 12,
			16,
			rl.WHITE,
		)

		// Check for mouse click
		mouse_pos := rl.GetMousePosition()
		if rl.IsMouseButtonPressed(.LEFT) &&
		   mouse_pos.x >= f32(ui_x) &&
		   mouse_pos.x <= f32(ui_x + button_width) &&
		   mouse_pos.y >= f32(button_y) &&
		   mouse_pos.y <= f32(button_y + button_height) {
			selected_particle = particle_info.type
		}
	}
}

get_mouse_pos :: proc() -> (x, y: i32) {
	mouse_pos := rl.GetMousePosition()
	x = i32(mouse_pos.x) / GRID_SIZE
	y = i32(mouse_pos.y) / GRID_SIZE
	return
}


// helper procedure
place_single_at :: proc(x, y: i32, p: Particle) {
	if !is_in_bounds(x, y) do return

	brush_size: i32 = 2 // creates a 5x5 brush (from -2 to +2)

	for i: i32 = -brush_size; i <= brush_size; i += 1 {
		for j: i32 = -brush_size; j <= brush_size; j += 1 {
			place_x := x + i
			place_y := y + j
			if is_in_bounds(place_x, place_y) {
				world.cells[place_y][place_x] = p
			}
		}
	}
}

place_particle :: proc(particle: Particle) {
	current_x, current_y := get_mouse_pos()
	if !is_in_bounds(current_x, current_y) do return

	if prev_mouse_x >= 0 && prev_mouse_y >= 0 {
		if current_x == prev_mouse_x {
			start_y := min(prev_mouse_y, current_y)
			end_y := max(prev_mouse_y, current_y)
			for y := start_y; y <= end_y; y += 1 {
				place_single_at(current_x, y, particle)
			}
		} else {
			m := f32(current_y - prev_mouse_y) / f32(current_x - prev_mouse_x)
			b := f32(prev_mouse_y) - m * f32(prev_mouse_x)

			start_x := min(prev_mouse_x, current_x)
			end_x := max(prev_mouse_x, current_x)

			for x := start_x; x <= end_x; x += 1 {
				y := i32(m * f32(x) + b + 0.5)
				place_single_at(x, y, particle)
			}
		}
	} else {
		place_single_at(current_x, current_y, particle)
	}

	prev_mouse_x = current_x
	prev_mouse_y = current_y
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
	for y in 0 ..< WORLD_HEIGHT - 1 {
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

move_wood_particle :: proc(x, y: i32) {
	world.cells[y][x].ra = WOOD_FLAMMABILITY
	world.cells[y][x].has_been_updated = true
}

move_smoke_particle :: proc(x, y: i32) {
	// move up like smoke should 
	random_movement(x, y)
	if world.cells[y][x].ra > 0 {
		world.cells[y][x].ra -= 1
	}
	if world.cells[y][x].ra <= 0 {
		world.cells[y][x] = Particle {
			type  = .EMPTY,
			color = rl.BLACK,
		}
		world.cells[y][x].has_been_updated = true
	}
}

move_fire_particle :: proc(x, y: i32) {
	current_fire := world.cells[y][x]
	aged_color := get_fire_color_by_age(current_fire.ra, FIRE_LIFETIME)
	world.cells[y][x].color = aged_color
	get_fire_color_by_age(current_fire.ra, FIRE_LIFETIME)
	// Try to spread fire to adjacent wood
	world.cells[y][x].rb -= 1
	if world.cells[y][x].rb <= 0 {
		spread_fire(x, y)
		world.cells[y][x].rb = FIRE_DISPERSION_CHANCE
	}

	// Add random movement to fire
	random_movement(x, y)

	// Decrement lifetime
	world.cells[y][x].ra -= 1

	// Check if fire should die
	if world.cells[y][x].ra <= 0 {
		world.cells[y][x] = Particle {
			type  = .SMOKE,
			color = Smoke,
			ra    = 30,
		}
	}

	world.cells[y][x].has_been_updated = true
}

move_lava_particle :: proc(x, y: i32) {
	particle := world.cells[y][x]

	if is_in_bounds(x, y - 1) && world.cells[y - 1][x].type == .WATER {
		// Convert lava to stone
		world.cells[y][x].rb -= 1
		if world.cells[y][x].rb <= 0 {
			world.cells[y][x] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y][x].has_been_updated = true

			// Also convert the water to stone
			world.cells[y - 1][x] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y - 1][x].has_been_updated = true

			// Spawn smoke above the stone
			if is_in_bounds(x, y - 2) && world.cells[y - 2][x].type == .EMPTY {
				world.cells[y - 2][x] = Particle {
					type  = .SMOKE,
					color = Smoke,
					ra    = 30,
				}
			}
			return
		}
	}

	// Check down
	if is_in_bounds(x, y + 1) && world.cells[y + 1][x].type == .WATER {
		world.cells[y][x].rb -= 1
		if world.cells[y][x].rb <= 0 {
			world.cells[y][x] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y][x].has_been_updated = true

			world.cells[y + 1][x] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y + 1][x].has_been_updated = true

			// Spawn smoke above the stone
			if is_in_bounds(x, y - 1) && world.cells[y - 1][x].type == .EMPTY {
				world.cells[y - 1][x] = Particle {
					type  = .SMOKE,
					color = Smoke,
					ra    = 30,
				}
			}
			return
		}
	}

	// Check left
	if is_in_bounds(x - 1, y) && world.cells[y][x - 1].type == .WATER {
		world.cells[y][x].rb -= 1
		if world.cells[y][x].rb <= 0 {
			world.cells[y][x] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y][x].has_been_updated = true

			world.cells[y][x - 1] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y][x - 1].has_been_updated = true

			// Spawn smoke above the stone
			if is_in_bounds(x, y - 1) && world.cells[y - 1][x].type == .EMPTY {
				world.cells[y - 1][x] = Particle {
					type  = .SMOKE,
					color = Smoke,
					ra    = 30,
				}
			}
			return
		}
	}

	// Check right
	if is_in_bounds(x + 1, y) && world.cells[y][x + 1].type == .WATER {
		world.cells[y][x].rb -= 1
		if world.cells[y][x].rb <= 0 {
			world.cells[y][x] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y][x].has_been_updated = true

			world.cells[y][x + 1] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y][x + 1].has_been_updated = true

			// Spawn smoke above the stone
			if is_in_bounds(x, y - 1) && world.cells[y - 1][x].type == .EMPTY {
				world.cells[y - 1][x] = Particle {
					type  = .SMOKE,
					color = Smoke,
					ra    = 30,
				}
			}
			return
		}
	}

	// Check up-left
	if is_in_bounds(x - 1, y - 1) && world.cells[y - 1][x - 1].type == .WATER {
		world.cells[y][x].rb -= 1
		if world.cells[y][x].rb <= 0 {
			world.cells[y][x] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y][x].has_been_updated = true

			world.cells[y - 1][x - 1] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y - 1][x - 1].has_been_updated = true

			// Spawn smoke above the stone
			if is_in_bounds(x, y - 1) && world.cells[y - 1][x].type == .EMPTY {
				world.cells[y - 1][x] = Particle {
					type  = .SMOKE,
					color = Smoke,
					ra    = 30,
				}
			}
			return
		}
	}

	// Check up-right
	if is_in_bounds(x + 1, y - 1) && world.cells[y - 1][x + 1].type == .WATER {
		world.cells[y][x].rb -= 1
		if world.cells[y][x].rb <= 0 {
			world.cells[y][x] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y][x].has_been_updated = true

			world.cells[y - 1][x + 1] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y - 1][x + 1].has_been_updated = true

			// Spawn smoke above the stone
			if is_in_bounds(x, y - 1) && world.cells[y - 1][x].type == .EMPTY {
				world.cells[y - 1][x] = Particle {
					type  = .SMOKE,
					color = Smoke,
					ra    = 30,
				}
			}
			return
		}
	}

	// Check down-left
	if is_in_bounds(x - 1, y + 1) && world.cells[y + 1][x - 1].type == .WATER {
		world.cells[y][x].rb -= 1
		if world.cells[y][x].rb <= 0 {
			world.cells[y][x] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y][x].has_been_updated = true

			world.cells[y + 1][x - 1] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y + 1][x - 1].has_been_updated = true

			// Spawn smoke above the stone
			if is_in_bounds(x, y - 1) && world.cells[y - 1][x].type == .EMPTY {
				world.cells[y - 1][x] = Particle {
					type  = .SMOKE,
					color = Smoke,
					ra    = 30,
				}
			}
			return
		}
	}

	// Check down-right
	if is_in_bounds(x + 1, y + 1) && world.cells[y + 1][x + 1].type == .WATER {
		world.cells[y][x].rb -= 1
		if world.cells[y][x].rb <= 0 {
			world.cells[y][x] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y][x].has_been_updated = true

			world.cells[y + 1][x + 1] = Particle {
				type  = .STONE,
				color = Stone,
			}
			world.cells[y + 1][x + 1].has_been_updated = true

			// Spawn smoke above the stone
			if is_in_bounds(x, y - 1) && world.cells[y - 1][x].type == .EMPTY {
				world.cells[y - 1][x] = Particle {
					type  = .SMOKE,
					color = Smoke,
					ra    = 30,
				}
			}
			return
		}
	}

	if is_in_bounds(x, y) && world.cells[y + 1][x].type == .WOOD {
		world.cells[y][x].ra -= 1
		if world.cells[y][x].ra <= 0 {
			// Create a new lava particle with reset burn delay
			new_lava := particle
			new_lava.ra = LAVA_BURN_DELAY

			world.cells[y + 1][x] = new_lava
			world.cells[y][x] = Particle {
				type  = .EMPTY,
				color = rl.BLACK,
			}
			world.cells[y + 1][x].has_been_updated = true
		}
	}
}

move_sand_particle :: proc(x, y: i32) {
	particle := world.cells[y][x]

	// Sand sinks through water
	if is_in_bounds(x, y + 1) && world.cells[y + 1][x].type == .WATER {
		water_particle := world.cells[y + 1][x]
		world.cells[y][x] = water_particle
		world.cells[y + 1][x] = particle
		world.cells[y][x].has_been_updated = true
		world.cells[y + 1][x].has_been_updated = true
		return
	}

	// Sand sinks through water diagonally
	if is_in_bounds(x - 1, y + 1) && world.cells[y + 1][x - 1].type == .WATER {
		water_particle := world.cells[y + 1][x - 1]
		world.cells[y][x] = water_particle
		world.cells[y + 1][x - 1] = particle
		world.cells[y][x].has_been_updated = true
		world.cells[y + 1][x - 1].has_been_updated = true
		return
	}

	if is_in_bounds(x + 1, y + 1) && world.cells[y + 1][x + 1].type == .WATER {
		water_particle := world.cells[y + 1][x + 1]
		world.cells[y][x] = water_particle
		world.cells[y + 1][x + 1] = particle
		world.cells[y][x].has_been_updated = true
		world.cells[y + 1][x + 1].has_been_updated = true
		return
	}
}

move_stone_particle :: proc(x, y: i32) {
	particle := world.cells[y][x]

	// Stone sinks in water 
	if is_in_bounds(x, y + 1) && world.cells[y + 1][x].type == .WATER {
		water_particle := world.cells[y + 1][x]
		world.cells[y + 1][x] = particle
		world.cells[y][x] = water_particle
		world.cells[y + 1][x].has_been_updated = true
		world.cells[y][x].has_been_updated = true
		return
	}
}

move_particles :: proc(x, y: i32) {
	if !is_in_bounds(x, y) do return

	particle := world.cells[y][x]
	if particle.type == .EMPTY do return
	if particle.has_been_updated == true do return

	// Handle specific particle types
	#partial switch particle.type {
	case .WOOD:
		move_wood_particle(x, y)
		return
	case .SMOKE:
		move_smoke_particle(x, y)
		return
	case .FIRE:
		move_fire_particle(x, y)
		return
	case .LAVA:
		move_lava_particle(x, y)
	case .SAND:
		move_sand_particle(x, y)
	case .STONE:
		move_stone_particle(x, y)
	}
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

	if particle.type == .WATER || particle.type == .LAVA {
		natural_water_flow(x, y)
		world.cells[y][x].has_been_updated = true
		return
	}
}

// directions 
// up: {0, -1}
// left: {-1,0}
// right: {1,0}
// down: {0,1}
// up-left: {-1,-1}
// up-right: {1,-1}
// down-left: {-1,1}
// down-right: {1,1}

spread_fire :: proc(x, y: i32) {
	fire_chance := u8(rand.float32_range(0, 100))

	// array of direction offsets for all 8 directions
	directions := [8][2]i32 {
		{0, -1}, // up
		{0, 1}, // down  
		{-1, 0}, // left
		{1, 0}, // right
		{-1, -1}, // up-left
		{1, -1}, // up-right
		{-1, 1}, // down-left
		{1, 1}, // down-right
	}

	//check each direction
	for dir in directions {
		new_x := x + dir.x
		new_y := y + dir.y

		if !is_in_bounds(new_x, new_y) do continue

		if world.cells[new_y][new_x].type == .WOOD {
			wood_flammability := world.cells[new_y][new_x].ra

			// if fire_chance is less than wood's flammability, wood catches fire
			new_fire_color := get_fire_color_by_age(FIRE_LIFETIME, FIRE_LIFETIME)
			if fire_chance <= wood_flammability {
				world.cells[new_y][new_x] = Particle {
					type  = .FIRE,
					color = new_fire_color,
					ra    = FIRE_LIFETIME,
					rb    = FIRE_DISPERSION_CHANCE,
				}
				world.cells[new_y][new_x].has_been_updated = true

				return
			}
		}
	}
}

random_movement :: proc(x, y: i32) {
	if !is_in_bounds(x, y) do return
	particle_type := world.cells[y][x].type
	if particle_type != .FIRE && particle_type != .SMOKE do return
	if world.cells[y][x].has_been_updated do return

	// Different movement chances based on particle type
	move_chance := rand.float32_range(0, 100)
	chance_threshold: f32

	#partial switch particle_type {
	case .FIRE:
		chance_threshold = 40 // 40% chance for fire
	case .SMOKE:
		chance_threshold = 60 // 60% chance for smoke
	case:
		return
	}

	if move_chance > chance_threshold do return

	current_particle := world.cells[y][x]

	// Different movement patterns based on particle type
	movements: [][2]i32

	#partial switch particle_type {
	case .FIRE:
		// Fire movement (existing pattern)
		fire_movements := [18][2]i32 {
			{0, -1},
			{0, -1},
			{0, -1},
			{0, -1},
			{0, -1},
			{0, -1},
			{0, -1}, // 7x up
			{-1, -1},
			{1, -1},
			{-1, -1},
			{1, -1}, // 4x diagonal up
			{-1, 0},
			{1, 0},
			{-1, 0},
			{1, 0}, // 4x horizontal
			{-1, 1},
			{1, 1}, // 2x diagonal down
			{0, 0}, // 1x stay in place
		}
		movements = fire_movements[:]

	case .SMOKE:
		// Smoke movement (more upward, more dispersive)
		smoke_movements := [20][2]i32 {
			{0, -1},
			{0, -1},
			{0, -1},
			{0, -1},
			{0, -1},
			{0, -1},
			{0, -1},
			{0, -1}, // 8x up
			{-1, -1},
			{1, -1},
			{-1, -1},
			{1, -1},
			{-1, -1},
			{1, -1}, // 6x diagonal up
			{-1, 0},
			{1, 0},
			{-1, 0},
			{1, 0}, // 4x horizontal
			{-1, 1},
			{1, 1}, // 2x diagonal down
		}
		movements = smoke_movements[:]
	}

	movement := movements[rand.int31_max(i32(len(movements)))]
	new_x := x + movement.x
	new_y := y + movement.y

	if is_in_bounds(new_x, new_y) && world.cells[new_y][new_x].type == .EMPTY {
		world.cells[y][x] = Particle {
			type  = .EMPTY,
			color = rl.BLACK,
		}
		world.cells[new_y][new_x] = current_particle
		world.cells[new_y][new_x].has_been_updated = true
	}
}

get_fire_color_by_age :: proc(current_lifetime: u8, max_lifetime: u8) -> rl.Color {
	age_percentage := 1.0 - (f32(current_lifetime) / f32(max_lifetime))

	age_percentage = clamp(age_percentage, 0.0, 1.0)

	young_color := rl.Color{212, 31, 0, 1} // Red-orange

	old_color := rl.Color{255, 140, 0, 255} // Dark orange

	r := u8(f32(young_color.r) + age_percentage * f32(old_color.r - young_color.r))
	g := u8(f32(young_color.g) + age_percentage * f32(old_color.g - young_color.g))
	b := u8(f32(young_color.b) + age_percentage * f32(old_color.b - young_color.b))
	a := u8(255)

	return rl.Color{r, g, b, a}
}


natural_water_flow :: proc(x, y: i32) {
	if !is_in_bounds(x, y) do return
	particle := world.cells[y][x]
	if particle.type != .WATER && particle.type != .LAVA do return
	if particle.has_been_updated do return
	dispersion_rate := i32(4)

	// Step 1: Try to move down first
	if is_in_bounds(x, y + 1) && world.cells[y + 1][x].type == .EMPTY {
		world.cells[y + 1][x] = particle
		world.cells[y][x] = Particle {
			type  = .EMPTY,
			color = rl.BLACK,
		}
		world.cells[y + 1][x].has_been_updated = true
		return
	}

	// Step 2: Try diagonal down movement

	diag_left := is_in_bounds(x - 1, y + 1) && world.cells[y + 1][x - 1].type == .EMPTY
	diag_right := is_in_bounds(x + 1, y + 1) && world.cells[y + 1][x + 1].type == .EMPTY

	if diag_left && diag_right {
		// Both diagonals available - use particle's direction preference
		if world.cells[y][x].rb == 0 {
			world.cells[y + 1][x - 1] = particle
			world.cells[y][x] = Particle {
				type  = .EMPTY,
				color = rl.BLACK,
			}
			world.cells[y + 1][x - 1].has_been_updated = true
			return
		} else {
			world.cells[y + 1][x + 1] = particle
			world.cells[y][x] = Particle {
				type  = .EMPTY,
				color = rl.BLACK,
			}
			world.cells[y + 1][x + 1].has_been_updated = true
			return
		}
	} else if diag_left {
		world.cells[y + 1][x - 1] = particle
		world.cells[y][x] = Particle {
			type  = .EMPTY,
			color = rl.BLACK,
		}
		world.cells[y + 1][x - 1].has_been_updated = true
		return
	} else if diag_right {
		world.cells[y + 1][x + 1] = particle
		world.cells[y][x] = Particle {
			type  = .EMPTY,
			color = rl.BLACK,
		}
		world.cells[y + 1][x + 1].has_been_updated = true
		return
	}

	// Step 3: Try horizontal movement
	if world.cells[y][x].rb == 0 {
		// try to go left 
		if is_in_bounds(x - 1, y) && world.cells[y][x - 1].type == .EMPTY {
			world.cells[y][x - 1] = particle
			world.cells[y][x] = Particle {
				type  = .EMPTY,
				color = rl.BLACK,
			}
			world.cells[y][x - 1].has_been_updated = true
			return
		} else {
			// Can't go left, switch to right
			world.cells[y][x].rb = 1
		}
	} else {
		// try to go right
		if is_in_bounds(x + 1, y) && world.cells[y][x + 1].type == .EMPTY {
			world.cells[y][x + 1] = particle
			world.cells[y][x] = Particle {
				type  = .EMPTY,
				color = rl.BLACK,
			}
			world.cells[y][x + 1].has_been_updated = true
			return
		} else {
			// Can't go right, switch to left
			world.cells[y][x].rb = 0
		}
	}

	// Particle couldn't move
	world.cells[y][x].has_been_updated = true
}
