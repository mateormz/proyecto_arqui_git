`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.07.2025 14:06:08
// Design Name: 
// Module Name: CLKdivider
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



// Clock divider - divides 100MHz to ~480Hz
module CLKdivider(
    input clk,
    input reset,
    output reg t
);
    reg [17:0] counter;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 18'd0;
            t <= 1'b0;
        end else begin
            if (counter >= 18'd104166) begin // 100MHz / 480Hz / 2 ? 104166
                counter <= 18'd0;
                t <= ~t;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule