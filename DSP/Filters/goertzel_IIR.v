`timescale 1ns / 1ps
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
    parameter OW = 32
)
(
    input                   i_clk, i_rst,
    input signed [(IW-1):0] i_sample,       // Input signal, A(1,10) format
    output reg              o_data_valid,   // 1 clk cycle pulse each time results are latched to output regs
    output wire [(OW-1):0]  o_result_re,    // Re{X(k)}, A(1,10) format
    output wire [(OW-1):0]  o_result_im     // Im{X(k)}, A(1,10) format
);

    // * INITIALIZE DELAY REG MEMORY BLOCK *
    reg signed [(OW-1):0] d_mem [1:0];
    initial begin
        d_mem[0] = 0;
        d_mem[1] = 0;
    end

    // * COUNT SAMPLE # *
    localparam NW = $clog2(N);
    reg [(NW-1):0] n = 0;

    always @(posedge i_clk) begin
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
    wire signed [(OW-1):0] sum = i_sample + difference;

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
    // s[N-1], s[N-2] used for final calculation of X(k)
    reg signed [(OW-1):0] s [(N-1):(N-2)];
    initial begin
        s[N-1] = 0;
        s[N-2] = 0;
    end
    always @ (posedge i_clk) begin
        if ( n == (N-1) ) begin
            s[N-1] <= sum;
            s[N-2] <= d_mem[0];
        end
    end

    // * CALCULATE FINAL RESULTS, Re{X(k)}, Im{X(k)} *
    // Re{X(k)} = cos()*s[N-1] - s[N-2] = 0.5*s[N-1] - s[N-2]
    // Im{X(k)} = sin()*s[N-1]
    // given k/N = 1/6, 2*PI*k/N = PI/3, cos(PI/3) = 1/2, sin(PI/3) = ~0.866
    reg signed [7:0] SIN = 8'b01101111;     // = 111, or 0.8671875, A(0,7) format
    assign o_result_re = (s[N-1] >>> 1) - s[N-2];
    wire signed [(OW+7):0] mult = (SIN * s[N-1]) >>> 7;     // A(0,7) * A(a,b) = A(a+1, b+7) >>> 7 
    assign o_result_im = mult[(OW-1):0];  

    // * CONTROL DATA_VALID FLAG *
    initial o_data_valid <= 1'b0;
    always @ (posedge i_clk) begin
        if ( n == (N-1) ) o_data_valid <= 1'b1;    
        else o_data_valid <= 1'b0;
    end

endmodule