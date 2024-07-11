`timescale 1ns / 1ps
`define SIM
`define CMOD_PER 83.33
//////////////////////////////////////////////////////////////////////////////////
// Company: the Ohio State University
// Engineer: Connor Fricke
// 
// Create Date: 07/09/2024 12:52:37 PM
// Module Name: testbench_xadc
// Project Name: XADC
// Target Devices: CMOD S7
// Description: Example instantiation of AMD's XADC IP core for digitization and processing
// of an analog signal from a signal generator 
// Dependencies: 
//  XADC IP Core
//////////////////////////////////////////////////////////////////////////////////


module testbench_xadc(
    `ifndef SIM
    input wire clk,         // system clock
    `endif
    input wire vaux5_p,     // analog input pin 32 (channel 5), positive    # IO_L12P_T1_MRCC_AD5P_15
    input wire vaux5_n      // analog input pin 32 (channel 5), negative    # IO_L12N_T1_MRCC_AD5N_15
    );

    // NOTES:
    /*
    From : https://docs.amd.com/r/en-US/ug480_7Series_XADC/Instantiating-the-XADC, and https://digilent.com/reference/programmable-logic/cmod-s7/reference-manual

        - In unipolar mode (default), the ADC has input range from 0-1V, where the ADC output has a full scale code of FFFh when the input is 1V
          For example, with an input of 200 mV to the ADC pin, the output of the ADC would be ((200/1000) x FFFh) = 819d or 333h. The LSB size in
          unipolar mode is equivalent to 244 uV or 0.244 mV.
        - In bipolar mode, the range of ADC input is instead -0.5V to 0.5V with a full scale (two's complement) code of 7FFh = +0.5V and 800h = -0.5V.
          The output coding is intended to indicate the sign of the input signal on V_p relative to V_n. The LSB size is again 244 uV or 0.244 mV.
        - the temperature sensor result in celsius can be calculated from the output code via the equation: T = ((ADC Code x 503.975) / 4096) - 273.15
        - ALL OPERATING MODES of the ADC are configured using the CONTROL REGISTERS (see Chapter 3 for details of control regs)
        - The XADC inputs are connected to the top level of the design, labeled in User Guide UG475 by appending _ADxP_ and _ADxN_ to the I/O name. For
          example, VAUXP[15] could be designated to IO_LxxP_xx_AD15P_xx in the pinout spec
        - On the CMOD S7, the analog input pins should receive voltages of 0-3.3V relative to GND on pin 25. Resistor-divider circuits will scale this 
          down to the 0-1V range needed by the ADC. The pins can handle up to 5.5V safely but anything greater than 3.3V will be read as 3.3V by the XADC.
        - The maximum conversion rate of the ADC is 1 MSPS. Since the ADC requires 26 clock cycles to acquire an analog signal and perform a conversion, 
          the maximum ADC clock frequency is 26 MHz. The ADC clock is, at it's fastest, equivalent to the input clock (system clock) divided by two. Since the CMOD
          S7 has a 12 MHz clock, the fastest ADC Clock we can have is 6 MHz, and thus a sample rate of 231 kSPS.
        - In general, the differential analog input is the difference between v_p and v_n. V_n is typically connected to a local ground or common mode signal,
          and should be between 0 and +0.5 V relative to ADC GND.
          In unipolar mode, V_p must always be positive relative to V_n, with a difference (V_p - V_n) between 0 and 1 V, thus V_p must range between 0 and +1.5V
          relative to ADC GND.
          In bipolar mode, V_p may be positive or negative relative to V_n, for example with V_n = +0.5V relative to ADC GND, then V_p can range from 0 to 1V
          relative to ADC GND which is equivalent to an analog differential measurement between -0.5V and +0.5V.
        - The ADC can measure internal temperature of the FPGA as well as power supply voltages V_ccint, V_ccaux, and V_ccbram. The voltage measurement is given
          by the transfer function V = (ADC Code / 4096) x 3V

    NOTE: For most measurements (temp, power supply, analog input) the results are stored in 16-bit regs but only the 12 MSBs should be used in the transfer functions.
    See XADC Register Interface of UG480 for details.
    STATUS REGISTER ADDRESSES: (Read only)
        Temp -              h00
        V_CCINT -           h01 
        V_CCAUX -           h02
        V_P/V_N -           h03
        V_REFP -            h04
        V_REFN -            h05
        V_CCBRAM -          h06
        Supply A Offset -   h08
        ADC A Offset -      h09
        ADC A Gain -        h0A
        VAUX(P/N)[15:0] -   h10 to h1F
        Max/Min Temp -      h20/h24
        Max/Min V_CCINT -   h21/h25
        Max/Min V_CCAUX -   h22/h26
        Max/Min V_CCBRAM -  h23/h27
        Supply B Offset -   h30
        ADC B Offset -      h31
        ADC B Gain -        h32
        Flag (ALMs, OT) -   h3F
    CONTROL REGISTER ADDRESSES: (Read & Write)
        Config Reg 0-2 -    h40 to h42
        Test Reg 0-4 -      h43 to h47
        Sequence Regs -     h48 to h4F
        Alarm Regs -        h50 to h5F
    */

    `ifdef SIM
    reg clk = 1'b0;
    always #(`CMOD_PER/2) clk = ~clk;
    `endif


    // = {2{1'b0}, channel} ??

    // ** adc outputs **
    wire [3:0]  alm;
    wire        eoc;
    wire        eos;
    wire [4:0]  channel;
    wire [4:0]  muxaddr;
    wire        adc_busy;

    // ** drp interface **
    wire        rst = 1'b0;                   // asynchronous reset
    wire        drp_en = 1'b1;                // enable
    wire        drp_we = 1'b0;                // write-enable
    wire        drp_ready;                    // ready
    wire [15:0] drp_in = 0;                   // data bus for control/config registers
    wire [15:0] drp_out;                      // data bus for status registers
    wire [6:0]  drp_addr = {2'b00, channel};  // control/status register address

    reg [11:0] signal;

    xadc_0 myADC (
        .di_in                  (drp_in),           // input wire [15 : 0] : DRP DATA INPUT BUS
        .daddr_in               ({2'b00, channel}), // input wire [6 : 0] : DRP ADDRESS BUS
        .den_in                 (eoc),              // input wire : DRP ENABLE SIGNAL
        .dwe_in                 (drp_we),           // input wire : DRP WRITE ENABLE SIGNAL
        .drdy_out               (drp_ready),        // output wire : DRP DATA READY SIGNAL
        .do_out                 (drp_out),          // output wire [15 : 0] : DRP DATA OUTPUT BUS
        .dclk_in                (clk),              // input wire dclk_in : SYSTEM CLOCK
        .reset_in               (rst),              // input wire : ASYNCH RESET
        .vp_in                  (1'b0),             // input wire : DIFFERENTIAL ANALOG INPUT, POSITIVE
        .vn_in                  (1'b0),             // input wire : DIFFERENTIAL ANALOG INPUT, NEGATIVE
        .vccint_alarm_out       (alm[0]),           // output wire : POWER SUPPLY ALARM
        .vccaux_alarm_out       (alm[1]),           // output wire : POWER SUPPLY ALARM
        .ot_out                 (alm[2]),           // output wire : OVER TEMPERATURE ALARM
        .alarm_out              (alm[3]),           // output wire : ANY ALARMS SIGNAL
        .channel_out            (channel),          // output wire [4 : 0] : CHANNEL SELECTION OUTPUT
        .muxaddr_out            (muxaddr),          // output wire [4 : 0] : FOR EXTERNAL MULTIPLEXER MODE
        .eoc_out                (eoc),              // output wire : END OF CONVERSION
        .eos_out                (eos),              // output wire : END OF SEQUENCE
        .busy_out               (adc_busy)          // output wire : ADC BUSY (during conversion)
    );

    always @ (posedge clk) begin
        if (drp_ready)
            signal <= drp_out[15:4]; // take 12 MSBs
    end

    // ** DEBUG **
    /*
    ila_0 debuggerILA(
        .clk(clk),
        .probe0(signal),    // 12-bit
        .probe1(channel),   // 5-bit
        .probe2(muxaddr),   // 5-bit
        .probe3(alm),       // 4-bit
        .probe4(adc_busy),  // 1-bit
        .probe5(eoc),       // 1-bit
        .probe6(eos),       // 1-bit
        .probe7(drp_ready)  // 1-bit
    );
    */

endmodule
