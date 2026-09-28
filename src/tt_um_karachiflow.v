/*
 * KarachiFlow
 * Tiny Tapeout top-level wrapper
 */

`default_nettype none

module tt_um_karachiflow (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ------------------------------------------------------------
    // KarachiFlow core outputs
    // ------------------------------------------------------------

    wire a_red;
    wire a_yellow;
    wire a_green;

    wire b_red;
    wire b_yellow;
    wire b_green;


    // ------------------------------------------------------------
    // KarachiFlow core
    //
    // Tiny Tapeout input mapping:
    //
    // ui_in[1:0] = traffic_a
    // ui_in[3:2] = traffic_b
    // ui_in[4]   = emergency_a
    // ui_in[5]   = emergency_b
    // ui_in[7:6] = unused
    // ------------------------------------------------------------

    karachiflow #(
        .MIN_GREEN(5),
        .MAX_GREEN(10),
        .YELLOW_TIME(2),
        .ALL_RED_TIME(2)
    ) core (
        .clk         (clk),
        .rst_n       (rst_n),

        .traffic_a   (ui_in[1:0]),
        .traffic_b   (ui_in[3:2]),

        .emergency_a (ui_in[4]),
        .emergency_b (ui_in[5]),

        .a_red       (a_red),
        .a_yellow    (a_yellow),
        .a_green     (a_green),

        .b_red       (b_red),
        .b_yellow    (b_yellow),
        .b_green     (b_green)
    );


    // ------------------------------------------------------------
    // Tiny Tapeout output mapping
    //
    // uo_out[0] = A red
    // uo_out[1] = A yellow
    // uo_out[2] = A green
    // uo_out[3] = B red
    // uo_out[4] = B yellow
    // uo_out[5] = B green
    // uo_out[7:6] = unused
    // ------------------------------------------------------------

    assign uo_out[0] = a_red;
    assign uo_out[1] = a_yellow;
    assign uo_out[2] = a_green;

    assign uo_out[3] = b_red;
    assign uo_out[4] = b_yellow;
    assign uo_out[5] = b_green;

    assign uo_out[7:6] = 2'b00;


    // ------------------------------------------------------------
    // Bidirectional pins are not used by KarachiFlow
    // ------------------------------------------------------------

    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;


    // ------------------------------------------------------------
    // Prevent unused-input warnings
    //
    // ena is provided by Tiny Tapeout but KarachiFlow does not
    // require it internally.
    //
    // uio_in and ui_in[7:6] are also unused.
    // ------------------------------------------------------------

    wire _unused = &{
        ena,
        uio_in,
        ui_in[7:6],
        1'b0
    };

endmodule

`default_nettype wire