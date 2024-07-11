`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: the Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 06/28/2024 02:58:22 PM
// Module Name: complex_mult
// Project Name: FPGA Arithmetic
// Description: performs a multiplication of two complex numbers
//////////////////////////////////////////////////////////////////////////////////


module complex_mult
#(  parameter AW=16,    // A factor width (of each component)
    parameter BW=16,    // B factor width (of each component)
    parameter MW=AW+BW, // width of terms prior to addition
    parameter OW=MW+1   // width of output
)
(
    input wire                      clk,    // input clock  
    input wire                      ce,     // enable       
    input wire signed [(AW-1):0]    a_re,   // real part of factor a
    input wire signed [(AW-1):0]    a_im,   // imaginary part of factor a
    input wire signed [(BW-1):0]    b_re,   // real part of factor b
    input wire signed [(BW-1):0]    b_im,   // imaginary part of factor b   

    output reg signed [(OW-1):0]    out_re, // real part of multiplication result
    output reg signed [(OW-1):0]    out_im  // imaginary part of multiplication result
);

    // A * B = (Re[A] + i*Im[A]) x (Re[B] + i*Im[B]) 
    //       = Re[A]*Re[B] + i*Im[A]*Re[B] + i*Re[A]*Im[B] + i*i*Im[A]*Im[B]
    //       = Re[A]*Re[B] - Im[A]*Im[B] + i(Im[A]*Re[B] + Re[A]*Im[B])
    
    wire signed [(MW-1):0] mult_reals;
    assign mult_reals = a_re * b_re;    // Re[A]*Re[B]
    
    wire signed [(MW-1):0] mult_ims;
    assign mult_ims = a_im * b_im;      // Im[A]*Im[B]

    wire signed [(MW-1):0] cross_term1;
    assign cross_term1 = a_im * b_re;   // Im[A]*Re[B]

    wire signed [(MW-1):0] cross_term2;
    assign cross_term2 = a_re * b_im;   // Re[A]*Im[B]

    always @ (posedge clk) begin
        if (ce) begin
            out_re <= mult_reals - mult_ims;
            out_im <= cross_term1 + cross_term2;
        end else begin
            out_re <= 0;
            out_im <= 0;
        end
    end

endmodule
