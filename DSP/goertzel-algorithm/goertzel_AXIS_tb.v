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
// Current Results: A(8,7)
// t_init   Re      Im
// 210      6985    -4034          
// 220      -4      8074 
// 230      -6982   -4041
// 240      6985    -4034

`timescale 1ns / 1ps
`define RF_CLK_PER 2.667
`define GZ_CLK_PER 5.334
`define SIM     // must be either SYNTH or SIM

module goertzel_tb(
    `ifdef SYNTH
        input clk,
        input rst,
        output led
    `endif
);

    `ifdef SIM
        reg rst = 1'b1;
        initial rst = #260 1'b0;
        // 375 MHz Clock for Wave Generation
        reg rf_clk = 1'b0;
        always rf_clk = #(`RF_CLK_PER/2) ~rf_clk;
        // 187.5 MHz Clock - GZ Algorithm takes every OTHER sample from wave gen
        reg gz_clk = 1'b0;
        always gz_clk = #(`GZ_CLK_PER/2) ~gz_clk;
    `endif

    // ** PARAMS **
    localparam SIW = 13;    // signed signal width
    localparam N = 126;     // y[N] = X(k) (the result we want)
    localparam OW = 20;     // width of Goertzel result
    localparam SAW = 16;    // width of a single ADC sample
    localparam DROP_BITS = OW - SAW;

    // ** FEED SIGNAL **
    wire signed [(SIW-1):0] signal;
    wave_gen_CORDIC #(.OW(SIW), .PW(16)) freq(
        .clk    (rf_clk),   // input clock (375 MHz)
        .rst    (1'b0),    
        .i_phi  (16'd4290), // phase increment value to create 31.25 MHz wave
        .cos    (),         
        .sin    (signal)    // sine wave result -> 12 bit
    );

    /* CLKEN SIGNAL CONTROL FOR GOERTZEL -> Allows only one of every two RFCLK samples to be registered by GZ module */
    reg div2 = 1'b0;
    always @ (posedge rf_clk) div2 <= ~div2;

    // AXI-S Output from GZ
    wire [((2*OW)-1):0] gz0_tdata;
    wire [(SAW-1):0] gz0_re;
    wire [(SAW-1):0] gz0_im;
    wire gz0_tvalid;

    goertzel_IIR #(.IW(SIW), .N(N), .OW(OW)) goertzelAlgo (
        .i_clk          (rf_clk),           // RF Clock (375 MHz)
        .i_clken        (div2),             // Clock Dividing clken signal, so that this module only registers every OTHER sample
        .i_rst          (rst),         
        .s_axis_tdata   (signal),           // Input 12-bit Sine Wave (31.25 MHz)
        .s_axis_tvalid  (1'b1),             // Assume input data always valid
        .s_axis_tready  (),                 
        .m_axis_tdata   (gz0_tdata),   // output data, OW*2 bits wide (re and im components each OW bits)
        .m_axis_tvalid  (gz0_tvalid),       
        .m_axis_tready  ()                  
    );
    assign gz0_re = gz0_tdata[39:24];       // A(n,9)
    assign gz0_im = gz0_tdata[19:4];        // A(n,9)

    // ** AXI4-S Interface for GZ to PS **
    wire [127:0] gz_results_tdata = {{96{1'b0}}, gz0_re, gz0_im};     // 6 samples of all zeros, then last two samples are the top 16 bits of Goertzel components
    wire gz_results_tvalid = 1'b1;      // TODO: TEST BEHAVIOR IF THIS IS ASSIGNED TO gz0_tvalid
    wire gz_results_tready;             // nc

    `ifdef SYNTH
        assign led = data_valid;
    `endif

endmodule
