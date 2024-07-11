`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: the Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 06/28/2024 11:03:35 AM
// Module Name: drop_bits
// Project Name: FPGA Arithmetic
// Description: various ways of shrinking the bit width of a value
// TRUNCATE : TYPE == 0
// ROUND HALF UP : TYPE == 1
// ROUND HALF TOWARDS ZERO : TYPE == 2
// ROUND TO NEAREST EVEN INT : TYPE == 3
// Using this module is not the most resource efficient method, and the computation 
// requires a single clock delay for all types of rounding. It's primary purpose is
// to keep a record of the available methods and how to implement them.
//////////////////////////////////////////////////////////////////////////////////


module drop_bits(clk, in, out);

    // optional parameters. truncates 4 bits by default
    parameter TYPE = 0;
    parameter IW = 16;
    parameter OW = IW-4;

    // rounding types
    localparam TRUNCATE = 0;        // biased. drops the last N bits
    localparam ROUND_UP = 1;        // biased. adds one half, then drops the last N bits
    localparam ROUND_TO_ZERO = 2;   // unbiased, but will change the signal amplitude. rounds all values towards zero
    localparam ROUND_TO_EVEN = 3;   // unbiased

    // port declarations
    input wire                      clk;
    input wire signed [(IW-1):0]    in;
    output reg signed [(OW-1):0]    out;

    // for rounding half up
    wire [(IW-1):0] w_halfup;
    assign w_halfup = in[(IW-1):0] + { {(OW-1){1'b0}}, 1'b1, {(IW-OW-1){1'b0}} };

    // for rounding half towards zero
    wire [(IW-1):0] w_tozero;
    assign	w_tozero = in[(IW-1):0] + { {(OW){1'b0}}, in[(IW-1)], {(IW-OW-1){!in[(IW-1)]}} };

    // for rounding half towards nearest even number
    wire [(IW-1):0] w_toeven;
    assign	w_toeven = in[(IW-1):0] + { {(OW){1'b0}}, in[(IW-OW)], {(IW-OW-1){!in[(IW-OW)]}} };

    // all methods require one clock cycle in this module, but truncation is possible without a clk.
    // see here: https://zipcpu.com/dsp/2017/07/22/rounding.html
    always @ (posedge clk) begin
        case (TYPE)
            TRUNCATE: begin
                out <= in[(IW-1):(IW-OW)];
            end
            ROUND_UP: begin
                out <= w_halfup[(IW-1):(IW-OW)];
            end
            ROUND_TO_ZERO: begin
                out <= w_tozero[(IW-1):(IW-OW)];
            end
            ROUND_TO_EVEN: begin
                out <= w_toeven[(IW-1):(IW-OW)];
            end
            default: begin
                out <= in[(IW-1):(IW-OW)];
            end
        endcase
    end

    


        
endmodule
