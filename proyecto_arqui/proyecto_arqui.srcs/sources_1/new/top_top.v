`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.07.2025 14:10:12
// Design Name: 
// Module Name: top_top
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



// Top-level module that combines your multi-cycle processor with hex display
module top_top(
    input clk,
    input reset,
    input [1:0] display_sel, // Switch to select what to display
    output [3:0] anode,
    output [7:0] catode
);
    // Signals from your multi-cycle processor
    wire [31:0] WriteData;
    wire [31:0] Adr;
    wire MemWrite;
    
    // Instantiate your multi-cycle processor
    top processor_top(
        .clk(clk),
        .reset(reset),
        .WriteData(WriteData),
        .Adr(Adr),
        .MemWrite(MemWrite)
    );
    
    // Data to display on 7-segment (16 bits)
    reg [15:0] display_data;
    
    // Select what to display based on switches
    always @(*) begin
        case (display_sel)
            2'b00: display_data = WriteData[15:0];  // Lower 16 bits of WriteData
            2'b01: display_data = WriteData[31:16]; // Upper 16 bits of WriteData
            2'b10: display_data = Adr[15:0];        // Lower 16 bits of Address
            2'b11: display_data = Adr[31:16];       // Upper 16 bits of Address
        endcase
    end
    
    // Instantiate hex display
    hex_display display(
        .clk(clk),
        .reset(reset),
        .data(display_data),
        .anode(anode),
        .catode(catode)
    );
endmodule
