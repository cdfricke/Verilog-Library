`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/11/2024 03:40:39 PM
// Design Name: 
// Module Name: counter_12MHz
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


module counter_12MHz(
    input CLK, CE,
    output out
    );
    // flip this each time the count resets
    reg flip = 1'b0;
    // we want to count to 6 million, we need 23 bits
    // because 2^23 is ~ 8 million
    reg [22:0] count = 0;
    
    always @ (posedge CLK) begin
        // each clock cycle, increment count if counting is enabled
        if (CE)
            count <= count + 1;
        // if our count has reached 3 mil, reset the counter to zero
        // this corresponds to flipping every quarter second
        if (count == 23'd2_999_999) begin
            count <= 1'd0;
            flip <= ~flip;
        end
    end
    
    // output should match the value of flip, which flips every half second (assuming 12 MHz clock)
    assign out = flip;
    
endmodule
