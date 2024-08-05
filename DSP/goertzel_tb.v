`timescale 1ns / 1ps
`define CLK_PER 10
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


module goertzel_tb();

    reg rst = 1'b1;
    initial rst = #380 1'b0;
    reg clk = 1'b0;
    always clk = #(`CLK_PER/2) ~clk;
    

    // * DEFAULTS FOR GOERTZEL
    localparam SW = 12;             // signed signal width
    localparam N = 60;              // y[N] = X(k) (the result we want)
    localparam KW = $clog2(N);      // signed k width, needs to range from 0 to N/2, log2(N) bits gets us that
    localparam PIW = 15;            // width of unsigned constant PI localparam
    localparam PW = PIW+KW;         // phase 2*PI*k/N width
    localparam CW = 16;             // CORDIC output width
    localparam OW = 16;             // width of output and output delay registers

    // ** FEED SIGNAL **
    // output signal is A(1,f) format as required by the CORDIC IP
    wire signed [(SW-1):0] signal;
    wave_gen_CORDIC #(.OW(SW), .PW(16)) freq_5MHz(
        .clk(clk),
        .rst(1'b0),
        .i_phi(16'd8579),
        .cos(),
        .sin(signal)
    );

    goertzel_IIR goertzelAlgo(
        .i_clk      (clk),
        .i_rst      (rst),
        .i_sample   (signal)
    );


endmodule
