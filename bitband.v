`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:       René Trapp
//
// Create Date:    19:42:00 26/Aug/2021
// Design Name:
// Module Name:    bitband (top)
// Project Name:   BitBand
// Target Devices: XC6SLX9-TQG144
// Tool versions:
// Description:    A music synthesizer.
//
// License:
// --------
// Copyright 2021  René Trapp (rene [dot] trapp (-at-) web [dot] de)
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
// Additional Comments:
// --------------------
//
// Alchitry "Mojo v3":
// -------------------
//
// Board:
//  i_CLOCK       P56  (CLK, 50 MHz)   LVCMOS33, no pull
//  i_BUTTON      P38  (L65N_2)        LVCMOS33, no pull
//  o_LEDS9       P123 (L37N_0)        LVCMOS33, slow, 24 mA
//  o_LEDS8       P124 (L37P_0)        LVCMOS33, slow, 24 mA
//  o_LEDS7       P126 (L36N_0)        LVCMOS33, slow, 24 mA
//  o_LEDS6       P127 (L36P_0)        LVCMOS33, slow, 24 mA
//  o_LEDS5       P131 (L35N_0)        LVCMOS33, slow, 24 mA
//  o_LEDS4       P132 (L35P_0)        LVCMOS33, slow, 24 mA
//  o_LEDS3       P133 (L34N_0)        LVCMOS33, slow, 24 mA
//  o_LEDS2       P134 (L34P_0)        LVCMOS33, slow, 24 mA
//
// ATmega32U4 ucif:
//  io_DATA[7]    P65  (D0)            LVCMOS33, slow, 4 mA, no pull
//  io_DATA[6]    P62  (D1)            LVCMOS33, slow, 4 mA, no pull
//  io_DATA[5]    P61  (D2)            LVCMOS33, slow, 4 mA, no pull
//  io_DATA[4]    P46  (D3)            LVCMOS33, slow, 4 mA, no pull
//  io_DATA[3]    P45  (MISO)          LVCMOS33, slow, 4 mA, no pull
//  io_DATA[2]    P44  (MOSI)          LVCMOS33, slow, 4 mA, no pull
//  io_DATA[1]    P43  (SCK)           LVCMOS33, slow, 4 mA, no pull
//  io_DATA[0]    P48  (SS)            LVCMOS33, slow, 4 mA, no pull
//  i_E           P55  (AVR_TX)        LVCMOS33, no pull
//  i_RW          P59  (AVR_RX)        LVCMOS33, no pull
//  i_DDR         P70  (CCLK)          LVCMOS33, no pull
//                P39  (INIT_B)        LVCMOS33
//
// Experimental audio output:
//  PWM                                LVCMOS33, slow, 4 mA, no pull
//
// Register file:
//    Addr  !  
// ---------+--------------
//      0   ! reserved
//      1   ! [7:0] waveFreqLo
//      2   ! [7:0] waveFreqMi
//      3   ! [2:0] waveFreqHi
//      4   ! [7:0] effectFreqLo
//      5   ! [7:0] effectFreqMi
//      6   ! [2:0] effectFreqHi
//      7   ! [7:4] pulseWidthLo
//      8   ! [7:0] pulseWidthHi
//      9   !   [7] Ring, [6] Sync, [2:0] Mode
//     10   ! [6:0] envAttack
//     11   ! [6:0] envDecay
//     12   ! [6:0] envSustain
//     13   ! [6:0] envRelease
//     14   ! [7:0] filtFreqLo
//     15   ! [7:0] filtFreqHi
//     16   ! [7:5] filtMode, [4:0] Q
//     17   ! [7:0] filtOvrdrv
//     18   !   [0] gate1
//     19   ! 
//
////////////////////////////////////////////////////////////////////////////////


module bitband
(
   input          i_CLOCK,    // On board oscillator, 50 MHz <=> 20 ns
   input          i_BUTTON,   // On board pushbutton, '0' = pushed
   input          i_E,        // µC-Interface (ucif) data strobe
   input          i_RW,       // ucif RD- / WR-control, '0' = WR
   input          i_DDR,      // ucif Double Data Rate, '1' = enable
   inout   [7:0]  io_DATA,    // ucif data lines
   output         o_LED2,     // On board LED, '1' = light
   output         o_LED3,     // On board LED, '1' = light
   output         o_LED4,     // On board LED, '1' = light
   output         o_LED5,     // On board LED, '1' = light
   output         o_LED6,     // On board LED, '1' = light
   output         o_LED7,     // On board LED, '1' = light
   output         o_LED8,     // On board LED, '1' = light
   output         o_LED9,     // On board LED, '1' = light

output reg  PWM = 0  // temporary, unconstrained, check Pinout Report!
);

   localparam     REGCNT   = 18;
   localparam     REGSIZE  = 8;        // Bit
   localparam     SIGSIZE  = 8;        // Bit
   localparam     OSCFREQ  = 50000000; // Hz

// localparam     PWMSTEPS = 2**REGSIZE;
// localparam     PRESCAL1 = (OSCFREQ / (PWMSTEPS * PWMFREQ)) - 1;
// localparam     PRESCAL2 = (OSCFREQ / (PRESCAL1 * BLINKFRQ)) - 1;
// localparam     PRESIZE1 = clog2(PRESCAL1);
// localparam     PRESIZE2 = clog2(PRESCAL2);
   localparam     ADDRSIZE = clog2(REGCNT);


// assign                        o_LED2 = 0;
// assign                        o_LED3 = 0;
   assign                        o_LED4 = 0;
   assign                        o_LED5 = 0;
   assign                        o_LED6 = 0;
   assign                        o_LED7 = 0;
   assign                        o_LED8 = 0;
// assign                        o_LED9 = 0;

   // ucif
   wire        [(ADDRSIZE-1):0]  address;
   wire        [(REGSIZE-1):0]   dataToLogic;
   wire                          wrPulse;
   reg         [(REGSIZE-1):0]   dataFromLogic = 0;

   // clocks and common stuff
   reg         [9:0]             prescaler = 0;
   reg         [9:0]             prescalerPrev = 0;
   wire                          clk1M5;
   wire                          clk48k;

   // wavegen
   reg         [(REGSIZE-1):0]   tempReg1 = 0;
   reg         [(REGSIZE-1):0]   tempReg2 = 0;
   reg         [(REGSIZE-1):0]   tempReg5 = 0;
   reg         [(REGSIZE-1):0]   tempReg6 = 0;
   reg         [18:0]            phaseInc1 = 0;
   reg         [18:0]            phaseInc2 = 0;
   reg         [2:0]             waveSel1 = 0;
   reg         [3:0]             tempReg3 = 0;
   reg         [11:0]            pulseLen = 12'd2048;
   reg                           syncCtrl1 = 0;
   reg                           ringCtrl1 = 0;
   wire                          syncIn1;
   wire                          ringIn1;
   wire signed [(SIGSIZE-1):0]   wave1;
   wire                          syncOut1;
assign o_LED9 = syncOut1; // nur ein QnD dummy gegen Synthese-Warnings

   // filter
   reg         [(REGSIZE-1):0]   tempReg4 = 0;
   reg         [15:0]            filtFreq = 0;
   reg         [4:0]             filtReso = 0;
   reg         [2:0]             filtMode = 0;
   wire signed [(SIGSIZE-1):0]   filtered1;
   reg         [(SIGSIZE-1):0]   filtOvrdrv = 0;

   // envelope
   reg         [6:0]             attackVal = 5;
   reg         [6:0]             decayVal = 45;
   reg         [6:0]             sustainVal = 123;
   reg         [6:0]             releaseVal = 68;
   reg                           gate1 = 0;
   wire        [6:0]             envelope1;
   wire        [15:0]            envExpo1;

   // pwm dac
   reg         [(2*SIGSIZE-1):0] dacIn = 0;
   wire        [(SIGSIZE-1):0]   pwmDAC;


   // Microcontroller Interface
   // -------------------------

   // Synchronize inputs
   syncstage e
   (
      .clock      (i_CLOCK),
      .async      (i_E),
      .sync       (e_sync)
   );

   syncstage rw
   (
      .clock      (i_CLOCK),
      .async      (i_RW),
      .sync       (rw_sync)
   );

   syncstage ddr
   (
      .clock      (i_CLOCK),
      .async      (i_DDR),
      .sync       (ddr_sync)
   );

   ucif
   #(
      .dataSize         (REGSIZE),
      .addrSize         (ADDRSIZE)
   )
   ucif1
   (
      // Inputs
      .clock            (i_CLOCK),
      .ddr              (ddr_sync),
      .rw               (rw_sync),
      .e                (e_sync),
      .dataIn           (io_DATA),
      // Outputs
      .address          (address),
      .dataToLogic      (dataToLogic),
      .wrPulse          (wrPulse)
   );

   // Register write
   always @(posedge i_CLOCK)
   begin
      if (wrPulse)
         case (address[(ADDRSIZE-1):0])
             1: tempReg1    <= dataToLogic;
             2: tempReg2    <= dataToLogic;
             3: phaseInc1   <= {dataToLogic[2:0], tempReg2, tempReg1};
             4: tempReg5    <= dataToLogic;
             5: tempReg6    <= dataToLogic;
             6: phaseInc2   <= {dataToLogic[2:0], tempReg6, tempReg5};
             7: tempReg3    <= dataToLogic[7:4];
             8: pulseLen    <= {dataToLogic, tempReg3};
             9: begin
                  waveSel1  <= dataToLogic[2:0];
                  syncCtrl1 <= dataToLogic[6];
                  ringCtrl1 <= dataToLogic[7];
                end
            10: attackVal   <= dataToLogic[6:0];
            11: decayVal    <= dataToLogic[6:0];
            12: sustainVal  <= dataToLogic[6:0];
            13: releaseVal  <= dataToLogic[6:0];
            14: tempReg4    <= dataToLogic;
            15: filtFreq    <= {dataToLogic, tempReg4};
            16: begin
                  filtReso  <= dataToLogic[4:0];
                  filtMode  <= dataToLogic[7:5];
                end
            17: filtOvrdrv  <= dataToLogic[7:0];
            18: begin
                  gate1     <= dataToLogic[0];
                end
         endcase
   end

   // Register readback
   always @(posedge i_CLOCK)
//    case (address[(ADDRSIZE-1):0])
//        1: dataFromLogic <= phaseInc1[ 7: 0];
//        2: dataFromLogic <= phaseInc1[15: 8];
//        3: dataFromLogic <= {{(REGSIZE-3){'b0}}, phaseInc1[18:16]};
//       default:
             dataFromLogic <= {7'b0, ~button};
//    endcase

   // Bus output enabling
   assign io_DATA = i_RW ? dataFromLogic : {8'bz};


   // Clock prescaling
   // ----------------

   // Prescaler
   always @(posedge i_CLOCK)
      prescaler <= prescaler + 1'b1;

   always @(posedge i_CLOCK)
      prescalerPrev <= prescaler;

   assign clk1M5 = prescalerPrev[4] & ~prescaler[4];
   assign clk48k = prescalerPrev[9] & ~prescaler[9];


   // Waveform generator
   // ------------------

   waveGen
   #(
      .INCRSIZE   (19),
      .ACCUSIZE   (22),
      .THRSIZE    (12),
      .SMPLSIZE   (8)
   )
   waveGen1
   (
      .clock      (i_CLOCK),
      .nextSample (clk48k),
      .increment  (phaseInc1),
      .waveselect (waveSel1),
      .threshold  (pulseLen),
      .ringModIn  (ringIn1 & ringCtrl1),
      .syncIn     (syncIn1 & syncCtrl1),
      .sample     (wave1),
      .syncOut    (syncOut1)
   );


   // Effect generator
   // ----------------

   reg                    [21:0] accu = 0;
   reg                           accuPrevMSB = 1'b1;
   wire                   [21:0] accuNext;

   assign accuNext = accu + phaseInc2;

   always @(posedge i_CLOCK)
      if (clk48k)
         accu <= accuNext;

   always @(posedge i_CLOCK)
      if (clk48k)
         accuPrevMSB <= accuNext[21];

   assign syncIn1 = ~accuNext[21] & accuPrevMSB;
   assign ringIn1 = accuNext[21];


   // Numerical Controlled Filter
   // ---------------------------

   filter
   #(
      .SIGWIDTH   (SIGSIZE),
      .FRQWIDTH   (16)
   )
   filter1
   (
      .clk        (i_CLOCK),
      .sampleClk  (clk1M5),
      .freq       (filtFreq),
      .Q          ({filtReso, 1'b0}),
      .overdrive  (filtOvrdrv),
      .mode       (filtMode),
      .unfiltered (wave1),
      .filtered   (filtered1),
      .clipBP     (o_LED2),
      .clipLP     (o_LED3)
   );


   // Envelope generator
   // ------------------

   envGen
   #(
      .ENVWIDTH   (7)
   )
   envGen1
   (
      .clock      (i_CLOCK),
      .clockEn    (clk48k),
      .attackVal  (attackVal),
      .decayVal   (decayVal),
      .sustainVal (sustainVal),
      .releaseVal (releaseVal),
      .gate       (gate1),
      .envelope   (envelope1)
   );

   // Convert linear envelope to exponential volume control
   linExpo  lin2Exp1
   (
      .clock      (i_CLOCK),
      .lin        (envelope1),
      .expo       (envExpo1)
   );


   // PDM-DAC <- Temporär bis das waveShare Audio-Hat dran ist
   // -------

   always @(posedge i_CLOCK)
      if (clk48k)
         dacIn <= filtered1 * $signed({1'b0, envExpo1[15:8]});

   wire [8:0] dacUnsigned;
   assign dacUnsigned = dacIn[14:7] + 2**(SIGSIZE-1);
   reg [7:0] pdmDac = 0;

   always @(posedge i_CLOCK)
      {PWM, pdmDac} <= pdmDac + dacUnsigned[7:0];


   // Miscellaneous stuff
   // -------------------

   syncstage syncButton
   (
      .clock      (i_CLOCK),
      .async      (i_BUTTON),
      .sync       (button)
   );


   // Convenience function
   function integer clog2;
      input integer argument;
      begin
         argument = argument - 1;
         for (clog2 = 0; argument > 0; clog2 = clog2 + 1)
            argument = argument >> 1;
      end
   endfunction


endmodule
