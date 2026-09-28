/*
 * KarachiFlow
 * Adaptive Two-Road Traffic Controller
 *
 * Core RTL only. This module is independent of the
 * Tiny Tapeout top-level interface.
 */

`timescale 1ns / 1ps
`default_nettype none

module karachiflow #(
    // Timing values are expressed in clock cycles.
    // YELLOW_TIME and ALL_RED_TIME must be >= 1.
    //
    // Small defaults are used for simulation and will be
    // finalized before the implementation is frozen.
    parameter integer MIN_GREEN    = 5,
    parameter integer MAX_GREEN    = 10,
    parameter integer YELLOW_TIME  = 2,
    parameter integer ALL_RED_TIME = 2
) (
    input  wire       clk,
    input  wire       rst_n,

    input  wire [1:0] traffic_a,
    input  wire [1:0] traffic_b,

    input  wire       emergency_a,
    input  wire       emergency_b,

    output reg        a_red,
    output reg        a_yellow,
    output reg        a_green,

    output reg        b_red,
    output reg        b_yellow,
    output reg        b_green
);

    // ------------------------------------------------------------
    // FSM state definitions
    // ------------------------------------------------------------

    localparam [2:0]
        A_GREEN    = 3'd0,
        A_YELLOW   = 3'd1,
        ALL_RED_AB = 3'd2,
        B_GREEN    = 3'd3,
        B_YELLOW   = 3'd4,
        ALL_RED_BA = 3'd5;

    reg [2:0] current_state;
    reg [2:0] next_state;


    // ------------------------------------------------------------
    // Timer
    //
    // One timer is sufficient because only the active FSM state
    // requires timing. It is reset whenever the state changes.
    // ------------------------------------------------------------

    reg [31:0] timer;


    // ------------------------------------------------------------
    // State register and timer
    // ------------------------------------------------------------

    always @(posedge clk) begin

        if (!rst_n) begin

            current_state <= A_GREEN;
            timer         <= 32'd0;

        end
        else begin

            current_state <= next_state;

            if (current_state != next_state)
                timer <= 32'd0;
            else
                timer <= timer + 1'b1;

        end
    end


    // ------------------------------------------------------------
    // Next-state / transition logic
    // ------------------------------------------------------------

    always @(*) begin

        // Default behavior: remain in current state.
        next_state = current_state;

        case (current_state)

            // ----------------------------------------------------
            // ROAD A GREEN
            // ----------------------------------------------------

            A_GREEN: begin

                // Emergency on the currently green road retains
                // priority.
                //
                // This also handles simultaneous emergencies:
                // if both emergency signals are high while A is
                // green, Road A retains its green.
                if (emergency_a) begin

                    next_state = A_GREEN;

                end

                // Emergency on the opposite road requests an
                // immediate safe transfer.
                //
                // MIN_GREEN is bypassed for emergency priority,
                // but Yellow and All-Red are never bypassed.
                else if (emergency_b) begin

                    next_state = A_YELLOW;

                end

                // Normal scheduling cannot interrupt MIN_GREEN.
                else if (timer < MIN_GREEN) begin

                    next_state = A_GREEN;

                end

                // After MIN_GREEN, greater demand on Road B
                // requests a safe transfer toward B.
                else if (traffic_b > traffic_a) begin

                    next_state = A_YELLOW;

                end

                // Starvation prevention:
                // after MAX_GREEN, transfer if Road B is waiting.
                //
                // An empty opposite road does not force a switch.
                else if ((timer >= MAX_GREEN) &&
                         (traffic_b != 2'b00)) begin

                    next_state = A_YELLOW;

                end

                else begin

                    next_state = A_GREEN;

                end
            end


            // ----------------------------------------------------
            // A -> B SAFE CLEARANCE
            // ----------------------------------------------------

            A_YELLOW: begin

                // Timer begins at zero on state entry.
                // Therefore N cycles correspond to timer values
                // 0 through N-1.
                if (timer >= (YELLOW_TIME - 1))
                    next_state = ALL_RED_AB;

            end


            ALL_RED_AB: begin

                // Hold both roads red for exactly ALL_RED_TIME
                // clock cycles.
                if (timer >= (ALL_RED_TIME - 1))
                    next_state = B_GREEN;

            end


            // ----------------------------------------------------
            // ROAD B GREEN
            // ----------------------------------------------------

            B_GREEN: begin

                // Emergency on the currently green road retains
                // priority.
                //
                // This also handles simultaneous emergencies:
                // if both emergency signals are high while B is
                // green, Road B retains its green.
                if (emergency_b) begin

                    next_state = B_GREEN;

                end

                // Emergency on the opposite road requests an
                // immediate safe transfer.
                //
                // MIN_GREEN is bypassed for emergency priority,
                // but Yellow and All-Red are never bypassed.
                else if (emergency_a) begin

                    next_state = B_YELLOW;

                end

                // Normal scheduling cannot interrupt MIN_GREEN.
                else if (timer < MIN_GREEN) begin

                    next_state = B_GREEN;

                end

                // After MIN_GREEN, greater demand on Road A
                // requests a safe transfer toward A.
                else if (traffic_a > traffic_b) begin

                    next_state = B_YELLOW;

                end

                // Starvation prevention:
                // after MAX_GREEN, transfer if Road A is waiting.
                //
                // An empty opposite road does not force a switch.
                else if ((timer >= MAX_GREEN) &&
                         (traffic_a != 2'b00)) begin

                    next_state = B_YELLOW;

                end

                else begin

                    next_state = B_GREEN;

                end
            end


            // ----------------------------------------------------
            // B -> A SAFE CLEARANCE
            // ----------------------------------------------------

            B_YELLOW: begin

                if (timer >= (YELLOW_TIME - 1))
                    next_state = ALL_RED_BA;

            end


            ALL_RED_BA: begin

                if (timer >= (ALL_RED_TIME - 1))
                    next_state = A_GREEN;

            end


            // ----------------------------------------------------
            // DEFENSIVE RECOVERY
            // ----------------------------------------------------

            default: begin

                next_state = A_GREEN;

            end

        endcase
    end


    // ------------------------------------------------------------
    // Output decoder
    //
    // Outputs depend only on the current FSM state.
    //
    // Safe defaults are:
    // Road A = RED
    // Road B = RED
    //
    // Therefore both ALL_RED states and an unexpected state
    // naturally produce the safe output.
    // ------------------------------------------------------------

    always @(*) begin

        // Safe defaults
        a_red    = 1'b1;
        a_yellow = 1'b0;
        a_green  = 1'b0;

        b_red    = 1'b1;
        b_yellow = 1'b0;
        b_green  = 1'b0;


        case (current_state)

            A_GREEN: begin

                a_red   = 1'b0;
                a_green = 1'b1;

            end


            A_YELLOW: begin

                a_red    = 1'b0;
                a_yellow = 1'b1;

            end


            ALL_RED_AB: begin

                // Safe defaults already represent both roads red.

            end


            B_GREEN: begin

                b_red   = 1'b0;
                b_green = 1'b1;

            end


            B_YELLOW: begin

                b_red    = 1'b0;
                b_yellow = 1'b1;

            end


            ALL_RED_BA: begin

                // Safe defaults already represent both roads red.

            end


            default: begin

                // Safe defaults remain active.

            end

        endcase
    end

endmodule

`default_nettype wire