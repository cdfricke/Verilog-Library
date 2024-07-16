`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: the Ohio State University
// Engineer: Connor Fricke
// Create Date: 07/16/2024 06:09:33 PM
// Module Name: goertzel
// Project Name: goertzel
// Target Devices: Arty A7-35T
// Description: Second Order Goertzel DFT Algorithm
//////////////////////////////////////////////////////////////////////////////////


module goertzel
#(
    parameter SW=12,            // signal sample width
    parameter KW=12,            // k_freq width
    parameter PIW=16,           // width of PI localparam
    parameter LGN=8,            // N = 2^LGN
    parameter OW=32
)
(
    input wire                      i_clk,        // clock
    input wire signed [(SW-1):0]    i_sample,   // sample of input signal
    input wire signed [(KW-1):0]    i_kfreq,
    output reg signed [(OW-1):0]    o_result_re,
    output reg signed [(OW-1):0]    o_result_im
);

    // ** CALCULATE (2 * PI * k / N) **
    // to calculate this phase value, and assuming that N is some positive power of 2, we know the result has a width of (PI_WIDTH + K_WIDTH + 1 - LGN)
    // because the mult by 2 is equivalent to a left shift by 1 bit, and the division by N is equivalent to a right (arithmetic) shift by LGN bits.
    // since we know N > 2, we can just shift right by LGN - 1 instead of shifting left then right.
    localparam PIW = 16;            // width of constant PI localparam
    localparam PW = PIW+KW+1-LGN;   // phase 2*PI*k/N width
    localparam CW = PW;             // CORDIC output width
    localparam signed [(PIW-1):0] PI = 16'b0110010010001000; // == 3.1416015625 (1.2.13)
    wire signed [(PIW+KW-LGN):0] phase;

    assign phase = (PI*i_kfreq) >>> (LGN - 1);

    // calculate cos and sin of phase (we need both)
    wire trig_valid;
    wire signed [(CW-1):0] cos, sin;
    sincos #(.PW(PW), .OW(CW)) trigFunc(
        .i_clk(i_clk),
        .i_valid(1'b1),
        .i_rst(1'b0),
        .i_phase(phase),
        .o_valid(trig_valid),
        .cos(cos),
        .sin(sin)
    );

    // Delay registers
    reg [(SW-1):0] dr [0:2];
    initial begin
        dr[0] <= 1'b0;
        dr[1] <= 1'b0;
        dr[2] <= 1'b0;
    end

    
endmodule
