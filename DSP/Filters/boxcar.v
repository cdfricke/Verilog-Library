`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: the Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 07/02/2024 11:19:14 AM
// Module Name: boxcar
// Project Name: Signal Processing
// Target Devices: CMOD S7
// Description: Moving Average / Boxcar FIR Filter design
//  y[n] = x[n] + y[n-1] - x[n-N]
// See original, by Dan Gisselquist: https://github.com/ZipCPU/dspfilters/
//////////////////////////////////////////////////////////////////////////////////


module boxcar
#(  // params
    parameter IW=16,            // input sample width
    parameter LGMEM=6,          // can take up to 2^LGMEM averages
    parameter OW=(IW+LGMEM),    // output result width, result is rounded if OW < IW + LGMEM
    parameter FIX_NAVG=1'b0,    // flag for using fixed number of averages
    localparam OPT_SIGNED=1'b1, // flag for taking average using signed numbers
    parameter INIT_NAVG = -1    // if FIX_NAVG is set, then we use this number of averages
)
(   // port declarations
    input wire                      clk,
    input wire                      rst,
    input wire                      ce,
    input wire        [(LGMEM-1):0] i_navg,
    input wire signed [(IW-1):0]    i_sample,
    output reg signed [(OW-1):0]    o_result
);

    reg                     full;
    reg [(LGMEM-1):0]       rdaddr, wraddr;
    reg [(IW-1):0]          memory [0:((1<<LGMEM)-1)];  // memory of 2^LGMEM registers each (IW) bits wide.
    reg [(IW-1):0]          preval, memval;
    reg [IW:0]              sub;                        // subtraction, y[n-1] - x[n-N] (1 bit wider than input sample)
    reg [(IW+LGMEM-1):0]    acc;                        // accumulator, x[n] + subtraction
    wire [(LGMEM-1):0]      req_navg;                   // requested number of averages
    wire [(IW+LGMEM-1):0]   rounded;                    // rounded result

    // if FIX_NAVG, the number of averages follows the INIT_NAVG parameter, else it follows the input value i_navg
    assign req_navg = (FIX_NAVG) ? INIT_NAVG : i_navg;

    // wraddr starts at zero and increments on every valid sample
    // rdaddr starts at -(req_navg) and increments on every valid sample (because we want x[n-N])
    initial wraddr = 0;
    initial rdaddr = -(req_navg);
    always @ (posedge clk) begin
        if (rst) begin 
            wraddr <= 0;
            rdaddr <= -req_navg;
        end else if (ce) begin
            wraddr <= wraddr + 1'b1;
            rdaddr <= rdaddr + 1'b1;
        end
    end

    // ** CLOCK STAGE ONE **
    initial preval = 0;     // "preval" moves things down one stage in time to give us a clock cycle to read from memory
    initial memval = 0;     // the value read from memory
    initial full = 1'b0;    // flag for when all addresses have been set at least once, this is our normal operating condition
    always @ (posedge clk) begin
        if (rst) begin
            preval <= 0;
            full <= 1'b0;
        end else if (ce) begin
            preval <= i_sample;
            memory[wraddr] <= i_sample;
            memval <= memory[rdaddr];
            full <= (full) || (rdaddr==0);
        end
    end

    // ** CLOCK STAGE TWO ** -> using the results of stage one
    // perform subtraction -> y[n-1] - x[n-N] -> preval - memval
    initial sub = 0;
    always @ (posedge clk) begin
        if (rst) sub <= 0;
        else if (ce) begin
            if (full) 
                sub <= { OPT_SIGNED & preval[(IW-1)], preval } - { OPT_SIGNED & memval[(IW-1)], memval };
            else
                sub <= { OPT_SIGNED & preval[(IW-1)], preval };
        end
    end

    // ** CLOCK STAGE THREE ** -> using the difference from stage two, calculate the summation
    initial acc = 0;
    always @ (posedge clk) begin
        if (rst)
            acc <= 0;
        else if (ce)
            acc <= acc + { {(LGMEM-1){OPT_SIGNED & sub[IW]}}, sub};
    end

    // ** CLOCK STAGE FOUR ** -> round result from IW+LGMEM-1 bits down to OW bits

    generate begin : RND
	    if (IW+LGMEM == OW) begin : NO_ROUNDING
		    assign	rounded = acc;
	    end else if (IW+LGMEM == OW + 1) begin : DROP_BIT   // drop a single bit, round to even
		    assign	rounded = acc + { {(OW){1'b0}}, acc[1] };
	    end else begin : GENERIC    // drop a general number of bits, round to even
		    assign	rounded = acc + 
                {
		        {(OW){1'b0}},
				acc[(IW+LGMEM-OW)],
				{(IW+LGMEM-OW-1){!acc[(IW+LGMEM-OW)]}}
				};
	    end 
    end 
    endgenerate

    // register output from rounded, taking width from IW+LGMEM bits down to OW bits
    initial o_result = 0;
    always @ (posedge clk) begin
        if (rst) o_result <= 0;
        else if (ce) o_result <= rounded[(IW+LGMEM-1):(IW+LGMEM-OW)];
    end

endmodule
