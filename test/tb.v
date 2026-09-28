`default_nettype none
`timescale 1ns / 1ps

/*
 * KarachiFlow Tiny Tapeout testbench wrapper.
 *
 * Instantiates the actual Tiny Tapeout-facing module so Cocotb
 * tests the complete integration rather than the core directly.
 */

module tb ();

  // Dump signals for waveform inspection.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  // Tiny Tapeout interface
  reg clk;
  reg rst_n;
  reg ena;

  reg  [7:0] ui_in;
  reg  [7:0] uio_in;

  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;


  // Power connections required for gate-level simulation
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif


  // ------------------------------------------------------------
  // KarachiFlow Tiny Tapeout top-level
  // ------------------------------------------------------------

  tt_um_karachiflow user_project (

      // Gate-level power ports
`ifdef GL_TEST
      .VPWR   (VPWR),
      .VGND   (VGND),
`endif

      .ui_in   (ui_in),
      .uo_out  (uo_out),

      .uio_in  (uio_in),
      .uio_out (uio_out),
      .uio_oe  (uio_oe),

      .ena     (ena),
      .clk     (clk),
      .rst_n   (rst_n)
  );

endmodule