`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:       René Trapp
//
// Create Date:    19:00:07 05/30/2021 
// Design Name: 
// Module Name:    envGen
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
// Attack, Decay, Release input vectors are 7 bit wide:
//    {2'b"e", 5'b"m"}
//    2 bits as exponent e
//    5 bits as mantissa m
//
// t = 2**(e*3) * m * T
// T = 1/375 s @ clockEn = 48 kHz
//
//   e | 2**(e*3)
//  ---+---------
//   0 |   1
//   1 |   8
//   2 |  64
//   3 | 512
//
// Sustain is fixed to the envelope width. If the generator is in its Sustain
// state any writes to the register take effect immediately (with the next clock
// rising edge). There is intentionally no ramping performed! But there is
// intentionally some provision to lock into sustain even if the sustain level
// is (heavily) modulated.
//
// Envelope output is a simple linear up and down counter. To convert this into
// a volume control a linear-to-exponential conversion needs to happen
// thereafter.
//
////////////////////////////////////////////////////////////////////////////////


module envGen
#(
   parameter   ENVWIDTH       =  7
)
(
   input                         clock,
   input                         clockEn,

   input                   [6:0] attackVal,
   input                   [6:0] decayVal,
   input          [ENVWIDTH-1:0] sustainVal,
   input                   [6:0] releaseVal,
   input                         gate,

   output reg     [ENVWIDTH-1:0] envelope = 0
);

   localparam  ADSR_ATTACK    =  4'd2;
   localparam  ADSR_DECAY     =  4'd4;
   localparam  ADSR_SUSTAIN   =  4'd8;
   localparam  ADSR_RELEASE   =  4'd1;
   localparam  PREDIVWIDTH    =  9;


   reg                           gatePrev = 0;
   reg                     [3:0] adsrNext;
   reg                     [3:0] adsrState = ADSR_RELEASE;
   reg                     [1:0] expoMux;
   reg                     [1:0] exponent = 0;
   reg         [PREDIVWIDTH-1:0] divCoarse = 0;
   reg                     [4:0] mantMux;
   reg                     [4:0] mantissa = 0;
   reg                     [4:0] divFine = 0;
   wire                          nextEnv;

   wire                          gate_change;
   wire                          divCoarseLoad;
   wire                          divFineLoad;



   // envelope control state machine
   // ------------------------------


   assign atMax = (envelope == {ENVWIDTH{1'b1}});
   assign atSus = (envelope <= sustainVal);
   assign atMin = (envelope == {ENVWIDTH{1'b0}});


   always @(*)
      if (gate)
         case (adsrState)
            ADSR_ATTACK:   adsrNext = atMax ? (atSus ? ADSR_SUSTAIN : ADSR_DECAY) : ADSR_ATTACK;
            ADSR_DECAY:    adsrNext = atSus ? ADSR_SUSTAIN : ADSR_DECAY;
            ADSR_SUSTAIN:  adsrNext = ADSR_SUSTAIN;
            default:       adsrNext = ADSR_ATTACK;
         endcase
      else
         adsrNext = ADSR_RELEASE;


   always @(posedge clock)
      if (clockEn)
         if (nextEnv)
            adsrState <= adsrNext;


   // envelope generator
   // ------------------


   always @(posedge clock)
      if (clockEn)
         if (nextEnv)
            case (adsrNext)
               ADSR_ATTACK:   envelope <= envelope + 1'b1;
               ADSR_DECAY:    envelope <= envelope - 1'b1;
               ADSR_SUSTAIN:  envelope <= sustainVal;
               default:       envelope <= envelope - (atMin ? 1'b0 : 1'b1);
            endcase


   // prepare desired timing
   // ----------------------


   always @(*)
      case (adsrNext)
         ADSR_ATTACK:   expoMux = attackVal[6:5];
         ADSR_DECAY:    expoMux = decayVal[6:5];
         ADSR_SUSTAIN:  expoMux = releaseVal[6:5];
         default:       expoMux = releaseVal[6:5];
      endcase


   always @(posedge clock)
      if (nextEnv)
         exponent <= expoMux;


   always @(*)
      case (adsrNext)
         ADSR_ATTACK:   mantMux = attackVal[4:0];
         ADSR_DECAY:    mantMux = decayVal[4:0];
         ADSR_SUSTAIN:  mantMux = releaseVal[4:0];
         default:       mantMux = releaseVal[4:0];
      endcase


   always @(posedge clock)
      if (nextEnv)
         mantissa <= mantMux;


   // envelope timing generator
   // -------------------------


   always @(posedge clock)
      if (clockEn)
         gatePrev <= gate;


   assign gate_change = gatePrev ^ gate;


   function [PREDIVWIDTH-1:0] expLUT;
      input [1:0] address;
      begin
         case (address)
            3'd3:    expLUT =  511;   // :512
            3'd2:    expLUT =   63;   // :64
            3'd1:    expLUT =    7;   // :8
            default: expLUT =    0;   // :1   <=>   Divider - 1
         endcase
      end
   endfunction


   assign divCoarseLoad = (divCoarse == 0) | gate_change;


   always @(posedge clock)
      if (clockEn)
         if (nextEnv)
            divCoarse <= expLUT(expoMux);
         else
            if (divCoarseLoad)
               divCoarse <= expLUT(exponent);
            else
               divCoarse <= divCoarse - 1'b1;


   assign divFineLoad = ((divFine == 0) & divCoarseLoad) | gate_change;


   always @(posedge clock)
      if (clockEn)
         if (nextEnv)
            divFine <= mantMux;
         else
            if (divFineLoad)
               divFine <= mantissa;
            else
               if (divCoarseLoad)
                  divFine <= divFine - 1'b1;


      assign nextEnv = divFineLoad | (adsrState == ADSR_SUSTAIN);


endmodule
