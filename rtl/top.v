`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//  
// Create Date: Tue Dec  1 04:15:25 AM PST 2020
// Design Name:
// Module Name: top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module top(
	input clk,
	input [3:0] sw,
	output [31:0] obus
	);

	assign obus[0] = ^sw & clk;
	assign obus[31:1] = sw[2:0] & sw[3] & ~clk ^ sw[1];


endmodule
