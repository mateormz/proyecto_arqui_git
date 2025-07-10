`timescale 1ns / 1ps

module fpregfile (
    input wire clk,
    input wire we3,
    input wire [4:0] ra1,  // 5 bits para 32 registros S
    input wire [4:0] ra2,
    input wire [4:0] wa3,
    input wire [31:0] wd3,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);
    
    reg [31:0] rf [31:0]; // 32 registros S0-S31
    
    always @(posedge clk) begin
        if (we3)
            rf[wa3] <= wd3;
    end
    
    assign rd1 = rf[ra1];
    assign rd2 = rf[ra2];
    
endmodule