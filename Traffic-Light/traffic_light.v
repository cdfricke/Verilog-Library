`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: The Ohio State University
// Engineer: Patrick Allison
// 
// Create Date: 04/22/2024 04:05:43 PM
// Module Name: traffic_light
// Project Name: Traffic Light
// Target Devices: CMOD S7
// Description: 
// 
// Dependencies: module second_counter
// 
// 
//////////////////////////////////////////////////////////////////////////////////


module traffic_light(
    input CLK,
    output NS_RED,
    output NS_YELLOW,
    output NS_GREEN,
    output EW_RED,
    output EW_YELLOW,
    output EW_GREEN
    );
    
    // *** POSSIBLE STATES ***
    localparam FSM_BITS = $clog2(5);
    localparam [FSM_BITS-1:0] PAUSE = 0;
    localparam [FSM_BITS-1:0] NS_OK = 1;
    localparam [FSM_BITS-1:0] NS_WARN = 2;
    localparam [FSM_BITS-1:0] EW_OK = 3;
    localparam [FSM_BITS-1:0] EW_WARN = 4;
    
    // initialize state
    reg [FSM_BITS-1:0] state = PAUSE;
    
    // store previous direction, initialize as NS
    localparam NS = 0;
    localparam EW = 1;
    reg last_direction = NS;
    
    // store time of each state
    localparam OK_SEC = 20;
    localparam WARN_SEC = 5;
    localparam PAUSE_SEC = 2;
    localparam CNT_BITS = $clog2(OK_SEC - 1);
    reg [CNT_BITS-1:0] counter = 0;

    // *** STATE BEHAVIOR ***
    always @ (posedge CLK) begin
        case (state)
            PAUSE: begin
                if (counter == PAUSE_SEC - 1) begin
                    if (last_direction == NS)
                        state <= EW_OK;
                    else
                        state <= NS_OK;
                end
            end
            NS_OK: if (counter == OK_SEC - 1)
                state <= NS_WARN;
            NS_WARN: if (counter == WARN_SEC - 1)
                state <= PAUSE;
            EW_OK: if (counter == OK_SEC - 1)
                state <= EW_WARN;
            EW_WARN: if (counter == WARN_SEC - 1)
                state <= PAUSE;
            default: state <= PAUSE;
        endcase
    end

    // *** STATE OUTPUT ***
    reg [0:0] ns_red = 0;
    reg [0:0] ns_yellow = 0;
    reg [0:0] ns_green = 0;
    reg [0:0] ew_red = 0;
    reg [0:0] ew_yellow = 0;
    reg [0:0] ew_green = 0;

    // wire outputs to regs
    assign NS_RED = ns_red;
    assign NS_YELLOW = ns_yellow;
    assign NS_GREEN = ns_green;
    assign EW_RED = ew_red;
    assign EW_YELLOW = ew_yellow;
    assign EW_GREEN = ew_green;

    always @ (state) begin
        case (state)
            PAUSE: begin
                ns_red <= 1;
                ns_yellow <= 0;
                ns_green = 0;
                ew_red <= 1;
                ew_yellow <= 0;
                ew_green = 0;
            end
            NS_OK: begin
                ns_red <= 0;
                ns_yellow <= 0;
                ns_green = 1;
                ew_red <= 1;
                ew_yellow <= 0;
                ew_green = 0;
            end
            NS_WARN: begin
                ns_red <= 0;
                ns_yellow <= 1;
                ns_green = 0;
                ew_red <= 1;
                ew_yellow <= 0;
                ew_green = 0;
            end
            EW_OK: begin
                ns_red <= 1;
                ns_yellow <= 0;
                ns_green = 0;
                ew_red <= 0;
                ew_yellow <= 0;
                ew_green = 1;
            end
            EW_WARN: begin
                ns_red <= 1;
                ns_yellow <= 0;
                ns_green = 0;
                ew_red <= 0;
                ew_yellow <= 1;
                ew_green = 0;
            end
            default: begin
                ns_red <= 1;
                ns_yellow <= 0;
                ns_green = 0;
                ew_red <= 1;
                ew_yellow <= 0;
                ew_green = 0;
            end
        endcase
    end

    // *** SUPPORT LOGIC ***
    // switch last direction when we enter the NS_OK or EW_OK states
    always @ (posedge CLK) begin
        if (state == NS_OK) last_direction <= NS;
        else if (state == EW_OK) last_direction <= EW;
    end
    // counter needs to reset when a state transition happens
    wire pulse_per_second;
    second_counter pps(.CLK(CLK), .CE(1), .RS(0), .OUT(pulse_per_second));

    always @ (posedge CLK) begin
        if (pulse_per_second) begin
            if (state == NS_OK || state == EW_OK) begin
                if (counter < OK_SEC - 1) counter <= counter + 1;
                else counter <= 0;
            end
            else if (state == NS_WARN || state == EW_WARN) begin
                if (counter < WARN_SEC - 1) counter <= counter + 1;
                else counter <= 0;
            end
            else if (state == PAUSE) begin
                if (counter < PAUSE_SEC - 1) counter <= counter + 1;
                else counter <= 0;
            end
            else counter <= 0;
        end
    end
    
endmodule
