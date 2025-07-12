`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.07.2025 14:07:00
// Design Name: 
// Module Name: hFSM
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


// Finite State Machine for multiplexing display digits
module hFSM(
    input clk,
    input reset,
    input [15:0] data,
    output reg [3:0] digit,
    output reg [3:0] anode
);
    reg [1:0] state;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 2'b00;
        end else begin
            state <= state + 1;
        end
    end
    
    always @(*) begin
        case (state)
            2'b00: begin // D0 - rightmost digit
                digit = data[3:0];
                anode = 4'b1110;
            end
            2'b01: begin // D1
                digit = data[7:4];
                anode = 4'b1101;
            end
            2'b10: begin // D2
                digit = data[11:8];
                anode = 4'b1011;
            end
            2'b11: begin // D3 - leftmost digit
                digit = data[15:12];
                anode = 4'b0111;
            end
        endcase
    end
endmodule
