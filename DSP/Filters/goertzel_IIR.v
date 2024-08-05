`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2024 12:07:03 PM
// Design Name: 
// Module Name: goertzel_IIR
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

module goertzel_IIR
#(
    parameter IW = 12,
    parameter N = 126,
    parameter OW = 32
)
(
    input i_clk, i_rst,
    input signed [(IW-1):0]         i_sample
);

    // * OUTPUT MEM BLOCK *
    reg signed [(OW-1):0] d_mem [1:0];
    initial begin
        d_mem[0] = 0;
        d_mem[1] = 0;
    end

    // * COUNT SAMPLES *
    localparam NW = $clog2(N);
    reg [(NW-1):0] n = 0;

    always @(posedge i_clk) begin
        if ( i_rst || (n == (N-1)) ) n <= 0;
        else n <= n + 1;
    end

    // * PERFORM ADDITIONS *
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

    // s[N], s[N-1], s[N-2] for final calculation
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

endmodule
