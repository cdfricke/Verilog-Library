`timescale 1ns / 1ps
`define CMOD_CLK_PER 83.33
`define DEBUG
//`define SIMCLK
//////////////////////////////////////////////////////////////////////////////////
// Company: The Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 06/19/2024 10:23:10 AM
// Module Name: testbench
// Project Name: DDS Compiler and CORDIC Algorithm IP Testbench 
// Target Devices: CMOD S7
// Description:
//  FPGA Revolution @ YT: FPGA 18 - AMD Xilinx Verilog CORDIC Sine/Cosine Generator
//////////////////////////////////////////////////////////////////////////////////


module testbench(
    `ifndef SIMCLK
        input clk
    `endif
    );

    `ifdef SIMCLK
        // drive clock behavior with delays
        reg clk = 1'b0;
        initial begin
            clk = 1'b0;
        end
        always begin
            clk = #(`CMOD_CLK_PER/2) ~clk;
        end
    `endif

    // UNIT UNDER TEST: wave_gen_CORDIC.v
    wire signed [15:0]  cos_500kHz;      // 1.1.14 fixed point
    wire signed [15:0]  sin_500kHz;      // 1.1.14 fixed point
    wave_gen_CORDIC  #(.PHASE_INC(2145)) uut_500kHz(
        .clk(clk), 
        .rst(1'b0), 
        .cos(cos_500kHz), 
        .sin(sin_500kHz)
    );

    wire signed [15:0]  cos_1MHz;        // 1.1.14
    wire signed [15:0]  sin_1MHz;        // 1.1.14
    // F_OUT = (PHASE_INC * CLK_FREQ) / 51,472
    wave_gen_CORDIC  #(.PHASE_INC(4290)) uut_1MHz(
        .clk(clk), 
        .rst(1'b0), 
        .cos(cos_1MHz), 
        .sin(sin_1MHz)
    );

    wire signed [15:0]  cos_2MHz;        // 1.1.14 
    wire signed [15:0]  sin_2MHz;        // 1.1.14
    wave_gen_CORDIC  #(.PHASE_INC(8579)) uut_2MHz(
        .clk(clk), 
        .rst(1'b0), 
        .cos(cos_2MHz), 
        .sin(sin_2MHz)
    );

    // We might want to use the DDS compiler when the quantization of output frequencies of the CORDIC
    // wave generator is problematic. For example, a frequency like 2.8 MHz is rounded to 3 MHz by the
    // CORDIC wave generator but not rounded by the DDS Compiler
    wire signed [7:0]   cos_2_8MHz;     // 1.0.7
    wire signed [15:0]  cos_2_8MHz_wc;  // 1.0.15
    wire signed [7:0]   sin_2_8MHz;     // 1.0.7
    wire signed [15:0]  sin_2_8MHz_wc;  // 1.0.15
    wire                data_valid;

    wave_gen_DDS uut_2_8MHz (
        .aclk(clk),                              
        .m_axis_data_tvalid(data_valid),
        .m_axis_data_tdata({sin_2_8MHz, cos_2_8MHz}) 
    );

    // pad fractional bits to correct width to match CORDIC wave generator outputs
    assign cos_2_8MHz_wc = {cos_2_8MHz, {8{1'b0}}};
    assign sin_2_8MHz_wc = {sin_2_8MHz, {8{1'b0}}};

    // 
    reg signed [17:0]   outputCos;      // 1.3.14
    reg signed [17:0]   outputSin;      // 1.3.14
    always @ (posedge clk) begin
        outputCos <= cos_500kHz + (cos_1MHz >>> 1) + (cos_2MHz >>> 2) + (cos_2_8MHz_wc >>> 2);
        outputSin <= sin_500kHz + (sin_1MHz >>> 1) + (sin_2MHz >>> 2) + (sin_2_8MHz_wc >>> 2);
    end

    // ** FILTER SIGNAL **
    // filter increases bit width by 1 via padding of fraction bits so we go from 18-bit (1.3.14) -> 19-bit (1.3.15)
    wire signed [18:0] filteredCos;
    EMA_IIR #(.LGALPHA(3)) smoothingFilter (.clk(clk), .s_in(outputCos), .s_out(filteredCos));

    `ifdef DEBUG
    ila_0 debuggerILA(
        .clk(clk), 
        .probe0(cos_500kHz), 
        .probe1(cos_1MHz),
        .probe2(cos_2MHz),
        .probe3(cos_2_8MHz_wc),
        .probe4(outputCos),
        .probe5(filteredCos)
    );
    `endif

endmodule