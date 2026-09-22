# FPGA Lunar Lander Minigame

This repository contains a SystemVerilog implementation of a Lunar Lander minigame designed to run on an FPGA The game uses custom Binary-Coded Decimal (BCD) arithmetic to process real-time physics and displays telemetry data dynamically across 7-segment displays. 

## Gameplay & Controls
The objective is to manage limited fuel and thrust to safely land a spacecraft on the lunar surface without crashing.

* **Thrust Control**: The player inputs numeric keys (0-9) to set the active thrust level, which counteracts a constant gravity of `16'h5`. 
* **Display Toggles**: The user can toggle what data is shown on the 7-segment displays using dedicated keys (Z, Y, X, and W) to cycle between Altitude (`ALT`), Velocity (`VEL`), Fuel (`GAS`), and Thrust (`THR`).
* **Win/Loss Conditions**: The game ends when the altitude reaches `0`. If the landing velocity is too fast (represented in BCD as `< 16'h9970`), the ship crashes and triggers a red LED. If the velocity is within safe limits, the landing is successful and triggers a green LED.
* **Game Over State**: Once a landing or crash occurs, the game freezes the state by disabling the memory write-enable signal (`wen`).

## Hardware Interfaces
* **Inputs**: The system accepts a 100Hz clock (`hz100`), an asynchronous `reset`, and a 20-bit input array (`pb` / `in`) mapped to keypad or pushbutton inputs.
* **Outputs**: Visual feedback is provided via eight 7-segment displays (`ss0` to `ss7`), alongside red and green discrete LEDs for end-game status.

## System Architecture

The project is heavily modularized, separating hardware interfacing, game logic, arithmetic, and display control:

* **Top-Level & Synchronization (`lunarlander.sv`, `keysync.sv`, `clock_psc.sv`)**: The top module wires the game components together. It uses a clock prescaler to divide the 100Hz input clock into a slower game tick, and a key synchronizer to debounce and encode the 20-bit button inputs into usable signals.
* **Memory & State (`ll_memory.sv`)**: A sequential block that stores the current BCD values for altitude, velocity, fuel, and thrust. Default starting parameters are initialized at `16'h4500` for altitude and `16'h800` for fuel. 
* **Game Physics (`ll_alu.sv`)**: Computes the next state of the game on every clock cycle. It adds thrust to velocity, subtracts gravity from velocity, updates altitude based on velocity, and subtracts the active thrust from the fuel reserves. It also features bounding logic to prevent altitude and fuel from rolling over into negative invalid BCD states.
* **BCD Arithmetic Pipeline (`bcdaddsub4.sv`, `bcdadd4.sv`, `bcd9comp1.sv`)**: Instead of binary math, the physics engine relies on a 16-bit BCD adder/subtractor built from 4-bit BCD adders and 9's complement generators.
* **Display Controller (`ll_display.sv`, `ssdec.sv`)**: Multiplexes the 7-segment displays based on the user's selected view mode. It decodes the raw BCD numbers into 7-segment patterns, handles zero-blanking for leading digits, inserts a minus sign for negative velocities, and spells out three-letter status labels (e.g., "ALT", "GAS") on the upper displays[cite: 5].
