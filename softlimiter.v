`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:       René Trapp
//
// Create Date:    18:15:54 09/12/2021 
// Design Name:
// Module Name:    softlimiter
// Project Name:   Bitband
// Target Devices: XC6SLX9-TQG144
// Tool versions:  Xilinx ISE Webpack 14.7 (any supporting the Xc6SLX9)
// Description:    Soft limitation using a tanh-like characteristic
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
// mode == 0 <=> bypass
// mode == 1 <=> limit
//
////////////////////////////////////////////////////////////////////////////////


module softlimiter
#(
   parameter   SIGWIDTH        =  8
)
(
   input                                  clk,
   input                                  sampleClk,
   input                                  mode,
   input       signed      [SIGWIDTH-1:0] sampleIn,
   output reg  signed      [SIGWIDTH-1:0] sampleOut = 0
);

   localparam  max                      = {1'b0, {SIGWIDTH-1{1'b1}}};
   localparam  min                      = {1'b1, {SIGWIDTH-1{1'b0}}};


   reg                     [SIGWIDTH-1:0] tanh [15:0];
   initial begin
      tanh[ 7] = max;
      tanh[ 6] = $tanh(0.5); // <= Was sagt der Synthesizer zu diesem Ansinnen?
      tanh[ 0] = sampleIn;
      tanh[15] = min;
   end

   always @(posedge clk)
      if (sampleClk)
         if (mode == 0)
            sampleOut <= sampleIn;


endmodule
