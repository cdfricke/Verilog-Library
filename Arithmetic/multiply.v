`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: the Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 06/27/2024 01:20:34 PM
// Module Name: multiply
// Description: module for multiplying values, with included bit growth management
//////////////////////////////////////////////////////////////////////////////////


module multiply(clk, en, a, b, out);

    // params
    parameter AW = 16;
    parameter BW = 16;
    localparam OW = AW + BW;

    // port declarations
    input wire                      clk;
    input wire                      en;
    input wire signed   [(AW-1):0]  a;
    input wire signed   [(BW-1):0]  b;
    output reg signed   [(OW-1):0]  out;

    always @ (posedge clk) begin
        if (en) out <= a * b;
        else out <= 0;
    end

endmodule
