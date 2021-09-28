`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:       René Trapp
//
// Create Date:    17:58:54 08/31/2021 
// Design Name:
// Module Name:    filter
// Project Name:   Bitband
// Target Devices: XC6SLX9-TQG144
// Tool versions:  Xilinx ISE Webpack 14.7 (any supporting the Xc6SLX9)
// Description:    State Variable NCF
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
// Filter frequency control (fo):
//                                     fo
//    Register = 2*pi * 32 * 2**16 * -------
//                                   fSample
//
// Filter resonance control (Q):
//                Q - 0.5
//    Register = ---------
//                  0.25
//
// Definition of Q:
//            fo
//    Q = -----------
//         bandwidth
//
////////////////////////////////////////////////////////////////////////////////


module filter
#(
   parameter   SIGWIDTH        =  8,
   parameter   FRQWIDTH        = 12
)
(
   input                                  clk,
   input                                  sampleClk,
   input                   [FRQWIDTH-1:0] freq,
   input                            [5:0] Q,
   input                            [7:0] overdrive,
   input                            [2:0] mode,
   input       signed      [SIGWIDTH-1:0] unfiltered,
   output reg  signed      [SIGWIDTH-1:0] filtered = 0,
   output                                 clipBP,
   output                                 clipLP
);

   localparam  PREDECIMALS              = 1;    // Vorkommabits
   localparam  DECIMALS                 = 15;   // Nachkommabits
   localparam  INTWIDTH                 = PREDECIMALS+DECIMALS;
   localparam  ROMWIDTH                 = 12;
   localparam  ROMWIDTH_D               = ROMWIDTH+2;

   reg                     [ROMWIDTH-1:0] ROM_I [63:0];
   reg                   [ROMWIDTH_D-1:0] ROM_D [63:0];
   wire signed    [SIGWIDTH+ROMWIDTH-1:0] unf0;
   reg  signed             [INTWIDTH-1:0] unf1 = 0;
   wire signed             [INTWIDTH-1:0] highP;
   wire signed             [INTWIDTH-1:0] bandP;
   wire signed             [INTWIDTH-1:0] lowP;
   wire signed    [INTWIDTH+ROMWIDTH-1:0] Dcoeff;
   reg  signed             [INTWIDTH-1:0] Dvalue;
   reg  signed             [SIGWIDTH+1:0] filteredMux;

   // Input attenuator characteristic
   initial begin
      ROM_I[63] = 12'd0251;
      ROM_I[62] = 12'd0255;
      ROM_I[61] = 12'd0259;
      ROM_I[60] = 12'd0264;
      ROM_I[59] = 12'd0268;
      ROM_I[58] = 12'd0272;
      ROM_I[57] = 12'd0277;
      ROM_I[56] = 12'd0282;
      ROM_I[55] = 12'd0287;
      ROM_I[54] = 12'd0292;
      ROM_I[53] = 12'd0297;
      ROM_I[52] = 12'd0303;
      ROM_I[51] = 12'd0308;
      ROM_I[50] = 12'd0314;
      ROM_I[49] = 12'd0320;
      ROM_I[48] = 12'd0327;
      ROM_I[47] = 12'd0334;
      ROM_I[46] = 12'd0341;
      ROM_I[45] = 12'd0348;
      ROM_I[44] = 12'd0355;
      ROM_I[43] = 12'd0363;
      ROM_I[42] = 12'd0371;
      ROM_I[41] = 12'd0380;
      ROM_I[40] = 12'd0389;
      ROM_I[39] = 12'd0399;
      ROM_I[38] = 12'd0409;
      ROM_I[37] = 12'd0419;
      ROM_I[36] = 12'd0430;
      ROM_I[35] = 12'd0442;
      ROM_I[34] = 12'd0454;
      ROM_I[33] = 12'd0467;
      ROM_I[32] = 12'd0481;
      ROM_I[31] = 12'd0495;
      ROM_I[30] = 12'd0511;
      ROM_I[29] = 12'd0527;
      ROM_I[28] = 12'd0545;
      ROM_I[27] = 12'd0563;
      ROM_I[26] = 12'd0583;
      ROM_I[25] = 12'd0605;
      ROM_I[24] = 12'd0628;
      ROM_I[23] = 12'd0653;
      ROM_I[22] = 12'd0680;
      ROM_I[21] = 12'd0710;
      ROM_I[20] = 12'd0742;
      ROM_I[19] = 12'd0777;
      ROM_I[18] = 12'd0815;
      ROM_I[17] = 12'd0858;
      ROM_I[16] = 12'd0905;
      ROM_I[15] = 12'd0958;
      ROM_I[14] = 12'd1017;
      ROM_I[13] = 12'd1084;
      ROM_I[12] = 12'd1161;
      ROM_I[11] = 12'd1248;
      ROM_I[10] = 12'd1350;
      ROM_I[ 9] = 12'd1470;
      ROM_I[ 8] = 12'd1613;
      ROM_I[ 7] = 12'd1785;
      ROM_I[ 6] = 12'd1998;
      ROM_I[ 5] = 12'd2267;
      ROM_I[ 4] = 12'd2613;
      ROM_I[ 3] = 12'd3073;
      ROM_I[ 2] = 12'd3691;
      ROM_I[ 1] = 12'd4095;
      ROM_I[ 0] = 12'd4095;
   end

   // Damping feedback characteristic
   initial begin
      ROM_D[63] = 14'd0253;
      ROM_D[62] = 14'd0256;
      ROM_D[61] = 14'd0261;
      ROM_D[60] = 14'd0265;
      ROM_D[59] = 14'd0269;
      ROM_D[58] = 14'd0274;
      ROM_D[57] = 14'd0278;
      ROM_D[56] = 14'd0283;
      ROM_D[55] = 14'd0288;
      ROM_D[54] = 14'd0293;
      ROM_D[53] = 14'd0298;
      ROM_D[52] = 14'd0304;
      ROM_D[51] = 14'd0310;
      ROM_D[50] = 14'd0316;
      ROM_D[49] = 14'd0322;
      ROM_D[48] = 14'd0328;
      ROM_D[47] = 14'd0335;
      ROM_D[46] = 14'd0342;
      ROM_D[45] = 14'd0349;
      ROM_D[44] = 14'd0357;
      ROM_D[43] = 14'd0365;
      ROM_D[42] = 14'd0373;
      ROM_D[41] = 14'd0382;
      ROM_D[40] = 14'd0391;
      ROM_D[39] = 14'd0400;
      ROM_D[38] = 14'd0410;
      ROM_D[37] = 14'd0421;
      ROM_D[36] = 14'd0432;
      ROM_D[35] = 14'd0443;
      ROM_D[34] = 14'd0456;
      ROM_D[33] = 14'd0469;
      ROM_D[32] = 14'd0482;
      ROM_D[31] = 14'd0497;
      ROM_D[30] = 14'd0512;
      ROM_D[29] = 14'd0529;
      ROM_D[28] = 14'd0547;
      ROM_D[27] = 14'd0565;
      ROM_D[26] = 14'd0586;
      ROM_D[25] = 14'd0607;
      ROM_D[24] = 14'd0631;
      ROM_D[23] = 14'd0656;
      ROM_D[22] = 14'd0683;
      ROM_D[21] = 14'd0713;
      ROM_D[20] = 14'd0745;
      ROM_D[19] = 14'd0781;
      ROM_D[18] = 14'd0820;
      ROM_D[17] = 14'd0863;
      ROM_D[16] = 14'd0911;
      ROM_D[15] = 14'd0964;
      ROM_D[14] = 14'd1024;
      ROM_D[13] = 14'd1093;
      ROM_D[12] = 14'd1171;
      ROM_D[11] = 14'd1261;
      ROM_D[10] = 14'd1366;
      ROM_D[ 9] = 14'd1490;
      ROM_D[ 8] = 14'd1639;
      ROM_D[ 7] = 14'd1821;
      ROM_D[ 6] = 14'd2048;
      ROM_D[ 5] = 14'd2341;
      ROM_D[ 4] = 14'd2731;
      ROM_D[ 3] = 14'd3277;
      ROM_D[ 2] = 14'd4096;
      ROM_D[ 1] = 14'd5462;
      ROM_D[ 0] = 14'd8192;
   end

   // Prepare some signals
   assign unf0 = unfiltered * $signed({1'b0, ROM_I[Q] + (overdrive << 3)});
// assign unf0 = unfiltered * $signed({1'b0, ROM_I[Q]});

   always @(posedge clk)
      unf1 <= (unf0 >>> (SIGWIDTH+ROMWIDTH-INTWIDTH+PREDECIMALS));

   assign Dcoeff = $signed({1'b0, ROM_D[Q]}) * bandP;

   always @(posedge clk)
      Dvalue <= Dcoeff >>> ROMWIDTH;


   // Filter core
   assign highP = $signed({INTWIDTH{1'b0}}) - unf1 - lowP + Dvalue;

   integrator
   #(
      .SIGWIDTH               (INTWIDTH),
      .CWIDTH                 (FRQWIDTH),
      .N                      (5)
   )
   integBP
   (
      .clk                    (clk),
      .sampleClk              (sampleClk),
      .mode                   (2'd0),  // <= Release: Mode 0!
      .coeff                  (freq),
      .sigIn                  (highP),
      .sigOut                 (bandP),
      .clip                   (clipBP)
   );

   integrator
   #(
      .SIGWIDTH               (INTWIDTH),
      .CWIDTH                 (FRQWIDTH),
      .N                      (5)
   )
   integLP
   (
      .clk                    (clk),
      .sampleClk              (sampleClk),
      .mode                   (2'd0),  // <= Release: Mode 0!
      .coeff                  (freq),
      .sigIn                  (bandP),
      .sigOut                 (lowP),
      .clip                   (clipLP)
   );


   // Mode selection
   always @(*)
      case (mode)
         3'b100: filteredMux <= highP >>> (INTWIDTH-SIGWIDTH);
         3'b010: filteredMux <= bandP >>> (INTWIDTH-SIGWIDTH-1);
         3'b001: filteredMux <= lowP >>> (INTWIDTH-SIGWIDTH-1);
         3'b101: filteredMux <= (highP >>> (INTWIDTH-SIGWIDTH-1)) + (lowP >>> (INTWIDTH-SIGWIDTH-1));
         default: filteredMux <= {2'b00, unfiltered};
      endcase

   always @(posedge clk)
      if (sampleClk)
         filtered <= filteredMux[SIGWIDTH-1:0];

endmodule
