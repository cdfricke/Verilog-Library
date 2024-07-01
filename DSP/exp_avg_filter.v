`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: The Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 06/21/2024 01:25:57 PM
// Module Name: EMA_IIR
// Project Name: Wave Synthesis
// Target Devices: CMOD S7
// Tool Versions: 
// Description: Infinite-duration impulse response filter designed for exponential 
// averaging of a signal.
//////////////////////////////////////////////////////////////////////////////////


module exp_avg_filter(clk, s_in, s_out);

    parameter   IW = 17, OW = IW+1;
    parameter   LGALPHA = 3;      // corresponds to a multiplication of 2^(-LGALPHA)

    input wire              clk;
    input wire  [(IW-1):0]  s_in;
    output wire [(OW-1):0]  s_out;

    // filter difference equation:
    // y[n] = y[n-1] + a * (x[n] - y[n-1])

    wire signed [(OW-1):0]  difference; // x[n] - y[n-1]
    wire signed [(OW-1):0]  adjustment; // a*(x[n] - y[n-1])
    reg signed  [(OW-1):0]  r_delay = 0; // y[n-1]

    // difference is given as x[n] - y[n-1]
    // adds (OW - IW) fractional bits to s_in (x[n]) for the subtraction.
    assign difference = {s_in, {(OW-IW){1'b0}}} - r_delay;

    assign adjustment = difference >>> LGALPHA;

    always @ (posedge clk) begin
        r_delay <= r_delay + adjustment;
    end

    assign s_out = r_delay;

endmodule
