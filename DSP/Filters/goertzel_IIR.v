`timescale 1ns / 1ps
`include "interfaces.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: the Ohio State University
// Engineer: Connor Fricke (cd.fricke23@gmail.com)
// Create Date: 07/30/2024 12:07:03 PM
// Module Name: goertzel_IIR
// Project Name: Goertzel Simulation
//
// Description: 
// Fixed phase second-stage IIR Goertzel filter, cascade form. Phase is fixed with 
//      k/N = 1/6 -> 2*PI*k/N = PI/3 -> cos() = 1/2, sin() = ~0.866
// The difference equation for the IIR portion is given by:
//      s(n) = x(n) + 2cos()*s(n-1) - s(n-2),  where cos() = 1/2
//      s(n) = x(n) + s(n-1) - s(n-2)
// The DFT coefficient for k/N = 1/6 is then given by an algebraic simplification of
// the FIR portion of the filter:
//      X(k) = cos()*s(N-1) - s(N-2) + i*sin()*s(N-1)
//////////////////////////////////////////////////////////////////////////////////

module goertzel_IIR
#(
    parameter IW = 12,
    parameter N = 126,
    parameter OW = 20       // this may need to be increased if window size (N) is increased.   
)
(
    input                   i_clk,          // i_clk: FPGA Clock (expected 187.5 MHz)
    input                   i_rst,          // i_clk: external synchronous reset
    // AXI4-Stream INPUT Interface (FROM ADC)
    // `TARGET_NAMED_PORTS_AXI4S_MIN_IF(s_axis_, IW)
    input signed [(IW-1):0] s_axis_tdata,   // AXI4-S -> input data from ADC 
    input                   s_axis_tvalid,  // AXI4-S -> input flag that ADC data is valid (CURRENTLY UNUSED) (this flag is hopefully 1 always)
    output                  s_axis_tready,  // AXI4-S -> output to ADC that goertzel is ready to receive (this flag should be 1 always)
    
    // AXI4-Stream OUTPUT Interface (TO PROCESSING SYSTEM)
    // `HOST_NAMED_PORTS_AXI4S_MIN_IF(m_axis_, 2*OW)
    output [(2*OW-1):0]     m_axis_tdata,   // AXI4-S -> output result, a concatenation of Re{X(k)} and Im{X(k)}
    output                  m_axis_tvalid,  // AXI4-S -> output flag that calculation is complete
    input                   m_axis_tready   // AXI4-S -> input from PS that PS is ready to receive (CURRENTLY UNUSED)
);

    // this module should always be ready to receive data
    assign s_axis_tready = 1'b1;

    // * INITIALIZE DELAY REG MEMORY BLOCK *
    reg signed [(OW-1):0] d_mem [1:0];
    initial begin
        d_mem[0] = 0;
        d_mem[1] = 0;
    end

    // * COUNT SAMPLE # *
    localparam NW = $clog2(N);
    reg [(NW-1):0] n = 0;

    always @ (posedge i_clk) begin
        if ( i_rst || (n == (N-1)) ) n <= 0;
        else n <= n + 1;
    end

    // * COMBINATORIAL LOGIC STAGE, i.e. CALCULATE s[n] *
    // The standard difference equation for the IIR portion is 
    //  s(n) = x(n) + 2cos()s(n-1) - s(n-2)
    // however, we impose the constraint that k/N = 1/6 and thus cos(2pik/N) = cos(pi/3) = 1/2
    // and thus the difference equation we then implement is
    //  s(n) = x(n) + s(n-1) - s(n-2)
    wire signed [(OW-1):0] difference = d_mem[0] - d_mem[1];
    wire signed [(OW-1):0] sum = s_axis_tdata + difference;

    // * SHIFT MEMORY VALUES *
    always @ (posedge i_clk) begin
        if ( i_rst || (n == (N-1)) ) begin
            d_mem[0] <= 0;
            d_mem[1] <= 0;
        end else begin
            d_mem[0] <= sum;
            d_mem[1] <= d_mem[0];
        end
        
    end

    // * CALCULATE s[N-1], s[N-2] *
    // s[N-1], s[N-2] used for final (combinatoric) calculation of X(k)
    reg signed [(OW-1):0] s [(N-1):(N-2)];
    initial begin
        s[N-1] = 0;
        s[N-2] = 0;
    end
    always @ (posedge i_clk) begin
        if ( i_rst ) begin
                s[N-1] <= 0;
                s[N-2] <= 0;
        end else if ( n == (N-1) ) begin
                s[N-1] <= sum;
                s[N-2] <= d_mem[0];
        end
    end

    // * CALCULATE FINAL RESULTS, Re{X(k)}, Im{X(k)} *
    // Re{X(k)} = cos()*s[N-1] - s[N-2] = 0.5*s[N-1] - s[N-2]
    // Im{X(k)} = sin()*s[N-1]
    // given k/N = 1/6, 2*PI*k/N = PI/3, cos(PI/3) = 1/2, sin(PI/3) = ~0.866
    reg signed [7:0] SIN = 8'b01101111;                     // = 111, or 0.8671875, A(0,7) format
    wire [(OW-1):0] o_result_re = (s[N-1] >>> 1) - s[N-2];
    wire signed [(OW+7):0] mult = (SIN * s[N-1]) >>> 7;     // A(0,7) * A(a,b) = A(a+1, b+7) >>> 7 
    wire [(OW-1):0] o_result_im = mult[(OW-1):0];  
    
    assign m_axis_tdata = {o_result_re, o_result_im};           

    // * CONTROL DATA VALID FLAG *
    // first time a result is obtained, the flag goes high. Returns to zero only on rst
    reg o_data_valid;
    initial o_data_valid <= 1'b0;
    always @ (posedge i_clk) begin
        if ( i_rst ) o_data_valid <= 1'b0;
        else if ( n == (N-1) ) o_data_valid <= 1'b1;    
    end
    assign m_axis_tvalid = o_data_valid;    
    
endmodule