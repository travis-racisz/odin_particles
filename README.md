# Odin Particles


https://github.com/user-attachments/assets/5c366e03-9593-4522-9d95-93020b5aec39


A cellular automata-based falling sand game implemented in the Odin programming language using the Raylib graphics library. This project simulates particle interactions, such as sand falling, liquids flowing, and other physics-based behaviors in a pixelated world.

## Description

This is a simple yet engaging simulation where particles follow rules of cellular automata to create emergent behaviors. Particles can stack, fall, spread, or react with each other, mimicking real-world physics in a 2D grid. It's built for experimentation, fun, and learning about procedural generation and graphics programming in Odin.

## Features

- **Particle Types**: Support for various particles like sand, water, stone, fire, and more (depending on implementation).
- **Real-time Simulation**: Updates the grid each frame using cellular automata rules.
- **Interactive Placement**: Use the mouse to add or remove particles in the world.
- **Rendering with Raylib**: Efficient 2D graphics rendering for smooth performance.
- **Customizable**: Easy to extend with new particle types or rules.

## Requirements

- **Odin Compiler**: Download and install from the official Odin website: [odin-lang.org](https://odin-lang.org/).
- **Raylib Library**: Install Raylib from [raylib.com](https://www.raylib.com/). Ensure it's set up as an Odin collection (e.g., in a `vendor/raylib` directory or via environment variables).

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/travis-racisz/odin_particles.git
   ```
2. Navigate to the project directory:
   ```
   cd odin_particles
   ```
3. Ensure Raylib is accessible. If using a vendor directory, place Raylib sources in `vendor/raylib`.

## Building

Build the project using the Odin compiler:
```
odin build . -out:odin_particles -collection:raylib=vendor/raylib
```
(Adjust the `-collection` path if Raylib is installed differently.)

This will produce an executable named `odin_particles` (or `odin_particles.exe` on Windows).

## Usage

Run the executable:
```
./odin_particles
```

The game window will open, displaying the simulation grid.

### Controls
- **Left Mouse Button**: Place selected particle.
- **Right Mouse Button**: Erase particles.
- **Number Keys (1-5)**: Select different particle types (e.g., 1 for sand, 2 for water).
- **Esc**: Quit the game.

(Note: Controls may vary based on the exact implementation; check the source code for details.)

## Contributing

Contributions are welcome! Feel free to submit pull requests for new features, bug fixes, or optimizations. Please follow standard coding conventions for Odin.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details (if available; otherwise, assume open-source for personal use).

## Acknowledgments

- Built with [Odin](https://odin-lang.org/) and [Raylib](https://www.raylib.com/).
- Inspired by Noita and classic falling sand games.

For any questions or issues, open a GitHub issue or contact the maintainer. Enjoy simulating! 🚀
