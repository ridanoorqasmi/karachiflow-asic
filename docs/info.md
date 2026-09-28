<!---
This file is used to generate the KarachiFlow project datasheet.
-->

## How it works

KarachiFlow is an adaptive two-road traffic controller implemented as a synchronous digital design.

Traffic demand for Road A and Road B is provided using two-bit inputs:

- `00` = no traffic
- `01` = low traffic
- `10` = medium traffic
- `11` = high traffic

The controller operates as a six-state finite state machine:

`A_GREEN -> A_YELLOW -> ALL_RED_AB -> B_GREEN -> B_YELLOW -> ALL_RED_BA -> A_GREEN`

During normal operation, the currently active road remains green for at least `MIN_GREEN`. After this period, the controller can transfer right-of-way if the opposite road has greater traffic demand. `MAX_GREEN` provides starvation prevention when the opposite road has waiting traffic. If the opposite road has no demand, the current road may remain green beyond `MAX_GREEN`.

Emergency inputs are provided independently for both roads. An emergency request on the opposite road initiates a safe transfer without waiting for the normal minimum-green requirement. Yellow and all-red clearance states are always preserved. An emergency on the currently green road retains priority.

All direction changes therefore follow a safe:

`GREEN -> YELLOW -> ALL-RED -> GREEN`

sequence.

### Tiny Tapeout pin mapping

Inputs:

- `ui_in[1:0]` - Road A traffic demand
- `ui_in[3:2]` - Road B traffic demand
- `ui_in[4]` - Road A emergency request
- `ui_in[5]` - Road B emergency request
- `ui_in[7:6]` - unused

Outputs:

- `uo_out[0]` - Road A red
- `uo_out[1]` - Road A yellow
- `uo_out[2]` - Road A green
- `uo_out[3]` - Road B red
- `uo_out[4]` - Road B yellow
- `uo_out[5]` - Road B green
- `uo_out[7:6]` - unused

The bidirectional `uio` pins are unused.

## How to test

Apply the Tiny Tapeout clock and reset signals and drive the traffic-demand and emergency inputs through `ui_in`.

After reset, the controller enters the safe initial condition with Road A green and Road B red.

To test adaptive operation, apply different demand levels to Road A and Road B and observe the traffic-light outputs on `uo_out`. When the opposite road has greater demand after the minimum-green period, the controller should transfer right-of-way through Yellow and All-Red before enabling the opposite green signal.

To test emergency priority, assert the emergency input for the road currently stopped. The controller should initiate a safe transfer without waiting for the normal minimum-green requirement while still preserving the Yellow and All-Red clearance states.

The repository also includes automated Cocotb verification covering reset behavior, adaptive demand switching, minimum and maximum green timing, starvation prevention, emergency priority, simultaneous emergencies, clearance states, exact clearance durations, and randomized safety testing.

## External hardware

No external hardware is required for the digital design or automated verification.