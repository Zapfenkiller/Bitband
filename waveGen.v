`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:44:24 05/25/2021 
// Design Name: 
// Module Name:    waveGen
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
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
// Generator frequency control (fo):
//                      2**b
//    Register = fo * ---------
//                     fSample
// Where b = size of the phase accumulator (ACCUSIZE).
//
// Generator waveform control:
//     waveselect ! Waveform
//    ------------+--------------
//          0     ! n/a
//          1     ! Triangle     (0 dB)
//          2     ! Sawtooth     (0 dB)
//          3     ! Pulse        (0 dB @ PW=50 %)
//          4     ! Voiced Noise
//          5     ! White Noise  (approx. -13,3 dB)
//          6     ! n/a
//          7     ! Dirac Pulse
//
// Generator pulse shape control (Pulse Width, PW):
//    Register = PW * 2**THRSIZE / 100
// Where PW given as %, THRSIZE = size of the register.
// Generated pulse width is limited to minimum = 0.03 %, maximum = 99.97 %.
//
////////////////////////////////////////////////////////////////////////////////


module waveGen
#(
   parameter   INCRSIZE        = 16,
   parameter   ACCUSIZE        = 24,
   parameter   THRSIZE         = 12,
   parameter   SMPLSIZE        = 16
)
(
   input                         clock,
   input                         nextSample,
   input        [(INCRSIZE-1):0] increment,
   input                   [2:0] waveselect,
   input         [(THRSIZE-1):0] threshold,
   input                         ringModIn,
   input                         syncIn,

   output reg   [(SMPLSIZE-1):0] sample = 0,
   output reg                    syncOut = 0
);

   localparam  SQRPOS      = ((2**(SMPLSIZE-1))-1)*1000/1732;
   localparam  SQRNEG      = -1 * SQRPOS;

   reg          [(ACCUSIZE-1):0] accu = 0;
   reg                           accuPrevMSB = 1'b1;
   wire         [(ACCUSIZE-1):0] accuNext;
   reg                           accuNextNoise = 0;
   reg                    [23:1] lfsr = 23'h7FFFF8;
   wire                    [7:0] noise;
   wire                          belowThr;
   wire                          syncOutNext;
   reg                    [31:1] lfsr2 = 31'h0cafe042;
   reg                     [2:0] cycle2 = 0;
   wire                    [7:0] noise2;
   reg          [(SMPLSIZE-1):0] sampleMux;


   // Phase accumulator
   assign accuNext = syncIn ? {ACCUSIZE{1'b0}} : (accu + increment);

   always @(posedge clock)
      if (nextSample)
         accu <= accuNext;

   always @(posedge clock)
      if (nextSample)
         accuPrevMSB <= accuNext[(ACCUSIZE-1)];

   assign syncOutNext = ~accuNext[(ACCUSIZE-1)] & accuPrevMSB | syncIn;

   always @(posedge clock)
      if (nextSample)
         syncOut <= syncOutNext;


   // Pulse (square with adjustable duty cycle)
   assign belowThr = (accuNext[(ACCUSIZE-1):(ACCUSIZE-THRSIZE)]) < ((threshold == 0) ? 1 : threshold);


   // Noise generator ("voiced noise")
   always @(posedge clock)
      accuNextNoise <= accuNext[(ACCUSIZE-3)];

   always @(posedge clock)
      if (accuNextNoise ^ accuNext[ACCUSIZE-3])
         lfsr <= {lfsr[22:1], lfsr[23] ^ lfsr[18]};

   assign noise = {lfsr[23], lfsr[21], lfsr[17], lfsr[14], lfsr[12], lfsr[8], lfsr[5], lfsr[3]};


   // Noise generator ("white noise")
   always @(posedge clock)
      if ((cycle2 != 0) | nextSample)
      begin
         cycle2 <= cycle2 + 1'b1;
         lfsr2 <= {lfsr2[30:1], lfsr2[31] ^ lfsr2[28]};
      end

   assign noise2 = {lfsr2[8:1]};


   // Selected waveform (assemble SIGNED representation!)
   always @(*)
      case (waveselect)
//       3'd0: sampleMux <= // reserved
         3'd1: sampleMux <= {(SMPLSIZE){accuNext[ACCUSIZE-1] ^ accuNext[ACCUSIZE-2]}} ^ accuNext[(ACCUSIZE-2):(ACCUSIZE-SMPLSIZE-1)]; // triangle
         3'd2: sampleMux <= accuNext[(ACCUSIZE-1):(ACCUSIZE-SMPLSIZE)]; // saw
         3'd3: sampleMux <= belowThr ? SQRNEG[(SMPLSIZE-1):0] : SQRPOS[(SMPLSIZE-1):0]; // pulse
         3'd4: sampleMux <= {noise, {(SMPLSIZE-8){1'b0}}}; // voiced noise
         3'd5: sampleMux <= {noise2, {(SMPLSIZE-8){1'b0}}}; // white noise
//       3'd6: sampleMux <= // reserved
         3'd7: sampleMux <= {1'b0, {(SMPLSIZE-1){syncOutNext}}}; // Dirac
         default: sampleMux <= {(SMPLSIZE){1'b0}}; // silence
      endcase

   always @(posedge clock)
      if (nextSample)
         sample <= ringModIn ? ~sampleMux : sampleMux;

endmodule
