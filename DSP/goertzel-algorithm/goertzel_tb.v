`timescale 1ns / 1ps
`define CLK_PER 10
`define SIM     // must be either SYNTH or SIM
//////////////////////////////////////////////////////////////////////////////////
// Company: the Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 07/18/2024 11:10:50 AM
// Module Name: goertzel_tb
// Project Name: Goertzel Sim
// Target Devices: Arty A7
// Description: Testbench for the Second Order Goertzel Algorithm digital filter
// 
// Dependencies: 
//  CORDIC IP, Sincos Module, Goertzel Module
//////////////////////////////////////////////////////////////////////////////////
// Current Results:
// t_init   Re      Im          abs()
// 210      -54.55  -31.55      63.02
// 220      0.01    -63.08      63.08
// 230      54.56   -31.53      63.02
// 240      54.55   31.55       63.02
// 250      -0.01   63.08       63.08
// 260      -54.56  31.53       63.02
// 270      -54.55  -31.55      63.02

module goertzel_tb(
    `ifdef SYNTH
        input clk,
        input rst,
        output led
    `endif
);

    `ifdef SIM
        reg rst = 1'b1;
        initial rst = #270 1'b0;
        reg clk = 1'b0;
        always clk = #(`CLK_PER/2) ~clk;
    `endif

    // * DEFAULTS FOR GOERTZEL
    localparam SW = 12;             // signed signal width
    localparam N = 126;             // y[N] = X(k) (the result we want)
    localparam OW = 18;             // width of Goertzel result

    // ** FEED SIGNAL **
    // output signal is A(1,f) format, so f = SW-2
    wire signed [(SW-1):0] signal;
    wave_gen_CORDIC #(.OW(SW), .PW(16)) freq(
        .clk    (clk),      // input clock
        .rst    (1'b0),     // not used
        .i_phi  (16'd8579), // phase step value
        .cos    (),         // not used
        .sin    (signal)    // sine wave result, A(1,f)
    );

    wire cycle_complete;
    wire [(OW-1):0] Xk_re, Xk_im;

    goertzel_IIR #(.IW(SW), .N(N), .OW(OW)) goertzelAlgo (
        .i_clk          (clk),              // input clock
        .i_rst          (rst),              // synch reset
        .i_sample       (signal),           // Input signal, A(1,f) format
        .o_data_valid   (cycle_complete),   // Active-High output flag signaling result has been calculated
        .o_result_re    (Xk_re),            // Re{X(k)}, A(n,f) format
        .o_result_im    (Xk_im)             // Im{X(k)}, A(n,f) format
    );

    `ifdef SYNTH
        assign led = cycle_complete;
    `endif

endmodule
