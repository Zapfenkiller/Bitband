`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:       René Trapp
//
// Create Date:    18:33:27 06/10/2021 
// Design Name: 
// Module Name:    linExpo 
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
// Converts a 7-bit linear input into a 16-bit output with exponential
// characteristic. Dedicated to audible linear volume control by an envelope
// this might be useful for other purposes also.
//
// Be aware, output is registered and comes 1 clock after the input vector!
//
// Adjusted to give 0 dB with 127, -0.75 dB with 126 and so on. Gets rough
// when input gets below 34 (-65 dB). 127 => 32767 <=> 0 dB
//
////////////////////////////////////////////////////////////////////////////////


module linExpo(
   input                         clock,
   input                   [6:0] lin,
   output reg             [15:0] expo
   );


   reg                    [15:0] ROM [7:0];


   initial begin
      ROM[7] = 16'd32768;
      ROM[6] = 16'd30048;
      ROM[5] = 16'd27554;
      ROM[4] = 16'd25268;
      ROM[3] = 16'd23170;
      ROM[2] = 16'd21247;
      ROM[1] = 16'd19484;
      ROM[0] = 16'd17869;
   end


   always @(posedge clock)
      case (lin[6:3])
         4'hF:    expo <= ROM[lin[2:0]];
         4'hE:    expo <= { 1'b0, ROM[lin[2:0]][15: 1]};
         4'hD:    expo <= { 2'b0, ROM[lin[2:0]][15: 2]};
         4'hC:    expo <= { 3'b0, ROM[lin[2:0]][15: 3]};
         4'hB:    expo <= { 4'b0, ROM[lin[2:0]][15: 4]};
         4'hA:    expo <= { 5'b0, ROM[lin[2:0]][15: 5]};
         4'h9:    expo <= { 6'b0, ROM[lin[2:0]][15: 6]};
         4'h8:    expo <= { 7'b0, ROM[lin[2:0]][15: 7]};
         4'h7:    expo <= { 8'b0, ROM[lin[2:0]][15: 8]};
         4'h6:    expo <= { 9'b0, ROM[lin[2:0]][15: 9]};
         4'h5:    expo <= {10'b0, ROM[lin[2:0]][15:10]};
         4'h4:    expo <= {11'b0, ROM[lin[2:0]][15:11]};
         4'h3:    expo <= {12'b0, ROM[lin[2:0]][15:12]};
         4'h2:    expo <= {13'b0, ROM[lin[2:0]][15:13]};
         4'h1:    expo <= {14'b0, ROM[lin[2:0]][15:14]};
         default: expo <= {15'b0, ROM[lin[2:0]][15]};
      endcase


endmodule
