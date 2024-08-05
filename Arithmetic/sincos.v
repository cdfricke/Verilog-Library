`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: the Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 06/28/2024 04:20:11 PM
// Module Name: sincos
// Project Name: FPGA Arithmetic 
// Description: Module used for solving sine and cosine functions using CORDIC IP
// 
// Dependencies: 
//  CORDIC IP
//////////////////////////////////////////////////////////////////////////////////


module sincos 
#(  
    parameter PW=16, // phase width
    parameter OW=16  // output width
)
(
    input wire              i_clk,      // clock
    input wire              i_valid,    // high when phase input is valid
    input wire              i_rst,      // asynch reset for CORDIC IP
    input wire [(PW-1):0]   i_phase,    // input to CORDIC, radians -> A(2,f)

    output wire [(OW-1):0]  sin,        // sin(i_phase) -> A(1,f)
    output wire [(OW-1):0]  cos,        // cos(i_phase) -> A(1,f)
    output wire             o_valid     // high when output is valid
);

    wire [31:0] out;

    cordic_0 CORDIC (
        .aclk                   (i_clk),  
        .aresetn                (~i_rst),                              
        .s_axis_phase_tvalid    (i_valid),  
        .s_axis_phase_tdata     (i_phase),
        .m_axis_dout_tvalid     (o_valid),  
        .m_axis_dout_tdata      (out) 
    );

    // bit select comes from implementation details in CORDIC IP customizer
    assign sin = out[31:16];
    assign cos = out[15:0];

endmodule
