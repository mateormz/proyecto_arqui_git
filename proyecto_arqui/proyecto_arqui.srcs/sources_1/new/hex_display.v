`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.07.2025 14:08:56
// Design Name: 
// Module Name: hex_display
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


// Main hex display module
module hex_display(
    input clk,
    input reset,
    input [15:0] data,
    output wire [3:0] anode,
    output wire [7:0] catode
);
    wire scl_clk;
    wire [3:0] digit;
    
    CLKdivider sc(
        .clk(clk),
        .reset(reset),
        .t(scl_clk)
    );
    
    hFSM m(
        .clk(scl_clk),
        .reset(reset),
        .data(data),
        .digit(digit),
        .anode(anode)
    );
    
    HexTo7Segment decoder(
        .digit(digit),
        .catode(catode)
    );
endmodule

