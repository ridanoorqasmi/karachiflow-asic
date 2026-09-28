# KarachiFlow — Implementation Results

This document records the implementation and verification results obtained from the Tiny Tapeout SKY130 flow for KarachiFlow.

## RTL Verification

- Core RTL verification: **17/17 tests passed**
- Demand-based switching: **Passed**
- MIN_GREEN enforcement: **Passed**
- MAX_GREEN starvation prevention: **Passed**
- Emergency priority: **Passed**
- Yellow and all-red safety transitions: **Passed**
- Exact clearance-state duration tests: **Passed**
- 500-cycle randomized safety stress test: **Passed**

## Tiny Tapeout Integration

- Target interface: **Tiny Tapeout**
- Top module: `tt_um_karachiflow`
- Tile allocation: **1x1**
- GDS build: **Passed**
- Gate-level simulation: **Passed**
- Tiny Tapeout physical precheck: **15/15 passed**
- Layout viewer generation: **Passed**

## Physical Implementation

Results reported by the Tiny Tapeout SKY130 hardening flow:

| Metric | Result |
| --- | --- |
| Tile allocation | 1x1 |
| Utilization | 14.443% |
| Functional cells | 250 (excluding fill and tap cells) |
| Flip-flops | 35 |
| Routed wire length | 3810 µm |
| GDS generation | Passed |
| Physical precheck | 15/15 passed |

## Timing Analysis

The physical-design flow performed post-route static timing analysis using a **20 ns clock constraint (50 MHz)**.

| Reported corner | Minimum period | Estimated Fmax |
| --- | ---: | ---: |
| Fast (-40°C, 1.95 V) | 3.59 ns | 278.40 MHz |
| Typical (25°C, 1.80 V) | 5.73 ns | 174.53 MHz |
| Slow (100°C, 1.60 V) | 11.72 ns | 85.31 MHz |

Reported timing results:

- Setup violations: **0**
- Hold violations: **0**
- Setup WNS: **0.0**
- Setup TNS: **0.0**
- Hold WNS: **0**
- Hold TNS: **0.0**

The reported Fmax values are static timing estimates from the post-route implementation and are **not measured silicon performance**.

## Physical Layout

The final rendered physical layout is stored at:

`docs/karachiflow_layout.png`

The image is generated from the completed Tiny Tapeout physical-design flow.

## Notes and Limitations

- The RTL currently uses `MIN_GREEN = 5`, `MAX_GREEN = 10`, `YELLOW_TIME = 2`, and `ALL_RED_TIME = 2` as verification-cycle parameters. They are not intended to represent real-world traffic-light durations.
- Traffic demand and emergency status are external digital inputs; sensing and emergency detection are outside the KarachiFlow ASIC.
- Power consumption has not been characterized.
- No fabricated silicon measurements are available. Reported physical and timing results come from the Tiny Tapeout SKY130 implementation flow.