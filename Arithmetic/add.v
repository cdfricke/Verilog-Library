`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: the Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 06/27/2024 01:02:14 PM
// Module Name: add.v
// Description: module for adding values, with included bit growth management
//////////////////////////////////////////////////////////////////////////////////

module add(clk, en, a, b, out);

    // params
    parameter AW = 16;
    parameter BW = 16;
    localparam OW = (AW > BW) ? (AW + 1) : (BW + 1);

    // port declarations
    input wire                      clk, en;
    input wire signed [(AW-1):0]    a;
    input wire signed [(BW-1):0]    b;
    output reg signed [(OW-1):0]    out;

    always @ (posedge clk) begin
        if (en) out <= a + b;
        else out <= 0;
    end
        
endmodule
