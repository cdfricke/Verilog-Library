`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2024 03:12:08 PM
// Design Name: 
// Module Name: top_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_module(
    input clk,
    output pio1,
    output pio2,
    output pio3,
    output pio4,
    output pio5,
    output pio6
    );

    traffic_light myLight(.CLK(clk), .NS_RED(pio1), .NS_YELLOW(pio2), .NS_GREEN(pio3), .EW_RED(pio4), .EW_YELLOW(pio5), .EW_GREEN(pio6));
    
endmodule
