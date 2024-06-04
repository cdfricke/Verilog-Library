`timescale 1ns / 1ps
`define CMOD_CLK_FREQ 12000000
//////////////////////////////////////////////////////////////////////////////////
// Company: The Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 04/11/2024 04:10:19 PM
// Module Name: led_counter
// Project Name: led_counting
// Target Devices: CMOD S7
// Description: 
//  
//////////////////////////////////////////////////////////////////////////////////

module led_counter(
    input clk, 
    input [1:0] btn,
    output [3:0] led,
    output [2:0] rgb
    );
    
    // *** 4 LEDs CONTROL ***
    wire enabled_second_pulse;
    second_counter #(.FREQ(`CMOD_CLK_FREQ)) 
        enabled_counter(.CLK(clk), .OUT(enabled_second_pulse), .CE(btn[0]), .RS(btn[1]));
    reg [3:0] led_count = 4'b0000;
    
    always @ (posedge clk) begin
        if (btn[1])   // RESET
            led_count <= 4'b0000;
        else begin
            if (enabled_second_pulse) begin
                led_count <= led_count + 1;
            end
        end
    end
    assign led = led_count;
    
    // *** R CONTROL ***
    wire second_pulse;
    reg red_LED = 1'b0;
    second_counter #(.FREQ(`CMOD_CLK_FREQ)) 
        counter(.CLK(clk), .OUT(second_pulse), .CE(1), .RS(0)); // always enabled, never reset
    always @ (posedge clk) begin
        if (second_pulse) red_LED <= ~red_LED;
    end
    assign rgb[0] = red_LED;
    // *** G CONTROL ***
    assign rgb[1] = 1'b1;
    // *** B CONTROL ***
    assign rgb[2] = ~red_LED;
    
endmodule
