`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: The Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 04/11/2024 03:40:39 PM
// Module Name: second_counter
// Project Name: LED Counting
// Target Devices: CMOD S7
// Description: second_counter module parameterized to frequency of internal clock signal (.FREQ).
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module second_counter(
    input CLK,                  // internal clock
    output out                  // output signal high on clock cycle that counter rolls over
    );

    parameter FREQ = 12000000;              // parameterize for different clk speeds
    localparam NBITS = $clog2(FREQ - 1);    // calculate number of bits needed to store counter
    reg [NBITS-1:0] counter = 0;            // counter register
    reg flip = 1'b0;                        // output signal will match this register
    
    always @ (posedge CLK) begin
        if (counter == FREQ - 1) begin
            counter <= 0;
            flip <= ~flip;
        end
        else
            counter <= counter + 1;
    end
    
    assign out = flip;
    
endmodule
