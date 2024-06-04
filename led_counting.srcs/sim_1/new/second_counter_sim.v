`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/15/2024 11:31:04 AM
// Design Name: 
// Module Name: second_counter_sim
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

module led_counter_tb;

    reg CLK = 0;
    reg [1:0] BTN = 2'b01;
    wire red_LED;
    wire green_LED;
    wire blue_LED;
    wire [3:0] LED;
    
    always begin
        #41.66 CLK = ~CLK;
    end
    
    // UNIT UNDER TEST
    led_counter uut(CLK, BTN, LED, red_LED, green_LED, blue_LED);
    
    
endmodule
