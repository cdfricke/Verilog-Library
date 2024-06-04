`timescale 1ns / 1ps
`define CMOD_CLK_FREQ 12000000
//////////////////////////////////////////////////////////////////////////////////
// Company: The Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 04/11/2024 03:34:37 PM
// Module Name: blinky
// Project Name: blinky
// Target Devices: CMOD S7
// Description: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module blinky(
    input CLK,
    output [3:0] LED
    );
    
    localparam NUM_LEDS = 4;
    
    generate
        genvar i;
        for (i = 0; i < NUM_LEDS; i = i + 1) begin : BLINK
            second_counter #(.FREQ(`CMOD_CLK_FREQ)) blinky_blinky(.CLK(CLK), .out(LED[i]));
        end
    endgenerate
    
endmodule
