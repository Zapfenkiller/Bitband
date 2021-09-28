`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:       René Trapp
//
// Create Date:    04:54:10 09/06/2021 
// Design Name:
// Module Name:    integrator
// Project Name:   Bitband
// Target Devices: XC6SLX9-TQG144
// Tool versions:  Xilinx ISE Webpack 14.7 (any supporting the Xc6SLX9)
// Description:    INVERTING integrator
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
//             2^N        2^b
//  <=> T = --------- * -------
//           fsample     coeff
//
// Where:
//  b = Bitwidth of coefficient `coeff`
//  T is defined as time elapsed for the output to cross '1' with a unit step
//  applied to the input.
//
// When used as a filter building block:
//  The sample clock is 2*pi*2^N times the maximum desired cutoff frequency (fg)
//  and vice versa.
//  Example: fsample = 1536000 Hz, N = 5 <=> fg_max_ = 7639.4 Hz
//
//         fsample       coeff                    2*pi * 2^N
//  fg = ------------ * ------- <=> coeff = fg * ------------ * 2^b
//        2*pi * 2^N      2^b                      fsample
//
// Mode selects the integrator response to an overflow condition:
//  0 = Wrap around  (simple digital representation)
//  1 = Clip         (mimics analogue circuitry)
//  2 = Fold back    (folds back as if the input has been inverted)
// (3 = Wrap around)
// It is intended to hardcode the mode input. Any change during usage might
// result in a large output signal spike! Hardcoding also allows to optimize
// away several gates.
//
// Spartan 6 limitation:
//  SIGWIDTH + CWIDTH <= 36
//
////////////////////////////////////////////////////////////////////////////////


module integrator
#(
   parameter   SIGWIDTH               =  8,
   parameter   CWIDTH                 = 12,     // b
   parameter   N                      =  5      // N
)
(
   input                                clk,
   input                                sampleClk,
   input                          [1:0] mode,
   input                   [CWIDTH-1:0] coeff,  // coeff
   input       signed    [SIGWIDTH-1:0] sigIn,
   output      signed    [SIGWIDTH-1:0] sigOut,
   output                               clip
);

   wire signed    [CWIDTH+SIGWIDTH-1:0] sigInMult;
   wire signed  [CWIDTH+N+SIGWIDTH  :0] accuNext;
   wire signed  [CWIDTH+N+SIGWIDTH-1:0] accuClip;
   reg  signed  [CWIDTH+N+SIGWIDTH-1:0] accu = 0;
   wire                                 overflow;
   reg                                  ovfPrev = 0;
   reg                                  ovfStatus = 0;


   assign sigInMult  = sigIn * $signed({1'b0, coeff});
   assign accuNext   = accu - sigInMult;
   assign accuClip   = {accuNext[CWIDTH+N+SIGWIDTH], {(CWIDTH+N+SIGWIDTH-1){~accuNext[CWIDTH+N+SIGWIDTH]}}};
   assign overflow   = accuNext[CWIDTH+N+SIGWIDTH] ^ accuNext[CWIDTH+N+SIGWIDTH-1];


   always @(posedge clk)
      if (sampleClk)
         ovfPrev <= overflow;

   always @(posedge clk)
      if (sampleClk)
         if (overflow & ~ovfPrev)
            ovfStatus <= ~ovfStatus;


   always @(posedge clk)
      if (sampleClk)
         if (overflow & (mode == 2'd1))
            accu <= accuClip;
         else
            accu <= accuNext[CWIDTH+N+SIGWIDTH-1:0];


   assign sigOut = (mode == 2'd2) ? {SIGWIDTH{ovfStatus}} ^ accu[CWIDTH+N+SIGWIDTH-1:CWIDTH+N] : accu[CWIDTH+N+SIGWIDTH-1:CWIDTH+N];
   assign clip = overflow;


endmodule
