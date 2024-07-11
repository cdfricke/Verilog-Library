`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: the Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 06/27/2024 02:21:27 PM
// Module Name: accumulate
// Description: 
//////////////////////////////////////////////////////////////////////////////////


module accumulate(clk, en, rst, sum, add);

    parameter HIGH = 65536;             // highest value that sum can take, 2^16 by default
    parameter LOW = 0;                  // lowest value, which accumulator will reset to
    parameter WIDTH = $clog2(HIGH);    // width of accumulator

    // port declarations
    input wire                        clk, en, rst;
    input wire        [(WIDTH-1):0]   add;
    output reg signed [(WIDTH-1):0]   sum;

    initial begin
        sum <= LOW;
    end

    always @ (posedge clk) begin
        if (en) begin
            if (rst || (sum == HIGH)) sum <= LOW;
            else sum <= sum + add;
        end
    end

endmodule
