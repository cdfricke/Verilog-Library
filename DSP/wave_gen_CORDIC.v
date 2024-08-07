`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: The Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 06/19/2024 12:41:41 PM
// Module Name: wave_gen_CORDIC
// Project Name: Wave Synthesis
// Description: wrapper module of the CORDIC IP for since/cosine wave generation
// 
// Dependencies: 
//  AMD Xilinx - CORDIC IP
//////////////////////////////////////////////////////////////////////////////////


module wave_gen_CORDIC
#(
    parameter OW = 16,          // CORDIC IP "Output Width"
    parameter PW = 16           // CORDIC IP "Input Width"
)
(
    input wire                      clk, rst,
    input wire signed   [(PW-1):0]  i_phi,
    output wire signed  [(OW-1):0]  cos,
    output wire signed  [(OW-1):0]  sin
);

    // +- pi in fixed point notation 1.2.13
    localparam signed [(PW-1):0] PI_POS = 16'b0110_0100_1000_1000; 
    localparam signed [(PW-1):0] PI_NEG = 16'b1001_1011_0111_1000; 

    // NOTE:
    // output frequency is quantized significantly. See my Python script DSP.py @ https://github.com/cdfricke/DSP

    reg signed  [(PW-1):0]  phase = 0;
    reg                     phase_tvalid = 1'b0;
    wire                    sincos_tvalid;
    wire [31:0]             out;

    // instantiate wave synthesizer module
    cordic_1 CORDIC_12bit (
        .aclk               (clk),                  // input clock
        .s_axis_phase_tvalid(phase_tvalid),         // input valid flag
        .s_axis_phase_tdata (phase),                // input phase
        .m_axis_dout_tvalid (sincos_tvalid),        // output valid flag
        .m_axis_dout_tdata  (out)                   // output signals
    );

    // bit select comes from implementation details in CORDIC IP customizer
    assign sin = out[27:16];
    assign cos = out[11:0];

    // drive phase input to wave generator
    // phase starts at zero, increments in steps of PHASE_INC up to +pi, then flips to -pi.
    always @ (posedge clk) begin
        if (rst) begin
            phase <= 0;
            phase_tvalid <= 1'b0;
        end else begin
            phase_tvalid = 1'b1;
            if (phase + i_phi < PI_POS) begin
                phase <= phase + i_phi;
            end else begin
                phase <= PI_NEG;
            end
        end
    end
endmodule
