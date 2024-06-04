`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: The Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 04/11/2024 03:40:39 PM
// Module Name: second_counter
// Project Name: Traffic Light
// Target Devices: CMOD S7
// Description: second_counter module parameterized to frequency of internal clock signal (.FREQ).
// Outputs a single clock cycle flag when the counter rolls over.
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module second_counter(
    input CLK,                  // internal clock
    input CE,                   // clock enable
    input RS,                   // reset
    output OUT                  // output signal high on clock cycle that counter rolls over
    );

    parameter FREQ = 12000000;              // parameterize for different clk speeds
    localparam NBITS = $clog2(FREQ - 1);    // calculate number of bits needed to store counter
    reg [NBITS-1:0] counter = 0;            // counter register
    reg q_out;                              // output register
    
    always @ (posedge CLK) begin
        if (RS)
            counter <= 0;
        if (CE) begin
            if (counter == FREQ - 1) begin
                counter <= 0;
                q_out <= 1;
            end
            else begin
                counter <= counter + 1;
                q_out <= 0;
            end;
        end
    end
    
    assign OUT = q_out;
    
endmodule
