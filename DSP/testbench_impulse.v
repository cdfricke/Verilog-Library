`timescale 1ns / 1ps
`define DEBUG
`define SIMCLK
`define CMOD_CLK_PER 83.33
//////////////////////////////////////////////////////////////////////////////////
// Company: the Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 07/01/2024 11:07:06 AM
// Module Name: testbench_impulse
// Project Name: Signal Processing
// Target Devices: CMOD S7
// Description: Impulse generation testbench using signal generator module.
// 
// Dependencies:
//  wave_gen_CORDIC.v
//  CORDIC IP
//////////////////////////////////////////////////////////////////////////////////


module testbench_impulse(
    `ifndef SIMCLK
        input clk,
    `endif
    );

    `ifdef SIMCLK
        // drive clock behavior with delays
        reg clk = 1'b0;
        always clk = #(`CMOD_CLK_PER/2) ~clk;
    `endif

    localparam NUM_COMPONENTS = 12;
    localparam IW=16;                           // input (phase) width
    localparam OW=16;                           // output (cos) width
    localparam SW=OW+$clog2(NUM_COMPONENTS);    // signal width
    
    reg signed [(IW-1):0] phi_mem [0:(NUM_COMPONENTS-1)];
    initial begin
        $readmemh("phase_increments.mem", phi_mem);
    end

    // instantiate the module several times
    wire signed [(OW-1):0]  cos [0:(NUM_COMPONENTS-1)];
    wire signed [(OW-1):0]  sin [0:(NUM_COMPONENTS-1)];
    wire signed [(SW-1):0]  signal;

    generate for (genvar i = 0; i < NUM_COMPONENTS; i = i + 1) begin : COMPONENTS
            wave_gen_CORDIC generator(
                .clk    (clk),
                .rst    (1'b0),
                .i_phi  (phi_mem[i]),
                .cos    (cos[i]),
                .sin    (sin[i])
            );
    end
    endgenerate

    assign signal = cos[0] + cos[1] + cos[2] + cos[3] + cos[4] + cos[5] + cos[6] + cos[7] + cos[8] + cos[9] + cos[10] + cos[11];

endmodule
