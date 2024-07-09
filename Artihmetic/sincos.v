`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: the Ohio STate University
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
#(  parameter PW=8, // phase width
    parameter OW=8  // output width
)
(
    input wire clk,
    input wire en,
    input wire [(PW-1):0]   phase,  // input to CORDIC

    output wire [(OW-1):0]   sin,    // imaginary from CORDIC
    output wire [(OW-1):0]   cos     // real from CORDIC
);

    wire valid;
    cordic_0 CORDIC_8bit (
        .aclk(clk),                                
        .s_axis_phase_tvalid(en),  
        .s_axis_phase_tdata(phase),        // phase input is 1.2.5 format
        .m_axis_dout_tvalid(valid),    
        .m_axis_dout_tdata({sin,cos})      // sin and cos both 1.1.6 format
    );

endmodule
