`timescale 1ns / 1ps
`include "interfaces.vh"

module rfsoc4x2_top(
        input VP, // no pinloc
        input VN, // no pinloc
        input ADC0_CLK_P,   // AF5
        input ADC0_CLK_N,   // AF4
        input ADC0_VIN_P,   // AP2                  -- NOTE THESE ARE INVERTED
        input ADC0_VIN_N,   // AP1                  -- W-T-F REAL DIGITAL??
        input ADC1_VIN_P,   // AM2                  -- HOW DOES THIS WORK
        input ADC1_VIN_N,   // AM1      
        input ADC4_CLK_P,   // AB5
        input ADC4_CLK_N,   // AB4
        input ADC4_VIN_P,   // AF2
        input ADC4_VIN_N,   // AF1
        input ADC5_VIN_P,   // AD2
        input ADC5_VIN_N,   // AD1
        input DAC0_CLK_P,   // R5
        input DAC0_CLK_N,   // R4
        output DAC0_VOUT_P, // U2  - NOT IN XDC
        output DAC0_VOUT_N, // U1  - NOT IN XDC
        input SYSREF_P,     // U5  - NOT IN XDC
        input SYSREF_N,     // U4  - NOT IN XDC
        input FPGA_REFCLK_IN_P, // AN11
        input FPGA_REFCLK_IN_N, // AP11
        input SYSREF_FPGA_P,    // AP18
        input SYSREF_FPGA_N,    // AR18    
        output W_LED_0,
        output W_LED_1,
        output W_LED_2,
        output W_LED_3    
    );
    
    // we can't capture SYSREF at 375 MHz,
    // so we generate a half-speed clock in the clkwiz

    // input clock before bufg
    wire aclk_in;
    // this is the INPUT 375 MHz which is used b/c it's low jitter
    wire aclk;
    // this is the half-speed clock used for the DACs, ADC capture, and SYSREF cap
    wire aclk_div2;

    // this is 128 because we get eight 16-bit samples per clock cycle from each ADC.
    localparam ADC_WIDTH = 128;
    // ADC AXI4-Streams
    `DEFINE_AXI4S_MIN_IF( adc0_ , ADC_WIDTH );  // chD
    `DEFINE_AXI4S_MIN_IF( adc1_ , ADC_WIDTH );  // chC
    `DEFINE_AXI4S_MIN_IF( adc4_ , ADC_WIDTH );  // chB
    `DEFINE_AXI4S_MIN_IF( adc5_ , ADC_WIDTH );  // chA
    // Streams going to readout buffers
    `DEFINE_AXI4S_MIN_IF( buf0_ , ADC_WIDTH );
    `DEFINE_AXI4S_MIN_IF( buf1_ , ADC_WIDTH );
    `DEFINE_AXI4S_MIN_IF( buf2_ , ADC_WIDTH );
    `DEFINE_AXI4S_MIN_IF( buf3_ , ADC_WIDTH );
    
    IBUFDS u_aclk_ibuf(.I(FPGA_REFCLK_IN_P),
                       .IB(FPGA_REFCLK_IN_N),
                       .O(aclk_in));
    BUFG u_aclk_bufg(.I(aclk_in),.O(aclk));
    ref_clk_wiz u_refclkwiz(.clk_in1(aclk),
                            .reset(1'b0),
                            .clk_out1(aclk_div2));
    
    wire sysref;
    reg sysref_aclk_div2 = 0;
    reg sysref_reg = 0;
    IBUFDS u_sysref_ibuf(.I(SYSREF_FPGA_P),
                         .IB(SYSREF_FPGA_N),
                         .O(sysref));
    always @(posedge aclk_div2) sysref_aclk_div2 <= sysref;
    always @(posedge aclk) sysref_reg <= sysref_aclk_div2;

    reg [31:0] pps_counter = {32{1'b0}};
    reg pps_flag = 0;
    wire pps_flag_aclk;
    wire aclk_freq_done;

    reg [31:0] aclk_counter = {32{1'b0}};
    (* CUSTOM_CC_SRC = "ACLK" *)
    reg [31:0] aclk_freq = {32{1'b0}};
    (* CUSTOM_CC_DST = "PSCLK" *)
    reg [31:0] aclk_freq_ps = {32{1'b0}};

    always @(posedge aclk) begin
        if (pps_flag_aclk) aclk_counter <= {32{1'b0}};
        else aclk_counter <= aclk_counter + 1;

        if (pps_flag_aclk) aclk_freq <= aclk_counter;
    end
    always @(posedge ps_clk) begin
        if (pps_counter == 100000000 - 1) pps_counter <= {32{1'b0}};
        else pps_counter <= pps_counter + 1;

        pps_flag <= (pps_counter == {32{1'b0}});
        if (aclk_freq_done) aclk_freq_ps <= aclk_freq;
    end
    flag_sync u_pps_flag_sync(.in_clkA(pps_flag),.out_clkB(pps_flag_aclk),.clkA(ps_clk),.clkB(aclk));
    flag_sync u_aclk_freq_done_sync(.in_clkA(pps_flag_aclk),.out_clkB(aclk_freq_done),.clkA(aclk),.clkB(ps_clk));

    clk_count_vio u_clkcount(.clk(ps_clk),.probe_in0(aclk_freq_ps));

    // ** PS **
    mts_bd_wrapper u_ps(.Vp_Vn_0_v_p( VP ),
                        .Vp_Vn_0_v_n( VN ),
                        .sysref_in_0_diff_p( SYSREF_P ),
                        .sysref_in_0_diff_n( SYSREF_N ),
                        .adc0_clk_0_clk_p( ADC0_CLK_P ),
                        .adc0_clk_0_clk_n( ADC0_CLK_N ),
                        .adc2_clk_0_clk_p( ADC4_CLK_P ),
                        .adc2_clk_0_clk_n( ADC4_CLK_N ),
                        .vin0_01_0_v_p( ADC0_VIN_P ),
                        .vin0_01_0_v_n( ADC0_VIN_N ),
                        .vin0_23_0_v_p( ADC1_VIN_P ),
                        .vin0_23_0_v_n( ADC1_VIN_N ),
                        .vin2_01_0_v_p( ADC4_VIN_P ),
                        .vin2_01_0_v_n( ADC4_VIN_N ),
                        .vin2_23_0_v_p( ADC5_VIN_P ),
                        .vin2_23_0_v_n( ADC5_VIN_N ),
                        .vout00_0_v_p( DAC0_VOUT_P),
                        .vout00_0_v_n( DAC0_VOUT_N),
                        `CONNECT_AXI4S_MIN_IF( m00_axis_0_ , adc0_ ),
                        `CONNECT_AXI4S_MIN_IF( m02_axis_0_ , adc1_ ),
                        `CONNECT_AXI4S_MIN_IF( m20_axis_0_ , adc4_ ),
                        `CONNECT_AXI4S_MIN_IF( m22_axis_0_ , adc5_ ),
                        .s_axi_aclk_0( aclk_div2 ),
                        .s_axi_aresetn_0( 1'b1 ),
                        .s_axis_aclk_0( aclk ),
                        .s_axis_aresetn_0( 1'b1 ),
                        `CONNECT_AXI4S_MIN_IF( S_AXIS_0_ , buf0_ ),
                        `CONNECT_AXI4S_MIN_IF( S_AXIS_1_ , buf1_ ),   
                        `CONNECT_AXI4S_MIN_IF( S_AXIS_2_ , buf2_ ),       
                        `CONNECT_AXI4S_MIN_IF( S_AXIS_3_ , buf3_ ),

                        .pl_clk0( ps_clk ),
                        .pl_resetn0( ps_reset ),
                        .clk_adc0_0(adc_clk),
                        .user_sysref_adc_0( sysref_reg ));
    
    /* TEST DESIGNS */
    parameter THIS_DESIGN = "GOERTZEL";
    assign W_LED_1 = 1'b1;
    assign W_LED_2 = 1'b0;
    assign W_LED_3 = 1'b1;

    generate
        if (THIS_DESIGN == "BASIC") begin : BSC

            basic_design u_design(  
                .wb_clk_i               (ps_clk),
                .wb_rst_i               (1'b0),
                `CONNECT_WBS_IFS        ( wb_ , bm_ ),
                .aclk                   (aclk),
                .aresetn                (1'b1),
                `CONNECT_AXI4S_MIN_IF   ( adc0_ , adc0_ ),
                `CONNECT_AXI4S_MIN_IF   ( adc1_ , adc1_ ),
                `CONNECT_AXI4S_MIN_IF   ( adc4_ , adc4_ ),
                `CONNECT_AXI4S_MIN_IF   ( adc5_ , adc5_ ),
                // buffers
                `CONNECT_AXI4S_MIN_IF   ( buf0_ , buf0_ ),
                `CONNECT_AXI4S_MIN_IF   ( buf1_ , buf1_ ),
                `CONNECT_AXI4S_MIN_IF   ( buf2_ , buf2_ ),
                `CONNECT_AXI4S_MIN_IF   ( buf3_ , buf3_ )
            ); 

        end else if (THIS_DESIGN == "GOERTZEL") begin : GZ

            gz_design u_design(
                .aclk(aclk),
                .arst(1'b0),
                .signal_detected(W_LED_0),
                // ADC INPUTS
                `CONNECT_AXI4S_MIN_IF   (s0_axis_, adc0_ ),
                `CONNECT_AXI4S_MIN_IF   (s1_axis_, adc1_ ),
                `CONNECT_AXI4S_MIN_IF   (s2_axis_, adc4_ ),
                `CONNECT_AXI4S_MIN_IF   (s3_axis_, adc5_ ),
                // BUFFER OUTPUTS
                `CONNECT_AXI4S_MIN_IF   (m0_axis_, buf0_ ),
                `CONNECT_AXI4S_MIN_IF   (m1_axis_, buf1_ ),
                `CONNECT_AXI4S_MIN_IF   (m2_axis_, buf2_ ),
                `CONNECT_AXI4S_MIN_IF   (m3_axis_, buf3_ )
            );

        end
    endgenerate
    
endmodule
