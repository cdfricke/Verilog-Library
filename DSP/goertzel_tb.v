`timescale 1ns / 1ps
`define CLK_PER 10
//////////////////////////////////////////////////////////////////////////////////
// Company: the Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 07/18/2024 11:10:50 AM
// Module Name: goertzel_tb
// Project Name: Goertzel Sim
// Target Devices: Arty A7
// Description: Testbench for the Second Order Goertzel Algorithm digital filter
// 
// Dependencies: 
//  CORDIC IP, Sincos Module, Goertzel Module
//////////////////////////////////////////////////////////////////////////////////


module goertzel_tb();

    // from our C++ model, we expect that if we have a 100 MHz clock with a signal coming in at 
    // 5 MHz, and we take 256 samples for our Goertzel algorithm, we expect our Goertzel result
    // to be large at k values of +- 13, thus, to test this we should force parameters 
    // N = 256 (LGN = 8)
    // k = 13

    // U(a,b) denotes unsigned fixed point values with 'a' integer bits and 'b' fractional bits
    // A(a,b) denotes   signed fixed point values with 'a' integer bits and 'b' fractional bits plus a sign bit

    reg clk = 1'b0;
    always clk = #(`CLK_PER/2) ~clk;

    localparam SW = 12;             // signal width, signed value
    localparam LGN = 8;             // N = 2^LGN, unsigned
    localparam KW = LGN;            // k width signed, needs to range from 0 to N/2, LGN bits gets us up to N/2 - 1, good enough
    localparam PIW = 15;            // width of unsigned constant PI localparam
    localparam PW = PIW+KW;         // phase 2*PI*k/N width
    localparam CW = 16;             // CORDIC output width

    localparam              N = 256;                    // == 2^LGN
    localparam [(PIW-1):0]  PI = 15'b110010010001000;   // == 3.1416015625  U(2,13)
    localparam [(KW-1):0]   i_kfreq = 8'd13;            // == 13            U(8,0)

    // ** STAGE ONE : CALCULATE PHASE **
    wire signed [(PW-1):0] phase;
    // PI*k   U(2,13) x U(8,0) = U(10,13)
    // VIRTUAL bit shift:
    // by converting our interpretation from U(10,13) to U(3,20) instead of performing a literal bit shift, we achieve the goal of dividing by 2^7.
    // *** IF we wanted to reduce the bit width here, we could perform a literal bit shift >> (LGN-1), interpret it as U(10,13), then take the bottom 
    // 16 bits as A(2,13) for the CORDIC
    assign phase = PI * i_kfreq;    // U(3,20) 

    // ** STAGE TWO : CALCULATE SINE AND COSINE OF PHASE ** 
    // now, feed phase into CORDIC. It takes phase inputs in an A(2, f) input so the bit width should be 1 + 2 + f for f fractional bits
    // Thus, if we give it our U(3, 20) value it will interpret it as A(2,20).
    // INPUT : A(2,f)
    // OUTPUT: A(1,f)
    wire [(CW-1):0] sin, cos;
    wire            trig_valid;
    // when generating the CORDIC IP, make sure the input and output widths match PW and CW, respectively.
    sincos #(.PW(PW), .OW(CW)) trigFunc(
        .i_clk      (clk),
        .i_valid    (1'b1),
        .i_rst      (1'b1),     // active-low
        .i_phase    (phase),    // A(2,20) -> 23 BIT
        .sin        (sin),      // A(1,14) -> 16 BIT
        .cos        (cos),      // A(1,14) -> 16 BIT
        .o_valid    (trig_valid)
    );

    /*
    // ** STAGE THREE : MULTIPLY DELAYED SIGNAL VALUES BY COEFFS (REAL PART) **
    // Delay registers
    reg signed [(SW-1):0]   dri;        // x[n-1]
    reg signed [(SW-1):0]   dro0, dro1; // y[n-1], y[n-2]
    initial begin
        dri  <= 1'b0;
        dro0 <= 1'b0;
        dro1 <= 1'b0;
    end

    reg signed [(SW+CW-1):0]    mult0; // cos()x[n-1] -> A(3,25)
    reg signed [(SW+CW-1):0]    mult1; // 2cos()y[n-1] -> A(4,24)
    wire                        mults_valid;

    always @ (posedge clk) begin
        if (trig_valid) begin
            mult0 <= cos * dri;     // A(1,11) x A(1,14) = A(3,25)
            mult1 <= cos * dro0;    // A(1,11) x A(1,14) = A(3,25) << 1 = A(4,24) "virtual bit shift"
            mults_valid <= 1'b1;
        end else begin
            mult0 <= 0;
            mult1 <= 0;
            mults_valid <= 1'b0;
        end
    end

    // ** STAGE FOUR : MATCH WIDTH PRIOR TO ADDITION OF TERMS **
    // Re{y[n]} = x[n] - cos()x[n-1] + 2cos()y[n-1] - y[n-2]
    // *NOTE* the two middle terms are of width SW+CW, and the outer terms x[n] and y[n-2] are of width SW, 
    // so we must perform sign extension on the outer terms by CW bits
    wire signed [(SW+CW-1):0] ext_i_sample, ext_dro1;   // sign extended terms x[n] and y[n-2]
    assign ext_i_sample = {{CW{i_sample[SW-1]}}, i_sample};
    assign ext_dro1 = {{CW{dro1[SW-1]}}, dro1};

    // ** STAGE FIVE : PERFORM THE SUM, ADD TWO BITS TO WIDTH
    localparam RW = SW+CW+2;    // width of result (from addition of four terms of width SW + CW)
    reg signed [(RW-1):0] o_sample_re = 0;
    */




endmodule
