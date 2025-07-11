`timescale 1ns / 1ps

module floprdual ( 
    clk, 
    reset, 
    d1, 
    d2, 
    q1, 
    q2 
);
    parameter WIDTH = 8;
    
    input wire clk;
    input wire reset;
    input wire [WIDTH - 1:0] d1;
    input wire [WIDTH - 1:0] d2;
    output reg [WIDTH - 1:0] q1;
    output reg [WIDTH - 1:0] q2;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q1 <= 0;
            q2 <= 0;
        end else begin
            q1 <= d1;
            q2 <= d2;
        end
    end
    
endmodule