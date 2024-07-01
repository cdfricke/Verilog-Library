`timescale 1ns / 1ps
`define SIMCLK
`define CMOD_CLK_PER 83.33
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/01/2024 11:07:06 AM
// Design Name: 
// Module Name: testbench
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


module testbench(
    `ifndef SIMCLK
        input clk
    `endif
    );

    `ifdef SIMCLK
        // drive clock behavior with delays
        reg clk = 1'b0;
        always clk = #(`CMOD_CLK_PER/2) ~clk;
    `endif

    localparam NUM_COMPONENTS = 16;
    localparam IW=16;                           // input (phase) width
    localparam OW=16;                           // output (cos) width
    localparam SW=OW+$clog2(NUM_COMPONENTS);    // signal width
    localparam FW=SW+1;                         // filtered signal width

    // phase increment requirements for various resulting frequencies from CORDIC wave generator
    localparam PHI_50kHz = 215;
    localparam PHI_100kHz = 429;
    localparam PHI_150kHz = 644;
    localparam PHI_200kHz = 858;
    localparam PHI_250kHz = 1073;
    localparam PHI_300kHz = 1287;
    localparam PHI_353kHz = 1514;
    localparam PHI_400kHz = 1716;
    localparam PHI_444kHz = 1907;
    localparam PHI_500kHz = 2145;
    localparam PHI_545kHz = 2340;
    localparam PHI_600kHz = 2574;

    function integer idx_to_inc;
        input integer idx;
        begin
            case (idx)
                0: idx_to_inc = PHI_50kHz;
                1: idx_to_inc = PHI_100kHz;
                2: idx_to_inc = PHI_150kHz;
                3: idx_to_inc = PHI_200kHz;
                4: idx_to_inc = PHI_250kHz;
                5: idx_to_inc = PHI_300kHz;
                6: idx_to_inc = PHI_353kHz;
                7: idx_to_inc = PHI_400kHz;
                8: idx_to_inc = PHI_444kHz;
                9: idx_to_inc = PHI_500kHz;
                10: idx_to_inc = PHI_545kHz;
                11: idx_to_inc = PHI_600kHz;
            endcase
        end
    endfunction

    // instantiate the module several times
    wire signed [(OW-1):0]  cos [0:(NUM_COMPONENTS-1)];
    wire signed [(OW-1):0]  sin [0:(NUM_COMPONENTS-1)];

    generate for (genvar i = 0; i < NUM_COMPONENTS; i = i + 1) begin
        wave_gen_CORDIC #(.PHASE_INC(i+1)) generator(
            .clk    (clk),
            .rst    (1'b0),
            .cos    (cos[i]),
            .sin    (sin[i])
        );
    end
    endgenerate

    // combine then filter components
    wire signed [(SW-1):0] signal;
    wire signed [(FW-1):0] filtered;

    assign signal = cos[0] + cos[1] + cos[2] + cos[3] 
                + cos[4] + cos[5] + cos[6] + cos[7] 
                + cos[8] + cos[9] + cos[10] + cos[11] 
                + cos[12] + cos[13] + cos[14] + cos[15];

    exp_avg_filter #(.LGALPHA(12), .IW(SW)) EMA_IIR(
        .clk    (clk),
        .s_in   (signal),
        .s_out  (filtered)
    );

    
    


endmodule
