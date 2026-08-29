`default_nettype none
`timescale 1ns/1ps

module tb;

    // Simulation stimulus lines 
    reg [7:0] ui_in;
    reg [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    reg clk;
    reg rst_n;

    // Fix high-impedance injection by initializing simulator registers immediately
    initial begin
        clk = 0;
        rst_n = 0;
        ui_in = 8'h00;
        uio_in = 8'h00;
    end

    // Instantiate the upgraded 3x2 top-level module
    tt_um_mc14500b_soc_extended uut (
        .ui_in   (ui_in),
        .uo_out  (uo_out),
        .uio_in  (uio_in),
        .uio_out (uio_out),
        .uio_oe  (uio_oe),
        .clk     (clk),
        .rst_n   (rst_n)
    );

    // VCD waveform trace capture configuration for GitHub Actions
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);
    end

endmodule
