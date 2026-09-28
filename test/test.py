# SPDX-License-Identifier: Apache-2.0
#
# KarachiFlow
# Tiny Tapeout wrapper-level Cocotb verification
#
# This testbench drives and observes ONLY the Tiny Tapeout interface:
#
# Inputs:
#   ui_in[1:0] = traffic_a
#   ui_in[3:2] = traffic_b
#   ui_in[4]   = emergency_a
#   ui_in[5]   = emergency_b
#
# Outputs:
#   uo_out[0] = a_red
#   uo_out[1] = a_yellow
#   uo_out[2] = a_green
#   uo_out[3] = b_red
#   uo_out[4] = b_yellow
#   uo_out[5] = b_green

import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer


# ---------------------------------------------------------------------
# KarachiFlow simulation parameters
# Must match tt_um_karachiflow.v
# ---------------------------------------------------------------------

MIN_GREEN = 5
MAX_GREEN = 10
YELLOW_TIME = 2
ALL_RED_TIME = 2


# ---------------------------------------------------------------------
# Traffic encodings
# ---------------------------------------------------------------------

NONE = 0b00
LOW = 0b01
MEDIUM = 0b10
HIGH = 0b11


# ---------------------------------------------------------------------
# Output bit positions
# ---------------------------------------------------------------------

A_RED = 0
A_YELLOW = 1
A_GREEN = 2

B_RED = 3
B_YELLOW = 4
B_GREEN = 5


# ---------------------------------------------------------------------
# Tiny Tapeout input helpers
# ---------------------------------------------------------------------

def make_inputs(
    traffic_a=NONE,
    traffic_b=NONE,
    emergency_a=0,
    emergency_b=0,
):
    """
    Pack KarachiFlow inputs into Tiny Tapeout ui_in[7:0].
    """

    value = 0

    value |= (traffic_a & 0b11)
    value |= (traffic_b & 0b11) << 2
    value |= (emergency_a & 0b1) << 4
    value |= (emergency_b & 0b1) << 5

    return value


def set_inputs(
    dut,
    traffic_a=NONE,
    traffic_b=NONE,
    emergency_a=0,
    emergency_b=0,
):
    dut.ui_in.value = make_inputs(
        traffic_a,
        traffic_b,
        emergency_a,
        emergency_b,
    )


# ---------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------

def output_bit(dut, bit):
    return (int(dut.uo_out.value) >> bit) & 1


def is_a_green(dut):
    return (
        output_bit(dut, A_GREEN) == 1
        and output_bit(dut, A_YELLOW) == 0
        and output_bit(dut, A_RED) == 0
        and output_bit(dut, B_RED) == 1
        and output_bit(dut, B_YELLOW) == 0
        and output_bit(dut, B_GREEN) == 0
    )


def is_a_yellow(dut):
    return (
        output_bit(dut, A_RED) == 0
        and output_bit(dut, A_YELLOW) == 1
        and output_bit(dut, A_GREEN) == 0
        and output_bit(dut, B_RED) == 1
        and output_bit(dut, B_YELLOW) == 0
        and output_bit(dut, B_GREEN) == 0
    )


def is_b_green(dut):
    return (
        output_bit(dut, A_RED) == 1
        and output_bit(dut, A_YELLOW) == 0
        and output_bit(dut, A_GREEN) == 0
        and output_bit(dut, B_RED) == 0
        and output_bit(dut, B_YELLOW) == 0
        and output_bit(dut, B_GREEN) == 1
    )


def is_b_yellow(dut):
    return (
        output_bit(dut, A_RED) == 1
        and output_bit(dut, A_YELLOW) == 0
        and output_bit(dut, A_GREEN) == 0
        and output_bit(dut, B_RED) == 0
        and output_bit(dut, B_YELLOW) == 1
        and output_bit(dut, B_GREEN) == 0
    )


def is_all_red(dut):
    return (
        output_bit(dut, A_RED) == 1
        and output_bit(dut, A_YELLOW) == 0
        and output_bit(dut, A_GREEN) == 0
        and output_bit(dut, B_RED) == 1
        and output_bit(dut, B_YELLOW) == 0
        and output_bit(dut, B_GREEN) == 0
    )


# ---------------------------------------------------------------------
# Simulation helpers
# ---------------------------------------------------------------------

async def tick(dut, cycles=1):
    for _ in range(cycles):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ns")


async def reset_dut(dut):
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    dut.rst_n.value = 0

    await tick(dut, 2)

    dut.rst_n.value = 1

    await tick(dut, 1)


async def wait_until(dut, condition, timeout=50):
    for _ in range(timeout):
        if condition(dut):
            return True

        await tick(dut)

    return condition(dut)


def check_output_safety(dut):
    """
    Verify fundamental traffic-light safety properties.
    """

    a_r = output_bit(dut, A_RED)
    a_y = output_bit(dut, A_YELLOW)
    a_g = output_bit(dut, A_GREEN)

    b_r = output_bit(dut, B_RED)
    b_y = output_bit(dut, B_YELLOW)
    b_g = output_bit(dut, B_GREEN)

    # Exactly one lamp active per road.
    assert (a_r + a_y + a_g) == 1, (
        f"Invalid Road A outputs: R={a_r} Y={a_y} G={a_g}"
    )

    assert (b_r + b_y + b_g) == 1, (
        f"Invalid Road B outputs: R={b_r} Y={b_y} G={b_g}"
    )

    # Fundamental intersection safety rule.
    assert not (a_g and b_g), "SAFETY FAILURE: both roads GREEN"


# ---------------------------------------------------------------------
# Gate 5 wrapper-level verification
# ---------------------------------------------------------------------

@cocotb.test()
async def test_karachiflow_wrapper(dut):

    dut._log.info("============================================")
    dut._log.info(" KarachiFlow Tiny Tapeout Wrapper Verification")
    dut._log.info("============================================")

    # 100 kHz simulation clock.
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 1

    # -------------------------------------------------------------
    # T01 - Reset
    # -------------------------------------------------------------

    await reset_dut(dut)

    assert is_a_green(dut)
    assert int(dut.uio_oe.value) == 0
    assert int(dut.uio_out.value) == 0

    dut._log.info("PASS T01: Reset -> safe A_GREEN through TT wrapper")


    # -------------------------------------------------------------
    # T02 - Normal A operation
    # -------------------------------------------------------------

    await reset_dut(dut)

    set_inputs(
        dut,
        traffic_a=HIGH,
        traffic_b=LOW,
    )

    await tick(dut, MIN_GREEN + 2)

    assert is_a_green(dut)

    dut._log.info("PASS T02: Normal A_GREEN operation")


    # -------------------------------------------------------------
    # T03 - Demand-driven A -> B transfer
    # -------------------------------------------------------------

    await reset_dut(dut)

    set_inputs(
        dut,
        traffic_a=LOW,
        traffic_b=HIGH,
    )

    reached = await wait_until(dut, is_b_green)

    assert reached, "Road B never received green"

    dut._log.info("PASS T03: Demand-driven A -> B transfer")


    # -------------------------------------------------------------
    # T04 - MIN_GREEN protection
    # -------------------------------------------------------------

    await reset_dut(dut)

    set_inputs(
        dut,
        traffic_a=LOW,
        traffic_b=HIGH,
    )

    # Check the early part of the green interval.
    for _ in range(max(1, MIN_GREEN - 1)):
        assert is_a_green(dut), "Transfer occurred before MIN_GREEN"
        await tick(dut)

    dut._log.info("PASS T04: MIN_GREEN prevents premature transfer")


    # -------------------------------------------------------------
    # T05 - MAX_GREEN fairness
    # -------------------------------------------------------------

    await reset_dut(dut)

    # Equal non-zero demand means the greater-demand rule will not
    # switch. MAX_GREEN must eventually service B.
    set_inputs(
        dut,
        traffic_a=LOW,
        traffic_b=LOW,
    )

    reached = await wait_until(
        dut,
        is_b_green,
        timeout=MAX_GREEN + YELLOW_TIME + ALL_RED_TIME + 10,
    )

    assert reached, "MAX_GREEN failed to service waiting Road B"

    dut._log.info("PASS T05: MAX_GREEN starvation prevention")


    # -------------------------------------------------------------
    # T06 - No-demand hold beyond MAX_GREEN
    # -------------------------------------------------------------

    await reset_dut(dut)

    set_inputs(
        dut,
        traffic_a=HIGH,
        traffic_b=NONE,
    )

    await tick(dut, MAX_GREEN + 5)

    assert is_a_green(dut), (
        "A_GREEN switched despite zero demand on Road B"
    )

    dut._log.info("PASS T06: No-demand hold beyond MAX_GREEN")


    # -------------------------------------------------------------
    # T07 + T08 - Yellow and All-Red clearance states
    # -------------------------------------------------------------

    await reset_dut(dut)

    set_inputs(
        dut,
        traffic_a=LOW,
        traffic_b=HIGH,
    )

    reached_yellow = await wait_until(dut, is_a_yellow)

    assert reached_yellow, "A_YELLOW was never reached"

    dut._log.info("PASS T07: A_YELLOW clearance state exists")

    reached_all_red = await wait_until(dut, is_all_red)

    assert reached_all_red, "ALL_RED_AB was never reached"

    dut._log.info("PASS T08: ALL_RED_AB clearance state exists")


    # -------------------------------------------------------------
    # T09 - Reverse B -> A transfer
    # -------------------------------------------------------------

    reached_b = await wait_until(dut, is_b_green)
    assert reached_b

    set_inputs(
        dut,
        traffic_a=HIGH,
        traffic_b=LOW,
    )

    reached_a = await wait_until(dut, is_a_green)

    assert reached_a, "Road A never regained green"

    dut._log.info("PASS T09: Demand-driven B -> A transfer")


    # -------------------------------------------------------------
    # T10 - Emergency B while A is green
    # -------------------------------------------------------------

    await reset_dut(dut)

    set_inputs(
        dut,
        traffic_a=HIGH,
        traffic_b=LOW,
        emergency_b=1,
    )

    reached_yellow = await wait_until(
        dut,
        is_a_yellow,
        timeout=4,
    )

    assert reached_yellow, (
        "Emergency B did not immediately initiate safe transfer"
    )

    reached_b = await wait_until(dut, is_b_green)

    assert reached_b

    dut._log.info("PASS T10: Emergency B safely preempts A")


    # -------------------------------------------------------------
    # T11 - Emergency A while B is green
    # -------------------------------------------------------------

    await reset_dut(dut)

    set_inputs(
        dut,
        traffic_a=LOW,
        traffic_b=HIGH,
    )

    reached_b = await wait_until(dut, is_b_green)
    assert reached_b

    # Keep B favoured under normal traffic but request A emergency.
    set_inputs(
        dut,
        traffic_a=LOW,
        traffic_b=HIGH,
        emergency_a=1,
    )

    reached_b_yellow = await wait_until(
        dut,
        is_b_yellow,
        timeout=4,
    )

    assert reached_b_yellow

    reached_a = await wait_until(dut, is_a_green)

    assert reached_a

    dut._log.info("PASS T11: Emergency A safely preempts B")


    # -------------------------------------------------------------
    # T12 - Same-road emergency retains A_GREEN
    # -------------------------------------------------------------

    await reset_dut(dut)

    set_inputs(
        dut,
        traffic_a=LOW,
        traffic_b=HIGH,
        emergency_a=1,
    )

    await tick(dut, MAX_GREEN + 5)

    assert is_a_green(dut), (
        "A lost green despite active emergency_a"
    )

    dut._log.info("PASS T12: Same-road emergency retains A_GREEN")


    # -------------------------------------------------------------
    # T13 - Simultaneous emergencies
    # -------------------------------------------------------------

    await reset_dut(dut)

    set_inputs(
        dut,
        traffic_a=LOW,
        traffic_b=HIGH,
        emergency_a=1,
        emergency_b=1,
    )

    await tick(dut, MAX_GREEN + 3)

    assert is_a_green(dut), (
        "Currently green A did not retain priority "
        "during simultaneous emergencies"
    )

    # Clear A emergency while B emergency remains.
    set_inputs(
        dut,
        traffic_a=LOW,
        traffic_b=HIGH,
        emergency_a=0,
        emergency_b=1,
    )

    reached_b = await wait_until(dut, is_b_green)

    assert reached_b, (
        "B emergency was not served after A emergency cleared"
    )

    dut._log.info("PASS T13: Simultaneous emergency arbitration")


    # -------------------------------------------------------------
    # T14 - Continuous demand serves both roads
    # -------------------------------------------------------------

    await reset_dut(dut)

    set_inputs(
        dut,
        traffic_a=MEDIUM,
        traffic_b=MEDIUM,
    )

    saw_a = False
    saw_b = False

    for _ in range(60):

        if is_a_green(dut):
            saw_a = True

        if is_b_green(dut):
            saw_b = True

        check_output_safety(dut)

        await tick(dut)

    assert saw_a
    assert saw_b

    dut._log.info("PASS T14: Continuous demand serves both roads")


    # -------------------------------------------------------------
    # T15 - Randomized safety stress
    # -------------------------------------------------------------

    await reset_dut(dut)

    random.seed(2026)

    for _ in range(500):

        traffic_a = random.randint(0, 3)
        traffic_b = random.randint(0, 3)

        # Keep emergencies relatively uncommon.
        emergency_a = 1 if random.randint(0, 19) == 0 else 0
        emergency_b = 1 if random.randint(0, 19) == 0 else 0

        set_inputs(
            dut,
            traffic_a=traffic_a,
            traffic_b=traffic_b,
            emergency_a=emergency_a,
            emergency_b=emergency_b,
        )

        await tick(dut)

        check_output_safety(dut)

        # Unused dedicated outputs must remain zero.
        assert ((int(dut.uo_out.value) >> 6) & 0b11) == 0

        # Bidirectional outputs are disabled.
        assert int(dut.uio_oe.value) == 0
        assert int(dut.uio_out.value) == 0

    dut._log.info("PASS T15: 500-cycle randomized safety stress")


    # -------------------------------------------------------------
    # T16 - Exact A_YELLOW duration
    # -------------------------------------------------------------

    await reset_dut(dut)

    set_inputs(
        dut,
        traffic_a=LOW,
        traffic_b=HIGH,
    )

    reached_yellow = await wait_until(dut, is_a_yellow)

    assert reached_yellow

    yellow_cycles = 0

    while is_a_yellow(dut) and yellow_cycles < 20:
        await tick(dut)
        yellow_cycles += 1

    assert yellow_cycles == YELLOW_TIME, (
        f"A_YELLOW duration incorrect: "
        f"expected {YELLOW_TIME}, observed {yellow_cycles}"
    )

    dut._log.info(
        f"PASS T16: A_YELLOW exact duration = {yellow_cycles} cycles"
    )


    # -------------------------------------------------------------
    # T17 - Exact ALL_RED_AB duration
    #
    # T16 exits directly into ALL_RED_AB, so we can measure it
    # immediately.
    # -------------------------------------------------------------

    assert is_all_red(dut), (
        "Expected ALL_RED_AB immediately after A_YELLOW"
    )

    all_red_cycles = 0

    while is_all_red(dut) and all_red_cycles < 20:
        await tick(dut)
        all_red_cycles += 1

    assert all_red_cycles == ALL_RED_TIME, (
        f"ALL_RED_AB duration incorrect: "
        f"expected {ALL_RED_TIME}, observed {all_red_cycles}"
    )

    dut._log.info(
        f"PASS T17: ALL_RED_AB exact duration = "
        f"{all_red_cycles} cycles"
    )


    # -------------------------------------------------------------
    # Final Gate 5 result
    # -------------------------------------------------------------

    dut._log.info("============================================")
    dut._log.info(" 17/17 WRAPPER-LEVEL TESTS PASSED")
    dut._log.info(" GATE 5 BEHAVIORAL VERIFICATION PASSED")
    dut._log.info("============================================")